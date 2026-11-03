"""Download CVEs published during the current UTC calendar month from NVD."""

import csv
import json
import os
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

API_URL = "https://services.nvd.nist.gov/rest/json/cves/2.0"
PAGE_SIZE = 2000
OUTPUT_DIR = Path("reports")


def download_page(params):
    url = f"{API_URL}?{urlencode(params)}"
    headers = {"User-Agent": "Monthly-CVE-Watch/1.0"}
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


def get_cvss(cve):
    metrics = cve.get("metrics", {})
    for metric_version in ("cvssMetricV40", "cvssMetricV31", "cvssMetricV30", "cvssMetricV2"):
        values = metrics.get(metric_version, [])
        if values:
            preferred = next((x for x in values if x.get("type") == "Primary"), values[0])
            data = preferred.get("cvssData", {})
            return data.get("baseScore", ""), (
                data.get("baseSeverity") or preferred.get("baseSeverity", "")
            )
    return "", ""


def main():
    now = datetime.now(timezone.utc)
    start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    month = start.strftime("%Y-%m")
    base_params = {
        "pubStartDate": start.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
        "pubEndDate": now.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
        "resultsPerPage": PAGE_SIZE,
    }
    print(f"Fetching CVEs published from {base_params['pubStartDate']} to {base_params['pubEndDate']}")

    records = []
    index = 0
    while True:
        response = download_page({**base_params, "startIndex": index})
        batch = response.get("vulnerabilities", [])
        records.extend(item["cve"] for item in batch if "cve" in item)
        total = response.get("totalResults", 0)
        index += len(batch)
        print(f"Retrieved {index} / {total}")
        if not batch or index >= total:
            break
        time.sleep(7)  # Stay below the public API's request rate limits.

    records.sort(key=lambda cve: cve.get("published", ""), reverse=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output = OUTPUT_DIR / f"cves_{month}.csv"
    with output.open("w", newline="", encoding="utf-8-sig") as file:
        writer = csv.writer(file)
        writer.writerow(["CVE", "Published (UTC)", "CVSS", "Severity", "Description", "NVD URL"])
        for cve in records:
            description = next(
                (entry["value"] for entry in cve.get("descriptions", []) if entry.get("lang") == "en"),
                "",
            )
            score, severity = get_cvss(cve)
            writer.writerow([
                cve.get("id", ""),
                cve.get("published", ""),
                score,
                severity,
                description,
                f"https://nvd.nist.gov/vuln/detail/{cve.get('id', '')}",
            ])

    print(f"Saved {len(records)} CVEs to {output}")
    print("Note: NVD may publish some CVE entries after their initial disclosure.")


if __name__ == "__main__":
    main()
