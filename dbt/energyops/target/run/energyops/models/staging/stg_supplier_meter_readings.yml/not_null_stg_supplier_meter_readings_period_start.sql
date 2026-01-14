select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select period_start
from "energyops"."analytics"."stg_supplier_meter_readings"
where period_start is null



      
    ) dbt_internal_test