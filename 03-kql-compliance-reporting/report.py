"""
Runs every .kql file in ./queries against Azure Resource Graph,
saves each result as a CSV, and builds one simple HTML report.

Usage:
    python report.py                       # all subscriptions you can access
    python report.py --subscription <id>   # one subscription (repeatable)

Login: uses DefaultAzureCredential, so `az login` is enough on your laptop.
"""

import argparse
import csv
import html
from datetime import datetime
from pathlib import Path

from azure.identity import DefaultAzureCredential
from azure.mgmt.resourcegraph import ResourceGraphClient
from azure.mgmt.resourcegraph.models import QueryRequest, QueryRequestOptions, ResultFormat

BASE_DIR = Path(__file__).parent
QUERY_DIR = BASE_DIR / "queries"
OUTPUT_DIR = BASE_DIR / "output"

# These queries describe the environment rather than problems,
# so their rows are not counted as "findings" in the summary.
INFO_ONLY = {"01-policy-compliance-summary", "05-public-ip-inventory", "06-resource-inventory"}


def load_query(path: Path) -> str:
    """Read a .kql file and drop the comment lines."""
    lines = [line for line in path.read_text(encoding="utf-8").splitlines()
             if not line.strip().startswith("//")]
    return "\n".join(lines).strip()


def run_query(client: ResourceGraphClient, query: str, subscriptions: list[str] | None) -> list[dict]:
    """Run a query and follow the paging until all rows are collected."""
    rows: list[dict] = []
    skip_token = None
    while True:
        options = QueryRequestOptions(result_format=ResultFormat.OBJECT_ARRAY, skip_token=skip_token, top=1000)
        request = QueryRequest(query=query, subscriptions=subscriptions, options=options)
        response = client.resources(request)
        rows.extend(response.data or [])
        skip_token = response.skip_token
        if not skip_token:
            return rows


def save_csv(rows: list[dict], path: Path) -> None:
    if not rows:
        path.write_text("", encoding="utf-8")
        return
    columns = list(rows[0].keys())
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=columns, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def to_html_table(rows: list[dict], limit: int = 200) -> str:
    if not rows:
        return '<p class="ok">Nothing found.</p>'
    columns = list(rows[0].keys())
    head = "".join(f"<th>{html.escape(c)}</th>" for c in columns)
    body = ""
    for row in rows[:limit]:
        body += "<tr>" + "".join(f"<td>{html.escape(str(row.get(c, '')))}</td>" for c in columns) + "</tr>"
    more = f'<p class="muted">Showing {limit} of {len(rows)} rows. See the CSV for all of them.</p>' if len(rows) > limit else ""
    return f"<table><thead><tr>{head}</tr></thead><tbody>{body}</tbody></table>{more}"


def build_report(results: dict[str, list[dict]]) -> str:
    generated = datetime.now().strftime("%Y-%m-%d %H:%M")
    cards, sections = "", ""
    for name, rows in results.items():
        title = name.split("-", 1)[1].replace("-", " ").capitalize()
        info = name in INFO_ONLY
        css = "info" if info else ("bad" if rows else "good")
        label = f"{len(rows)} rows" if info else (f"{len(rows)} findings" if rows else "All good")
        cards += f'<a class="card {css}" href="#{name}"><span>{html.escape(title)}</span><strong>{label}</strong></a>'
        sections += f'<section id="{name}"><h2>{html.escape(title)}</h2>{to_html_table(rows)}</section>'

    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Azure Compliance Report</title>
<style>
  body {{ font-family: system-ui, sans-serif; margin: 0 auto; max-width: 1100px; padding: 24px; color: #1f2937; background: #f9fafb; }}
  h1 {{ margin-bottom: 4px; }}
  .muted {{ color: #6b7280; font-size: 14px; }}
  .cards {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; margin: 24px 0; }}
  .card {{ display: flex; flex-direction: column; gap: 6px; padding: 14px; border-radius: 10px; text-decoration: none; color: inherit; background: #fff; border-left: 5px solid #9ca3af; box-shadow: 0 1px 2px rgba(0,0,0,.06); }}
  .card span {{ font-size: 13px; color: #4b5563; }}
  .card strong {{ font-size: 20px; }}
  .card.bad {{ border-color: #dc2626; }} .card.good {{ border-color: #16a34a; }} .card.info {{ border-color: #2563eb; }}
  section {{ background: #fff; border-radius: 10px; padding: 16px 20px; margin-bottom: 16px; box-shadow: 0 1px 2px rgba(0,0,0,.06); overflow-x: auto; }}
  table {{ border-collapse: collapse; width: 100%; font-size: 13px; }}
  th, td {{ text-align: left; padding: 6px 10px; border-bottom: 1px solid #e5e7eb; white-space: nowrap; }}
  th {{ background: #f3f4f6; }}
  .ok {{ color: #16a34a; }}
</style></head>
<body>
  <h1>Azure Compliance Report</h1>
  <p class="muted">Generated {generated} · Source: Azure Resource Graph</p>
  <div class="cards">{cards}</div>
  {sections}
</body></html>"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Azure compliance report from Resource Graph")
    parser.add_argument("--subscription", action="append", help="Subscription ID (repeat for several)")
    args = parser.parse_args()

    OUTPUT_DIR.mkdir(exist_ok=True)
    client = ResourceGraphClient(DefaultAzureCredential())

    results: dict[str, list[dict]] = {}
    for query_file in sorted(QUERY_DIR.glob("*.kql")):
        name = query_file.stem
        print(f"{name} ...", end=" ", flush=True)
        rows = run_query(client, load_query(query_file), args.subscription)
        save_csv(rows, OUTPUT_DIR / f"{name}.csv")
        results[name] = rows
        print(f"{len(rows)} rows")

    report_path = OUTPUT_DIR / "report.html"
    report_path.write_text(build_report(results), encoding="utf-8")
    print(f"\nReport ready: {report_path}")


if __name__ == "__main__":
    main()
