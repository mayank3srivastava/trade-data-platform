
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select rejection_reason
from TRADE_DB.DBT_CURATED.rejected_trades
where rejection_reason is null



  
  
      
    ) dbt_internal_test