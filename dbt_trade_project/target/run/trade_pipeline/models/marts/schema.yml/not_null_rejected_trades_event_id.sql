
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select event_id
from TRADE_DB.DBT_CURATED.rejected_trades
where event_id is null



  
  
      
    ) dbt_internal_test