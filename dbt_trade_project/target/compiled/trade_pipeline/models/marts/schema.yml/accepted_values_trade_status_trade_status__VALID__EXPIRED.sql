
    
    

with all_values as (

    select
        trade_status as value_field,
        count(*) as n_records

    from TRADE_DB.DBT_CURATED.trade_status
    group by trade_status

)

select *
from all_values
where value_field not in (
    'VALID','EXPIRED'
)


