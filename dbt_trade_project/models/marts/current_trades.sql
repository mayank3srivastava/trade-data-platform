{{ config(
    materialized='incremental',
    unique_key='trade_id',
    incremental_strategy='merge',
    merge_update_columns=[
      'version','counterparty_id','instrument_id','trade_date','maturity_date',
      'quantity','price','currency','side','source_system','event_ts','batch_id',
      'source_event_id','updated_at'
    ],
    on_schema_change='sync_all_columns'
) }}

select
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
    event_id as source_event_id,
    current_timestamp() as updated_at
from {{ ref('int_trade_decisions') }}
where decision = 'ACCEPT'
{% if is_incremental() %}
  and ingested_at >= coalesce((select dateadd('hour', -1, max(updated_at)) from {{ this }}), '1900-01-01')
{% endif %}
qualify row_number() over (
  partition by trade_id
  order by version desc, event_ts desc, ingested_at desc, event_id desc
) = 1
