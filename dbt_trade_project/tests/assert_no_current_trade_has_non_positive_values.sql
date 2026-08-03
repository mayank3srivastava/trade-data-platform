select *
from {{ ref('current_trades') }}
where quantity <= 0 or price <= 0
