
  
    

create or replace transient table TRADE_DB.DBT_CURATED.rejected_trades
    
    
    
    as (

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
from TRADE_DB.DBT_INTERMEDIATE.int_trade_decisions
where decision = 'REJECT'

    )
;


  