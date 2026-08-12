

with incoming as (
    select *
    from TRADE_DB.DBT_STAGING.stg_trades
),
current_state as (
    
    select cast(null as string) trade_id, cast(null as number) existing_version where false
    
),
ranked_batch as (
    select
        i.*,
        c.existing_version,
        max(i.version) over (partition by i.trade_id) as max_incoming_version,
        row_number() over (
            partition by i.trade_id, i.version
            order by i.event_ts desc, i.ingested_at desc, i.event_id desc
        ) as same_version_rank
    from incoming i
    left join current_state c using (trade_id)
)
select
    *,
    case
      when trade_id is null or trim(trade_id) = '' then 'REJECT'
      when version is null or version < 1 then 'REJECT'
      when maturity_date < current_date() then 'REJECT'
      when quantity <= 0 then 'REJECT'
      when price <= 0 then 'REJECT'
      when currency not in ('USD','EUR','GBP','JPY') then 'REJECT'
      when side not in ('BUY','SELL') then 'REJECT'
      when existing_version is not null and version < existing_version then 'REJECT'
      when version < max_incoming_version then 'REJECT'
      when same_version_rank > 1 then 'REJECT'
      else 'ACCEPT'
    end as decision,
    case
      when trade_id is null or trim(trade_id) = '' then 'MISSING_TRADE_ID'
      when version is null or version < 1 then 'INVALID_VERSION'
      when maturity_date < current_date() then 'MATURITY_DATE_IN_PAST'
      when quantity <= 0 then 'NON_POSITIVE_QUANTITY'
      when price <= 0 then 'NON_POSITIVE_PRICE'
      when currency not in ('USD','EUR','GBP','JPY') then 'INVALID_CURRENCY'
      when side not in ('BUY','SELL') then 'INVALID_SIDE'
      when existing_version is not null and version < existing_version then 'LOWER_THAN_EXISTING_VERSION'
      when version < max_incoming_version then 'SUPERSEDED_IN_SAME_BATCH'
      when same_version_rank > 1 then 'DUPLICATE_SAME_VERSION_EVENT'
      else null
    end as rejection_reason
from ranked_batch