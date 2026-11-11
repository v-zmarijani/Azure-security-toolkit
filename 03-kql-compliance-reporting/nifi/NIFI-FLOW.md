# NiFi flow

`report.py` is fine for a one-off answer. When the data needs to land in a database every day,
I run it through NiFi.

## Flow

```
report.py (scheduled) -> ListFile -> FetchFile -> ConvertRecord -> UpdateRecord -> PutDatabaseRecord
```

- **ListFile / FetchFile** pick up new CSVs from `/data/input` (mounted from `../output`).
- **ConvertRecord** with a CSVReader and JsonRecordSetWriter.
- **UpdateRecord** adds `snapshotDate` and `checkName` to each record. Without a date column
  you only ever see today's state, with it you can chart the trend.
- **PutDatabaseRecord** writes into PostgreSQL or Azure SQL. Power BI or Grafana reads from there.

Generating the CSVs can be done with `ExecuteProcess` inside NiFi, but I find a plain cron job
calling `report.py` easier to debug.

## Running NiFi locally

```bash
python ../report.py
docker compose up -d
```

Then open https://localhost:8443/nifi (self-signed cert, so the browser will complain) and log
in with the credentials from `docker-compose.yml`. Change the password if this is running
anywhere other than your own machine.
