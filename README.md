# Snowflake Trade Data Platform Case Study

A GitHub-ready implementation of a scalable trade ingestion, validation, audit and reporting pipeline using Snowflake, dbt, Airflow, Terraform and GitHub Actions.

## Architecture

```text
Mock trade producer
       |
Python CSV generator
       |
Snowflake internal stage + COPY INTO
       |
TRADE_DB.RAW.RAW_TRADES
       |
Airflow -> dbt source freshness -> dbt build/tests
       |
       +--> CURATED.CURRENT_TRADES (latest accepted trade)
       +--> CURATED.REJECTED_TRADES (compliance audit)
       +--> CURATED.TRADE_STATUS (VALID / EXPIRED)
       |
Streamlit / BI + Snowflake monitoring views and alerts
```

PlantUML source: [`architecture/architecture.puml`](architecture/architecture.puml).

## Business rules

| Rule | Implementation |
|---|---|
| Lower version than current | Reject with `LOWER_THAN_EXISTING_VERSION` |
| Same version | Latest payload replaces current row via Snowflake `MERGE` |
| Higher version | Updates current row |
| New trade already matured | Reject with `MATURITY_DATE_IN_PAST` |
| Accepted trade later matures | Dynamic `EXPIRED` status in `TRADE_STATUS` view |
| Invalid quantity/price | Reject |
| Invalid side/currency | Reject |
| Duplicate event retry | Idempotent by `event_id` |

See [`docs/design-decisions.md`](docs/design-decisions.md) for assumptions.

## Repository structure

```text
architecture/             PlantUML architecture
 data_generator/          Mock generator and Snowflake loader
 snowflake/               Bootstrap, raw objects, monitoring and alerts
 dbt_trade_project/       dbt staging, decisions, marts and tests
 airflow/dags/             Orchestration DAG
 terraform/               Snowflake IaC starter
 monitoring/              Administrative monitoring queries
 streamlit_dashboard/     Optional status dashboard
 .github/workflows/       CI and deployment workflows
 docs/                    Design and operational documentation
```

## Prerequisites

- Python 3.11+
- Snowflake account with permission to create the case-study objects
- dbt Core with `dbt-snowflake`
- Airflow 2.10+ for orchestration demonstration
- Terraform 1.6+ for optional IaC

## Setup

### 1. Clone and configure

```bash
git clone <your-public-repository-url>
cd trade-data-platform
python -m venv .venv
source .venv/bin/activate
cp .env.example .env
set -a && source .env && set +a
pip install -r data_generator/requirements.txt
pip install -r dbt_trade_project/requirements.txt
```

Never commit `.env`, passwords or private keys.

### 2. Provision Snowflake

Run in Snowsight in order:

```text
snowflake/01_bootstrap.sql
snowflake/02_raw_objects.sql
snowflake/03_monitoring_objects.sql
```

`01_bootstrap.sql` uses `ACCOUNTADMIN` only for the initial demo setup. A production deployment should use a dedicated security-administration workflow and least-privilege custom roles.

### 3. Configure dbt

```bash
cp dbt_trade_project/profiles.yml.example dbt_trade_project/profiles.yml
cd dbt_trade_project
dbt debug --profiles-dir .
cd ..
```

### 4. Generate and load data

```bash
python data_generator/trade_generator.py \
  --count 1000 \
  --invalid-ratio 0.10 \
  --seed 42 \
  --output sample_data/trades.csv

python data_generator/load_to_snowflake.py --file sample_data/trades.csv
```

### 5. Transform and validate

```bash
cd dbt_trade_project
dbt source freshness --profiles-dir .
dbt build --profiles-dir .
```

Inspect:

```sql
SELECT * FROM TRADE_DB.CURATED.CURRENT_TRADES;
SELECT * FROM TRADE_DB.CURATED.REJECTED_TRADES;
SELECT trade_status, COUNT(*) FROM TRADE_DB.CURATED.TRADE_STATUS GROUP BY 1;
```

### 6. Run dashboard

```bash
pip install -r streamlit_dashboard/requirements.txt
streamlit run streamlit_dashboard/app.py
```

## Airflow

Copy or mount the repository into the Airflow environment and configure:

- Environment variables from `.env.example`
- Airflow connection `snowflake_trade`
- SMTP settings for `email_on_failure`
- `TRADE_PROJECT_ROOT` pointing to the mounted repository

The DAG runs every 15 minutes:

```text
generate_trades -> load_to_snowflake -> source_freshness -> dbt_build -> audit_success
```

## Monitoring and alerts

Use [`monitoring/snowflake_monitoring.sql`](monitoring/snowflake_monitoring.sql) to inspect:

- `ACCOUNT_USAGE.QUERY_HISTORY`
- `ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY`
- `ACCOUNT_USAGE.COPY_HISTORY`
- `INFORMATION_SCHEMA.TASK_HISTORY`
- ingestion freshness and rejection trends

Optional native email alert setup is in [`snowflake/04_alerts.sql`](snowflake/04_alerts.sql). Replace the placeholder email and run with the privileges required to create a notification integration.

## CI/CD

The CI workflow performs:

1. Python linting
2. dbt dependency resolution and compile
3. Terraform formatting and validation

The deployment workflow runs dbt against Snowflake on `main` or manual dispatch. Add Snowflake credentials as encrypted GitHub environment secrets. For a bank-grade implementation, use key-pair/OIDC authentication rather than a password.

## Demo script for interview

1. Show the architecture and repository structure.
2. Generate 20–100 trades with a fixed seed.
3. Load them and run `dbt build`.
4. Query current and rejected tables.
5. Re-send a same-version trade with changed price and show replacement.
6. Send a lower version and show its audit rejection.
7. Explain restartability, monitoring, delayed arrival handling and 10,000x scaling.

## Known production extensions

- Snowpipe Streaming or auto-ingest Snowpipe instead of local PUT
- Key-pair authentication and secret manager
- Batch manifest/control table and automated replay
- Row-access/masking policies for sensitive fields
- Separate warehouses by workload
- Threshold-based data-quality alerts
- Blue/green dbt deployment and environment isolation

See [`docs/scalability-and-failure-handling.md`](docs/scalability-and-failure-handling.md).
