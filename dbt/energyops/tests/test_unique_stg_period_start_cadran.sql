-- Un relevé par cadran et par début de période.
select
  period_start,
  cadran,
  count(*) as n
from {{ ref('stg_supplier_meter_readings') }}
group by 1,2
having count(*) > 1