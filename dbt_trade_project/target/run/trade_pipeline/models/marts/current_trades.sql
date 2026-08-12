
  
    

create or replace transient table TRADE_DB.DBT_CURATED.current_trades
    
    
    
    as (

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
from TRADE_DB.DBT_INTERMEDIATE.int_trade_decisions
where decision = 'ACCEPT'

qualify row_number() over (
  partition by trade_id
  order by version desc, event_ts desc, ingested_at desc, event_id desc
) = 1
    )
;


  