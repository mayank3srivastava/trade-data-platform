

select
  *,
  case when maturity_date < current_date() then 'EXPIRED' else 'VALID' end as trade_status
from TRADE_DB.DBT_CURATED.current_trades