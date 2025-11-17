-- Staging model for patient data
-- This model cleans and standardizes patient information from CSV sources

{{ config(
    materialized='table',
    partition_by={
        "field": "created_date",
        "data_type": "date"
    },
    cluster_by=["patient_id", "age_group"]
) }}

with source_data as (
    select * from {{ source('healthcare', 'patients') }}
),

cleaned_patients as (
    select
        -- Primary key
        patient_id,
        
        -- Demographics
        trim(upper(first_name)) as first_name,
        trim(upper(last_name)) as last_name,
        date_of_birth,
        
        -- Calculate age and age group
        date_diff(current_date(), date_of_birth, year) as age,
        case 
            when date_diff(current_date(), date_of_birth, year) < 18 then 'Pediatric'
            when date_diff(current_date(), date_of_birth, year) between 18 and 64 then 'Adult'
            else 'Senior'
        end as age_group,
        
        -- Contact information
        trim(lower(email)) as email,
        phone,
        address,
        city,
        state,
        zip_code,
        
        -- Medical information
        gender,
        blood_type,
        insurance_provider,
        emergency_contact_name,
        emergency_contact_phone,
        
        -- Metadata
        current_timestamp() as created_date,
        current_timestamp() as updated_date
        
    from source_data
    where patient_id is not null
),

final as (
    select 
        *,
        -- Add data quality flags
        case 
            when email is not null and email like '%@%' then true 
            else false 
        end as has_valid_email,
        
        case 
            when phone is not null and length(replace(replace(phone, '-', ''), ' ', '')) >= 10 then true 
            else false 
        end as has_valid_phone
        
    from cleaned_patients
)

select * from final
