select
  period_start,
  period_end,
  trim(reading_type) as reading_type,
  upper(trim(cadran)) as cadran,
  index_start,
  index_end,
  kwh::numeric(12,3) as kwh,
  (period_end - period_start + 1) as period_days
from raw.supplier_meter_readings
