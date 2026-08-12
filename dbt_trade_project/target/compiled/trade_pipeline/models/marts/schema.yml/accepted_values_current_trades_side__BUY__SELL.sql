
    
    

with all_values as (

    select
        side as value_field,
        count(*) as n_records

    from TRADE_DB.DBT_CURATED.current_trades
    group by side

)

select *
from all_values
where value_field not in (
    'BUY','SELL'
)


