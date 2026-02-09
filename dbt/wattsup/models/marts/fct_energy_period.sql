with base as (
  select
    period_start,
    period_end,
    max(period_days) as period_days,
    sum(kwh) filter (where cadran = 'HP') as kwh_hp,
    sum(kwh) filter (where cadran = 'HC') as kwh_hc
  from {{ ref('stg_supplier_meter_readings') }}
  group by 1,2
),

tar as (
  select
    b.*,
    t.hp_eur_per_kwh,
    t.hc_eur_per_kwh
  from base b
  left join lateral (
    select
      hp_eur_per_kwh,
      hc_eur_per_kwh
    from config.tariff_hp_hc
    where effective_from <= b.period_end
    order by effective_from desc
    limit 1
  ) t on true
)

select
  period_start,
  period_end,
  period_days,

  -- Conso (kWh)
  coalesce(kwh_hp, 0) as kwh_hp,
  coalesce(kwh_hc, 0) as kwh_hc,
  (coalesce(kwh_hp, 0) + coalesce(kwh_hc, 0)) as kwh_total,

  -- Estimation (kWh/j)
  ((coalesce(kwh_hp, 0) + coalesce(kwh_hc, 0)) / nullif(period_days, 0))::numeric(12,3) as kwh_per_day_est,

  -- Tarifs (€/kWh)
  hp_eur_per_kwh,
  hc_eur_per_kwh,

  -- Flags qualité : conso négative = reset compteur / incohérence source
  (
    coalesce(kwh_hp, 0) < 0
    or coalesce(kwh_hc, 0) < 0
    or (coalesce(kwh_hp, 0) + coalesce(kwh_hc, 0)) < 0
  ) as has_negative_kwh,

  -- Coût estimé : neutralisé en cas d'anomalie
  case
    when (
      coalesce(kwh_hp, 0) < 0
      or coalesce(kwh_hc, 0) < 0
      or (coalesce(kwh_hp, 0) + coalesce(kwh_hc, 0)) < 0
    )
      then null
    else (coalesce(kwh_hp, 0) * hp_eur_per_kwh + coalesce(kwh_hc, 0) * hc_eur_per_kwh)::numeric(12,2)
  end as cost_est_eur

from tar
order by period_end
