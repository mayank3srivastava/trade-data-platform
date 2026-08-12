
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  select *
from TRADE_DB.DBT_CURATED.current_trades
where quantity <= 0 or price <= 0
  
  
      
    ) dbt_internal_test