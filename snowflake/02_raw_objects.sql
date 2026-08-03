USE ROLE TRADE_PIPELINE_ROLE;
USE WAREHOUSE TRADE_WH;
USE DATABASE TRADE_DB;
USE SCHEMA RAW;

CREATE TABLE IF NOT EXISTS RAW_TRADES (
  event_id STRING NOT NULL,
  trade_id STRING NOT NULL,
  version NUMBER(10,0) NOT NULL,
  counterparty_id STRING,
  instrument_id STRING,
  trade_date DATE,
  maturity_date DATE,
  quantity NUMBER(18,4),
  price NUMBER(18,6),
  currency STRING,
  side STRING,
  source_system STRING,
  event_ts TIMESTAMP_TZ,
  batch_id STRING,
  source_file STRING,
  ingested_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
  CONSTRAINT uq_raw_event UNIQUE (event_id)
);

CREATE STAGE IF NOT EXISTS TRADE_INTERNAL_STAGE;

-- Optional CDC object used for operational visibility and extension to task-based processing.
CREATE STREAM IF NOT EXISTS RAW_TRADES_STREAM
  ON TABLE RAW_TRADES APPEND_ONLY=TRUE;
