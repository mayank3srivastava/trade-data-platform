#!/usr/bin/env python3
"""Upload a CSV to a Snowflake internal stage and load it into RAW_TRADES."""
from __future__ import annotations

import argparse
import os
import uuid
from pathlib import Path

import snowflake.connector

REQUIRED_ENV = [
    "SNOWFLAKE_ACCOUNT", "SNOWFLAKE_USER", "SNOWFLAKE_PASSWORD",
    "SNOWFLAKE_ROLE", "SNOWFLAKE_WAREHOUSE", "SNOWFLAKE_DATABASE"
]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", required=True)
    parser.add_argument("--schema", default=os.getenv("SNOWFLAKE_RAW_SCHEMA", "RAW"))
    args = parser.parse_args()

    missing = [name for name in REQUIRED_ENV if not os.getenv(name)]
    if missing:
        raise RuntimeError(f"Missing environment variables: {', '.join(missing)}")

    file_path = Path(args.file).resolve()
    if not file_path.exists():
        raise FileNotFoundError(file_path)

    batch_id = str(uuid.uuid4())
    conn = snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        role=os.environ["SNOWFLAKE_ROLE"],
        warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
        database=os.environ["SNOWFLAKE_DATABASE"],
        schema=args.schema,
    )
    try:
        with conn.cursor() as cur:
            cur.execute("CREATE STAGE IF NOT EXISTS TRADE_INTERNAL_STAGE")
            cur.execute(f"PUT 'file://{file_path}' @TRADE_INTERNAL_STAGE AUTO_COMPRESS=TRUE OVERWRITE=TRUE")
            cur.execute(
                """
                COPY INTO RAW_TRADES (
                    event_id, trade_id, version, counterparty_id, instrument_id,
                    trade_date, maturity_date, quantity, price, currency, side,
                    source_system, event_ts, batch_id, source_file
                )
                FROM (
                    SELECT $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,%s,
                           METADATA$FILENAME
                    FROM @TRADE_INTERNAL_STAGE
                )
                FILE_FORMAT=(TYPE=CSV SKIP_HEADER=1 FIELD_OPTIONALLY_ENCLOSED_BY='"')
                ON_ERROR='ABORT_STATEMENT'
                """,
                (batch_id,),
            )
            result = cur.fetchone()
            print(f"Loaded batch_id={batch_id}; COPY result={result}")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
