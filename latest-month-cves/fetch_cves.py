"""Download this month's NVD CVEs and render a separate Critical-only HTML report.

Python 3.12+, standard library only. Run from latest-month-cves/.
"""

import csv
import html
import json
import os
import re
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urlsplit
from urllib.request import Request, urlopen

API_URL = "https://services.nvd.nist.gov/rest/json/cves/2.0"
PAGE_SIZE = 2000
OUTPUT_DIR = Path("reports")
METRIC_KEYS = ("cvssMetricV40", "cvssMetricV31", "cvssMetricV30", "cvssMetricV2")
ADVISORY_PATTERN = re.compile(
    r"\b(?:GHSA-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}"
    r"|RHSA-\d{4}:\d+|USN-\d+-\d+|DSA-\d+-\d+)\b",
    re.IGNORECASE,
)


def download_page(params):
    url = f"{API_URL}?{urlencode(params)}"
    headers = {"User-Agent": "Monthly-CVE-Watch/2.0"}
    if os.getenv("NVD_API_KEY"):
        headers["apiKey"] = os.environ["NVD_API_KEY"]
    for attempt in range(3):
        try:
            with urlopen(Request(url, headers=headers), timeout=60) as response:
                return json.load(response)
        except (HTTPError, URLError, TimeoutError) as exc:
            if attempt == 2:
                raise RuntimeError(f"NVD request failed after 3 attempts: {exc}") from exc
            delay = 10 * (attempt + 1)
            print(f"NVD request failed: {exc}. Retrying in {delay}s...")
            time.sleep(delay)


def selected_metric(cve):
    metrics = cve.get("metrics") or {}
    for key in METRIC_KEYS:
        values = metrics.get(key) or []
        if values:
            return next((v for v in values if v.get("type") == "Primary"), values[0])
    return {}


def get_cvss(cve):
    metric = selected_metric(cve)
    data = metric.get("cvssData") or {}
    return data.get("baseScore", ""), data.get("baseSeverity") or metric.get("baseSeverity", "")


def description(cve, limit=None):
    entries = cve.get("descriptions") or []
    raw = next((x.get("value", "") for x in entries if x.get("lang") == "en"), "")
    normalized = " ".join(raw.split())
    if limit and len(normalized) > limit:
        normalized = normalized[:limit].rsplit(" ", 1)[0] + "…"
    return normalized or "No description available in NVD."


def cpe_matches(cve):
    """Iterate CPE match criteria including nested configuration nodes."""
    def walk(node):
        for entry in node.get("cpeMatch", []) or []:
            if entry.get("vulnerable") is True:
                yield entry
        for child in node.get("nodes", []) or []:
            yield from walk(child)

    for config in cve.get("configurations", []) or []:
        yield from walk(config)


def affected_versions(cve):
    labels = []
    for entry in cpe_matches(cve):
        parts = (entry.get("criteria") or "").split(":")
        if len(parts) < 6:
            continue
        vendor, product, version = parts[3], parts[4], parts[5]
        name = f"{vendor}:{product}"
        limits = []
        if entry.get("versionStartIncluding"):
            limits.append(f">= {entry['versionStartIncluding']}")
        if entry.get("versionStartExcluding"):
            limits.append(f"> {entry['versionStartExcluding']}")
        if entry.get("versionEndIncluding"):
            limits.append(f"<= {entry['versionEndIncluding']}")
        if entry.get("versionEndExcluding"):
            limits.append(f"< {entry['versionEndExcluding']}")
        if limits:
            details = ", ".join(limits)
        elif version not in ("*", "-"):
            details = f"version {version}"
        else:
            details = "version range not specified"
        labels.append(f"{name}: {details}")
    # Maintain display order while removing duplicates.
    labels = list(dict.fromkeys(labels))
    return labels


def safe_url(url):
    try:
        parsed = urlsplit(url)
        return url if parsed.scheme in ("http", "https") and parsed.netloc else ""
    except (TypeError, ValueError):
        return ""


def linked_ref(url, label):
    return (
        f'<a href="{html.escape(url, quote=True)}" target="_blank" '
        f'rel="noopener noreferrer">{html.escape(label)}</a>'
    )


def advisories(cve):
    refs = cve.get("references", []) or []
    source_text = description(cve) + " " + " ".join(x.get("url", "") for x in refs)
    identifiers = list(dict.fromkeys(m.upper() for m in ADVISORY_PATTERN.findall(source_text)))
    useful = []
    for ref in refs:
        url = safe_url(ref.get("url", ""))
        tags = ref.get("tags") or []
        if url and any(t in tags for t in ("Vendor Advisory", "Third Party Advisory", "Patch", "Mitigation")):
            useful.append((url, ", ".join(tags)))
    useful = list(dict.fromkeys(useful))
    return identifiers, useful


def attack_vector(cve):
    data = (selected_metric(cve).get("cvssData") or {})
    vector = data.get("attackVector")
    return str(vector).replace("_", " ").title() if vector else "Not specified in NVD metrics"


def potential_impact(cve):
    data = selected_metric(cve).get("cvssData") or {}
    mapping = (
        ("Confidentiality", data.get("vulnConfidentialityImpact") or data.get("confidentialityImpact")),
        ("Integrity", data.get("vulnIntegrityImpact") or data.get("integrityImpact")),
        ("Availability", data.get("vulnAvailabilityImpact") or data.get("availabilityImpact")),
    )
    parts = [f"{label}: {value.title()}" for label, value in mapping if value]
    return "; ".join(parts) if parts else "Not specified by available CVSS metrics; review the NVD description"


def sapi_field(cve):
    """NVD has no structured 'affected PHP SAPI' field; do not infer applicability."""
    is_php = any("php" in (item.get("criteria") or "").lower() for item in cpe_matches(cve))
    if is_php or re.search(r"\bPHP\b", description(cve), flags=re.IGNORECASE):
        return "Not specified by NVD; check the PHP/vendor advisory"
    return "Not applicable or not specified (SAPI is a PHP-specific concept)"


def solution_html(cve):
    patch_refs = [safe_url(x.get("url", "")) for x in cve.get("references", []) or []
                  if "Patch" in (x.get("tags") or [])]
    patch_refs = list(dict.fromkeys(url for url in patch_refs if url))
    if patch_refs:
        links = ", ".join(linked_ref(url, "Patch reference") for url in patch_refs[:3])
        return f"Check the vendor's patch and supported fixed-version guidance: {links}."
    return "No confirmed fixed version was provided in structured NVD data. Consult the vendor advisory for a patch or mitigation."


def render_html(cves, month, generated_at):
    critical = []
    for cve in cves:
        _score, severity = get_cvss(cve)
        if str(severity).upper() == "CRITICAL":
            critical.append(cve)
    critical.sort(key=lambda item: item.get("published", ""), reverse=True)

    cards = []
    for cve in critical:
        cve_id = cve.get("id", "Unknown CVE")
        score, _ = get_cvss(cve)
        published = cve.get("published", "Not specified")[:10]
        cpe_labels = affected_versions(cve)
        cpe_body = (
            "<ul>" + "".join(f"<li>{html.escape(x)}</li>" for x in cpe_labels[:8])
            + (f"<li>+{len(cpe_labels) - 8} other CPE matches</li>" if len(cpe_labels) > 8 else "")
            + "</ul>"
        ) if cpe_labels else "Not specified in NVD CPE data"
        identifiers, ref_links = advisories(cve)
        ids_body = ", ".join(html.escape(x) for x in identifiers) if identifiers else "No advisory ID identified"
        ref_body = (
            "<ul>" + "".join("<li>" + linked_ref(url, urlsplit(url).netloc) + "</li>" for url, _ in ref_links[:5])
            + "</ul>"
        ) if ref_links else "No tagged advisory links in NVD"
        nvd_url = f"https://nvd.nist.gov/vuln/detail/{cve_id}"
        cards.append(f"""
        <article class="card" data-search="{html.escape((cve_id + ' ' + description(cve)).lower(), quote=True)}">
          <div class="headline"><h2>{html.escape(cve_id)}</h2><span class="pill">CRITICAL · {html.escape(str(score))}</span></div>
          <p class="meta">Published {html.escape(published)} UTC · {linked_ref(nvd_url, 'NVD record')}</p>
          <p class="summary">{html.escape(description(cve, 320))}</p>
          <dl>
            <div><dt>Affected versions</dt><dd>{cpe_body}</dd></div>
            <div><dt>Affected Server APIs (SAPIs)</dt><dd>{html.escape(sapi_field(cve))}</dd></div>
            <div><dt>Advisory IDs</dt><dd>{ids_body}</dd></div>
            <div><dt>Attack Vector</dt><dd>{html.escape(attack_vector(cve))}</dd></div>
            <div><dt>Potential Impact (CVSS)</dt><dd>{html.escape(potential_impact(cve))}</dd></div>
            <div><dt>Solution</dt><dd>{solution_html(cve)}</dd></div>
            <div><dt>Advisory references</dt><dd>{ref_body}</dd></div>
          </dl>
        </article>""")

    body = "\n".join(cards) if cards else (
        '<div class="empty">No Critical CVEs with an available CVSS severity were found for this month in NVD.</div>'
    )
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Critical CVEs — {html.escape(month)}</title>
  <style>
    :root {{color-scheme:light; font-family:system-ui,-apple-system,Segoe UI,sans-serif}}
    body {{background:#f5f7fb; color:#172334; margin:0; line-height:1.5}}
    main {{max-width:1030px; margin:0 auto; padding:28px 18px 60px}}
    h1 {{margin:0 0 7px; font-size:2rem}} .muted,.meta {{color:#526377; font-size:.9rem}}
    .top {{display:flex; gap:14px; flex-wrap:wrap; align-items:center; justify-content:space-between}}
    input {{border:1px solid #b9c5d3; border-radius:9px; padding:12px; font:inherit; min-width:250px}}
    .card {{background:#fff; border:1px solid #e0e5ec; border-radius:14px; padding:20px; margin:18px 0; box-shadow:0 2px 8px #12243c0a}}
    .headline {{display:flex; align-items:center; justify-content:space-between; gap:12px; flex-wrap:wrap}}
    h2 {{margin:0;font-size:1.2rem}} .pill {{background:#fff0ef;color:#a52426;padding:5px 10px;border-radius:20px;font-weight:700;font-size:.85rem}}
    .summary {{font-size:1rem}} dl {{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-top:20px}}
    dl>div {{border-top:1px solid #e9edf3; padding-top:11px; min-width:0}}
    dt {{color:#40556b;font-size:.84rem;font-weight:700;margin-bottom:5px}} dd {{margin:0;overflow-wrap:anywhere}}
    a {{color:#0757ad}} li {{margin:3px 0}} ul {{padding-left:20px;margin:3px 0}}
    .info,.empty {{background:#e9f1fb;padding:12px;border-radius:10px;margin:18px 0;color:#334760}}
    @media(max-width:640px) {{dl {{grid-template-columns:1fr}} input {{width:100%;min-width:0;box-sizing:border-box}}}}
  </style>
</head>
<body><main>
  <div class="top"><div><h1>Critical CVEs — {html.escape(month)}</h1>
  <p class="muted">{len(critical)} Critical / {len(cves)} total CVEs · Generated {html.escape(generated_at)} UTC</p></div>
  <input id="search" type="search" placeholder="Search CVE or description" aria-label="Search CVEs"></div>
  <div class="info">Source: NIST NVD CVE API. Entries are filtered by the selected CVSS metric's <b>CRITICAL</b> severity.
  Affected versions are NVD CPE applicability conditions (which may include additional AND constraints), not vendor-confirmed fixed versions.
  SAPIs and solutions may require vendor advisory verification. Data and severity can change after publication.</div>
  <section id="results">{body}</section>
  <script>
    const search=document.getElementById('search');
    search.addEventListener('input',()=>{{
      for (const card of document.querySelectorAll('.card')) {{
        card.hidden=!card.dataset.search.includes(search.value.toLowerCase().trim());
      }}
    }});
  </script>
</main></body></html>"""


def main():
    now = datetime.now(timezone.utc)
    start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    month = start.strftime("%Y-%m")
    params = {
        "pubStartDate": start.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
        "pubEndDate": now.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
        "resultsPerPage": PAGE_SIZE,
    }
    print(f"Fetching NVD CVEs from {params['pubStartDate']} through {params['pubEndDate']}")
    records, index = [], 0
    while True:
        payload = download_page({**params, "startIndex": index})
        batch = payload.get("vulnerabilities", [])
        records.extend(item["cve"] for item in batch if "cve" in item)
        index += len(batch)
        total = payload.get("totalResults", 0)
        print(f"Retrieved {index}/{total} CVEs")
        if not batch or index >= total:
            break
        time.sleep(7)

    records.sort(key=lambda record: record.get("published", ""), reverse=True)
    OUTPUT_DIR.mkdir(exist_ok=True, parents=True)
    csv_path = OUTPUT_DIR / f"cves_{month}.csv"
    with csv_path.open("w", newline="", encoding="utf-8-sig") as file:
        writer = csv.writer(file)
        writer.writerow(["CVE", "Published (UTC)", "CVSS", "Severity", "Description", "NVD URL"])
        for cve in records:
            score, severity = get_cvss(cve)
            writer.writerow([cve.get("id", ""), cve.get("published", ""), score, severity,
                             description(cve), f"https://nvd.nist.gov/vuln/detail/{cve.get('id', '')}"])

    html_path = OUTPUT_DIR / f"critical_cves_{month}.html"
    html_path.write_text(render_html(records, month, now.strftime("%Y-%m-%d %H:%M")), encoding="utf-8")
    critical_count = sum(str(get_cvss(cve)[1]).upper() == "CRITICAL" for cve in records)
    print(f"Saved {len(records)} CVEs to {csv_path}")
    print(f"Saved {critical_count} Critical CVEs to {html_path}")


if __name__ == "__main__":
    main()
