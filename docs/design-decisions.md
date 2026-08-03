# Design decisions

## Version rules

- `incoming.version < current.version`: reject and retain the complete event in `REJECTED_TRADES`.
- `incoming.version = current.version`: replace the current payload using dbt's Snowflake `MERGE` materialization.
- `incoming.version > current.version`: update the current record.
- Multiple events for one trade/version in a batch: latest `event_ts` wins; other events are audited.

## Maturity rules

The brief contains two apparently conflicting rules. This implementation treats them as separate lifecycle moments:

1. A newly received trade whose maturity date is already before the processing date is rejected.
2. A previously accepted trade becomes `EXPIRED` automatically through the `TRADE_STATUS` view after its maturity date passes.

## Idempotency

`event_id` is the ingestion idempotency key. Rejected events use `event_id` as the dbt merge key, so retries do not create duplicate audit rows. Current trades use `trade_id` as the merge key.

## Processing ownership

Airflow owns end-to-end orchestration, retries and notifications. Snowflake owns storage, SQL execution, CDC metadata, administrative history and native alerts. dbt owns modular transformation logic, documentation and data tests.
