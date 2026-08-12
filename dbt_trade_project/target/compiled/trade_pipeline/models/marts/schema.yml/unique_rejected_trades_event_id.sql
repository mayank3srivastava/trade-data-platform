
    
    

select
    event_id as unique_field,
    count(*) as n_records

from TRADE_DB.DBT_CURATED.rejected_trades
where event_id is not null
group by event_id
having count(*) > 1


