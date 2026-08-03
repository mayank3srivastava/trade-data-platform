# Scalability and failure handling

## File arrival delay

- Run `dbt source freshness` before transformations.
- Configure an Airflow timeout/retry policy and an SLA/failure callback.
- Use the Snowflake `NO_TRADE_ARRIVAL_ALERT` for independent warehouse-side detection.
- Keep a batch manifest with file name, checksum, arrival time and load status in a production extension.

## Data-quality failures

- Invalid business events are quarantined, not discarded.
- dbt generic and singular tests fail the deployment or Airflow task.
- Store rejection reason, source file, batch ID and original event metadata for compliance.
- Use thresholds for rejection rate, not only binary tests, to catch upstream drift.

## Task failures

- Airflow retries twice with exponential backoff.
- Loading is idempotent through Snowflake COPY history and event IDs.
- dbt incremental merges are restartable.
- Failed DAG runs send email and remain visible in Airflow; Snowflake query history retains execution evidence.

## Scaling 10,000x

- Replace local generation/PUT with Snowpipe Streaming or cloud object storage plus auto-ingest Snowpipe.
- Partition producers by source/region and preserve immutable event IDs.
- Use dbt incremental microbatch models and narrow source predicates.
- Separate ingestion, transformation and BI warehouses; enable multi-cluster only where concurrency requires it.
- Size warehouses based on measured bytes scanned and queueing, then auto-suspend aggressively.
- Add clustering only after query-history evidence shows poor pruning on large tables.
- Process independent batches in parallel while serializing updates for the same trade ID.
- Add an event/batch control table and dead-letter replay workflow.
