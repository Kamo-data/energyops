
  
    

  create  table "energyops"."analytics"."agg_energy_calendar_month_est__dbt_tmp"
  
  
    as
  
  (
    with base as (
  select
    period_start,
    period_end,
    period_days,
    kwh_hp,
    kwh_hc,
    kwh_total,
    cost_est_eur
  from "energyops"."analytics"."fct_energy_period"
),

monthly as (
  select
    date_trunc('month', period_end)::date as month,
    sum(kwh_hp) as kwh_hp,
    sum(kwh_hc) as kwh_hc,
    sum(kwh_total) as kwh_total,
    sum(cost_est_eur) as cost_est_eur,
    sum(period_days) as days_covered,
    (sum(kwh_total) / nullif(sum(period_days), 0))::numeric(12,3) as kwh_per_day_est
  from base
  group by 1
)

select
  month,
  kwh_hp,
  kwh_hc,
  kwh_total,
  cost_est_eur,
  days_covered,
  kwh_per_day_est
from monthly
order by month
  );
  