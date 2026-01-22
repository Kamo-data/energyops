-- La consommation sur une période ne doit pas être négative.
-- Si ça arrive : reset compteur ou anomalie source -> à traiter explicitement dans le modèle.
select *
from {{ ref('fct_energy_period') }}
where
  coalesce(kwh_hp, 0) < 0
  or coalesce(kwh_hc, 0) < 0
  or coalesce(kwh_total, 0) < 0