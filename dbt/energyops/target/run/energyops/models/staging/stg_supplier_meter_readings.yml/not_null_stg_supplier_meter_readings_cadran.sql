select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select cadran
from "energyops"."analytics"."stg_supplier_meter_readings"
where cadran is null



      
    ) dbt_internal_test