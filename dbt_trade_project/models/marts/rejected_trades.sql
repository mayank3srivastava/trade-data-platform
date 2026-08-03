{{ config(
    materialized='incremental',
    unique_key='event_id',
    incremental_strategy='merge',
    on_schema_change='sync_all_columns'
) }}

select
    event_id,
    trade_id,
    version,
    counterparty_id,
    instrument_id,
    trade_date,
    maturity_date,
    quantity,
    price,
    currency,
    side,
    source_system,
    event_ts,
    batch_id,
    source_file,
    rejection_reason,
    current_timestamp() as rejected_at
from {{ ref('int_trade_decisions') }}
where decision = 'REJECT'
{% if is_incremental() %}
  and ingested_at >= coalesce((select dateadd('hour', -1, max(rejected_at)) from {{ this }}), '1900-01-01')
{% endif %}
