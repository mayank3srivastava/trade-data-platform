-- Recent pipeline queries
SELECT query_id, query_text, execution_status, total_elapsed_time, bytes_scanned,
       rows_inserted, rows_updated, rows_deleted, start_time
FROM snowflake.account_usage.query_history
WHERE start_time >= dateadd('hour', -24, current_timestamp())
  AND (query_text ILIKE '%TRADE_DB%' OR query_tag ILIKE '%trade%')
ORDER BY start_time DESC;

-- Warehouse saturation and queueing
SELECT warehouse_name, start_time, avg_running, avg_queued_load, avg_queued_provisioning
FROM snowflake.account_usage.warehouse_load_history
WHERE start_time >= dateadd('hour', -24, current_timestamp())
  AND warehouse_name = 'TRADE_WH'
ORDER BY start_time DESC;

-- Load/COPY history
SELECT file_name, status, row_count, row_parsed, first_error_message, last_load_time
FROM snowflake.account_usage.copy_history
WHERE table_name = 'RAW_TRADES'
  AND last_load_time >= dateadd('day', -7, current_timestamp())
ORDER BY last_load_time DESC;

-- Task history, if Snowflake tasks are added for native scheduling
SELECT name, state, error_code, error_message, scheduled_time, completed_time
FROM TABLE(information_schema.task_history(scheduled_time_range_start=>dateadd('day', -7, current_timestamp())))
ORDER BY scheduled_time DESC;

-- Freshness / arrival delay
SELECT max(ingested_at) AS latest_ingestion,
       datediff('minute', max(ingested_at), current_timestamp()) AS minutes_since_last_trade
FROM TRADE_DB.RAW.RAW_TRADES;

-- Rejection rate by hour
SELECT date_trunc('hour', rejected_at) AS hour,
       count(*) AS rejected_count
FROM TRADE_DB.CURATED.REJECTED_TRADES
WHERE rejected_at >= dateadd('day', -7, current_timestamp())
GROUP BY 1 ORDER BY 1 DESC;
