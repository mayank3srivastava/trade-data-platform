
  create or replace   view TRADE_DB.DBT_STAGING.stg_trades
  
  
  
  
  as (
    

with deduplicated as (
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
        upper(currency) as currency,
        upper(side) as side,
        source_system,
        event_ts,
        batch_id,
        source_file,
        ingested_at,
        row_number() over (partition by event_id order by ingested_at desc) as rn
    from TRADE_DB.RAW.raw_trades
)
select * exclude rn
from deduplicated
where rn = 1
  );

