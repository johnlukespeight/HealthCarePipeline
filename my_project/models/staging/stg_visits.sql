-- Staging model for patient visits data
-- This model processes visit information and calculates key metrics

{{ config(
    materialized='table',
    partition_by={
        "field": "visit_date",
        "data_type": "date"
    },
    cluster_by=["patient_id", "department"]
) }}

with source_data as (
    select * from {{ source('healthcare', 'visits') }}
),

cleaned_visits as (
    select
        -- Primary keys
        visit_id,
        patient_id,
        
        -- Visit details
        visit_date,
        visit_time,
        datetime(visit_date, visit_time) as visit_datetime,
        
        -- Department and provider information
        department,
        doctor_name,
        doctor_specialty,
        
        -- Visit classification
        visit_type,
        case 
            when visit_type in ('Emergency', 'Urgent') then 'Urgent Care'
            when visit_type in ('Routine', 'Follow-up') then 'Routine Care'
            else 'Other'
        end as care_category,
        
        -- Clinical information
        chief_complaint,
        diagnosis,
        diagnosis_code,
        treatment_plan,
        
        -- Visit metrics
        duration_minutes,
        case 
            when duration_minutes < 30 then 'Short'
            when duration_minutes between 30 and 60 then 'Standard'
            else 'Extended'
        end as visit_length_category,
        
        -- Financial information
        visit_cost,
        insurance_coverage,
        patient_payment,
        
        -- Status and outcomes
        visit_status,
        follow_up_required,
        follow_up_date,
        
        -- Metadata
        current_timestamp() as created_date,
        current_timestamp() as updated_date
        
    from source_data
    where visit_id is not null 
      and patient_id is not null
      and visit_date is not null
),

final as (
    select 
        *,
        -- Add calculated fields
        case 
            when visit_cost > 0 and insurance_coverage > 0 then true 
            else false 
        end as has_insurance_coverage,
        
        case 
            when follow_up_required = true and follow_up_date is not null then true 
            else false 
        end as has_scheduled_followup
        
    from cleaned_visits
)

select * from final
