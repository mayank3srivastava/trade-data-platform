
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select version
from TRADE_DB.DBT_CURATED.current_trades
where version is null



  
  
      
    ) dbt_internal_test