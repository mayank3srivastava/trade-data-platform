select *
from TRADE_DB.DBT_CURATED.current_trades
where quantity <= 0 or price <= 0