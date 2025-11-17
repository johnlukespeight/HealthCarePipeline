-- Patient summary mart
-- Aggregates key patient metrics and demographics

{{ config(materialized='table') }}

with patient_visits as (
    select 
        patient_id,
        count(*) as total_visits,
        count(distinct date(visit_date)) as unique_visit_days,
        min(visit_date) as first_visit_date,
        max(visit_date) as last_visit_date,
        avg(duration_minutes) as avg_visit_duration,
        sum(visit_cost) as total_visit_costs,
        sum(insurance_coverage) as total_insurance_coverage,
        count(case when visit_type = 'Emergency' then 1 end) as emergency_visits,
        count(case when follow_up_required = true then 1 end) as visits_requiring_followup
    from {{ ref('stg_visits') }}
    group by patient_id
),

patient_lab_results as (
    select 
        patient_id,
        count(*) as total_lab_tests,
        count(case when is_abnormal = true then 1 end) as abnormal_results,
        count(case when test_category = 'High' then 1 end) as high_results,
        count(case when test_category = 'Low' then 1 end) as low_results,
        max(test_date) as last_lab_test_date,
        count(distinct test_type) as unique_test_types
    from {{ ref('stg_lab_results') }}
    group by patient_id
)

select 
    p.patient_id,
    p.first_name,
    p.last_name,
    p.age,
    p.age_group,
    p.gender,
    p.blood_type,
    p.insurance_provider,
    p.city,
    p.state,
    p.has_valid_email,
    p.has_valid_phone,
    
    -- Visit metrics
    coalesce(pv.total_visits, 0) as total_visits,
    coalesce(pv.unique_visit_days, 0) as unique_visit_days,
    pv.first_visit_date,
    pv.last_visit_date,
    pv.avg_visit_duration,
    pv.total_visit_costs,
    pv.total_insurance_coverage,
    pv.emergency_visits,
    pv.visits_requiring_followup,
    
    -- Lab metrics
    coalesce(plr.total_lab_tests, 0) as total_lab_tests,
    coalesce(plr.abnormal_results, 0) as abnormal_results,
    coalesce(plr.high_results, 0) as high_results,
    coalesce(plr.low_results, 0) as low_results,
    plr.last_lab_test_date,
    coalesce(plr.unique_test_types, 0) as unique_test_types,
    
    -- Calculated fields
    case 
        when pv.total_visits > 10 then 'High Utilizer'
        when pv.total_visits between 5 and 10 then 'Moderate Utilizer'
        when pv.total_visits between 1 and 4 then 'Low Utilizer'
        else 'No Visits'
    end as utilization_category,
    
    case 
        when plr.abnormal_results > 0 then 'Has Abnormal Results'
        when plr.total_lab_tests > 0 then 'All Normal Results'
        else 'No Lab Tests'
    end as lab_status,
    
    p.created_date,
    p.updated_date

from {{ ref('stg_patients') }} p
left join patient_visits pv on p.patient_id = pv.patient_id
left join patient_lab_results plr on p.patient_id = plr.patient_id
