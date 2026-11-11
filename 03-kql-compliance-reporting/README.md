# KQL compliance reporting

A handful of Resource Graph queries and a Python script that runs them all and writes the
results to CSV plus a single HTML page. I use this when someone asks "where do we stand?"
and I don't want to spend a day exporting things from the portal.

## Queries

| File | Returns |
|------|---------|
| `01-policy-compliance-summary.kql` | compliant / non-compliant count per policy |
| `02-missing-owner-tag.kql` | resources without an `Owner` tag |
| `03-insecure-storage.kql` | storage accounts with HTTP, public blob access, old TLS or open network |
| `04-open-management-ports.kql` | NSG rules allowing 22 or 3389 from the internet |
| `05-public-ip-inventory.kql` | public IPs and what they're attached to |
| `06-resource-inventory.kql` | resource count per type |

Each query answers one question. That makes them easier to check and reuse somewhere else
(workbooks, alerts, a dashboard).

## Running it

```bash
az login
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

python report.py
python report.py --subscription <id>   # limit to one subscription, can be repeated
```

Output goes to `output/`: one CSV per query and `report.html`. The HTML has a small summary
at the top and a table per check below it.

Authentication uses `DefaultAzureCredential`, so your Azure CLI login is enough locally and
a managed identity works if you run it from Azure.

## NiFi

For scheduled reporting I push the same data through NiFi into a database that a dashboard
reads from. `nifi/` has a docker-compose file to run NiFi locally and a description of the flow.

## Notes

- Resource Graph returns max 1000 rows per page. The script follows the skip token, so large
  environments are fine.
- `04-open-management-ports` only looks at `destinationPortRange` (single value or range).
  Rules that use the `destinationPortRanges` list aren't covered yet.
- Resource Graph queries are free.
