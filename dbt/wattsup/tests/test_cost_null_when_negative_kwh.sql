-- Si la conso est négative (reset compteur/anomalie), on ne sort pas de coût estimé.
select *
from {{ ref('fct_energy_period') }}
where has_negative_kwh = true
  and cost_est_eur is not null