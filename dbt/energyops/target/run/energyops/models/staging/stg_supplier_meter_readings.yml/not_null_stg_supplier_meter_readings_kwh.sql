select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select kwh
from "energyops"."analytics"."stg_supplier_meter_readings"
where kwh is null



      
    ) dbt_internal_test