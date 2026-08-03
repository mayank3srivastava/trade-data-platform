{{ config(materialized='view') }}

select
  *,
  case when maturity_date < current_date() then 'EXPIRED' else 'VALID' end as trade_status
from {{ ref('current_trades') }}
