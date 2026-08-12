"""Airflow DAG for generation, Snowflake loading, dbt build, and audit logging."""

from __future__ import annotations

import os
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator


PROJECT_ROOT = os.getenv(
    "TRADE_PROJECT_ROOT",
    "/opt/airflow/trade-data-platform",
)

ALERT_EMAIL = os.getenv(
    "PIPELINE_ALERT_EMAIL",
    "data-engineering@example.com",
)

PYTHON_BIN = os.getenv(
    "TRADE_PYTHON_BIN",
    f"{PROJECT_ROOT}/.venv/bin/python",
)

DBT_BIN = os.getenv(
    "TRADE_DBT_BIN",
    f"{PROJECT_ROOT}/.venv-dbt/bin/dbt",
)


DEFAULT_ARGS = {
    "owner": "trade-data-platform",
    "depends_on_past": False,
    "email": [ALERT_EMAIL],
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "retry_exponential_backoff": True,
    "max_retry_delay": timedelta(minutes=30),
}


with DAG(
    dag_id="trade_data_pipeline",
    description="Generate, load, validate, and publish trade data",
    default_args=DEFAULT_ARGS,
    start_date=datetime(2026, 1, 1),
    schedule="*/15 * * * *",
    catchup=False,
    max_active_runs=1,
    tags=["snowflake", "dbt", "trades"],
) as dag:

    generate_trades = BashOperator(
        task_id="generate_trades",
        bash_command=(
            f"{PYTHON_BIN} "
            f"{PROJECT_ROOT}/data_generator/trade_generator.py "
            f"--count 1000 "
            f"--invalid-ratio 0.10 "
            f"--output "
            f"{PROJECT_ROOT}/sample_data/"
            f"trades_{{{{ ts_nodash }}}}.csv"
        ),
        env={**os.environ},
    )

    load_to_snowflake = BashOperator(
        task_id="load_to_snowflake",
        bash_command=(
            f"{PYTHON_BIN} "
            f"{PROJECT_ROOT}/data_generator/load_to_snowflake.py "
            f"--file "
            f"{PROJECT_ROOT}/sample_data/"
            f"trades_{{{{ ts_nodash }}}}.csv"
        ),
        env={**os.environ},
    )

    check_source_freshness = BashOperator(
        task_id="check_source_freshness",
        bash_command=(
            f"cd {PROJECT_ROOT}/dbt_trade_project && "
            f"{DBT_BIN} source freshness "
            f"--profiles-dir ~/.dbt"
        ),
        env={
            **os.environ,
            "DBT_SEND_ANONYMOUS_USAGE_STATS": "false",
        },
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=(
            f"cd {PROJECT_ROOT}/dbt_trade_project && "
            f"{DBT_BIN} build "
            f"--profiles-dir ~/.dbt "
            f"--fail-fast"
        ),
        env={
            **os.environ,
            "DBT_SEND_ANONYMOUS_USAGE_STATS": "false",
        },
    )

    audit_success = SQLExecuteQueryOperator(
        task_id="audit_success",
        conn_id="snowflake_trade",
        sql="""
        INSERT INTO TRADE_DB.MONITORING.PIPELINE_RUN_LOG
        (
            run_id,
            dag_id,
            status,
            started_at,
            completed_at,
            records_loaded,
            records_rejected
        )
        SELECT
            '{{ run_id }}',
            '{{ dag.dag_id }}',
            'SUCCESS',
            '{{ dag_run.start_date }}'::timestamp_tz,
            CURRENT_TIMESTAMP(),

            COUNT_IF(
                ingested_at >=
                '{{ data_interval_start }}'::timestamp_tz
            ),

            (
                SELECT COUNT(*)
                FROM TRADE_DB.DBT_CURATED.REJECTED_TRADES
                WHERE rejected_at >=
                '{{ data_interval_start }}'::timestamp_tz
            )

        FROM TRADE_DB.RAW.RAW_TRADES;
        """,
    )

    (
        generate_trades
        >> load_to_snowflake
        >> check_source_freshness
        >> dbt_build
        >> audit_success
    )