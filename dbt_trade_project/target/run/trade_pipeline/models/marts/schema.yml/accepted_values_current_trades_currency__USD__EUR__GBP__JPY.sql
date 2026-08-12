
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        currency as value_field,
        count(*) as n_records

    from TRADE_DB.DBT_CURATED.current_trades
    group by currency

)

select *
from all_values
where value_field not in (
    'USD','EUR','GBP','JPY'
)



  
  
      
    ) dbt_internal_test