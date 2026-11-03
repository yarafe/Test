# Monthly CVE Watch

Fetch CVEs **published during the current UTC month** using the official NVD CVE API v2 and write a CSV report. A GitHub Actions job runs daily at 08:17 Europe/Brussels time and uploads the report as a downloadable workflow artifact.

## Local run

```bash
python fetch_cves.py
```

Open `reports/cves_YYYY-MM.csv` in Excel or another spreadsheet app. The program automatically computes the first day of the current month; no date needs to be updated.

## Daily runs on GitHub

1. Create a repository on GitHub, preferably private.
2. Upload `fetch_cves.py` and `.github/workflows/daily-cves.yml` with their folder structure.
3. In the **Actions** tab, select **Daily CVE Download** > **Run workflow**.
4. Open the finished run and download **latest-month-cves** under Artifacts.
5. The scheduled run will execute automatically each morning.

Optional: create an NVD API key and store it as repository secret `NVD_API_KEY` for higher request limits.

## Important caveats

- This captures CVEs *published in NVD* this calendar month (UTC), not every newly exploited vulnerability or newly modified CVE.
- NVD publication can lag the initial public CVE disclosure.
- CVSS values may be blank until NVD or another scoring provider adds them.
- The CSV remains inside private GitHub workflow artifacts if you use a private repository; do not commit sensitive scans or keys.

Official documentation: https://nvd.nist.gov/developers/vulnerabilities and https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows
