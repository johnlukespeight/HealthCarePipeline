-- Staging model for laboratory results data
-- This model processes lab test results and normalizes values

{{ config(
    materialized='table',
    partition_by={
        "field": "test_date",
        "data_type": "date"
    },
    cluster_by=["patient_id", "test_type"]
) }}

with source_data as (
    select * from {{ source('healthcare', 'lab_results') }}
),

cleaned_lab_results as (
    select
        -- Primary keys
        lab_result_id,
        patient_id,
        visit_id,
        
        -- Test information
        test_name,
        test_type,
        test_category,
        
        -- Test details
        test_date,
        test_time,
        datetime(test_date, test_time) as test_datetime,
        
        -- Results
        result_value,
        result_unit,
        reference_range_min,
        reference_range_max,
        
        -- Normalize result values for numeric tests
        case 
            when test_type = 'Numeric' and result_value is not null 
            then safe_cast(result_value as float64)
            else null
        end as numeric_result_value,
        
        -- Determine if result is abnormal
        case 
            when test_type = 'Numeric' 
                 and safe_cast(result_value as float64) is not null
                 and reference_range_min is not null 
                 and reference_range_max is not null
            then safe_cast(result_value as float64) not between reference_range_min and reference_range_max
            else null
        end as is_abnormal,
        
        -- Result interpretation
        result_interpretation,
        case 
            when result_interpretation in ('High', 'Elevated', 'Above Normal') then 'High'
            when result_interpretation in ('Low', 'Decreased', 'Below Normal') then 'Low'
            when result_interpretation in ('Normal', 'Within Range') then 'Normal'
            else 'Unknown'
        end as result_category,
        
        -- Lab information
        lab_name,
        lab_location,
        technician_name,
        
        -- Quality control
        quality_control_passed,
        retest_required,
        
        -- Metadata
        current_timestamp() as created_date,
        current_timestamp() as updated_date
        
    from source_data
    where lab_result_id is not null 
      and patient_id is not null
      and test_date is not null
),

final as (
    select 
        *,
        -- Add calculated fields
        case 
            when is_abnormal = true then 'Abnormal'
            when is_abnormal = false then 'Normal'
            else 'Unknown'
        end as result_status,
        
        -- Calculate days since test
        date_diff(current_date(), test_date, day) as days_since_test
        
    from cleaned_lab_results
)

select * from final
