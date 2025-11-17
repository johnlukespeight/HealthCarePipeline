-- Department metrics mart
-- Aggregates performance metrics by department

{{ config(materialized='table') }}

with department_visits as (
    select 
        department,
        count(*) as total_visits,
        count(distinct patient_id) as unique_patients,
        count(distinct doctor_name) as unique_doctors,
        avg(duration_minutes) as avg_visit_duration,
        sum(visit_cost) as total_revenue,
        sum(insurance_coverage) as total_insurance_payments,
        sum(patient_payment) as total_patient_payments,
        count(case when visit_type = 'Emergency' then 1 end) as emergency_visits,
        count(case when follow_up_required = true then 1 end) as followup_visits,
        count(case when visit_status = 'Completed' then 1 end) as completed_visits,
        count(case when visit_status = 'Cancelled' then 1 end) as cancelled_visits
    from {{ ref('stg_visits') }}
    group by department
),

department_lab_results as (
    select 
        v.department,
        count(lr.lab_result_id) as total_lab_tests,
        count(case when lr.is_abnormal = true then 1 end) as abnormal_tests,
        count(distinct lr.test_type) as unique_test_types,
        avg(case when lr.test_type = 'Numeric' then lr.numeric_result_value end) as avg_numeric_result
    from {{ ref('stg_visits') }} v
    left join {{ ref('stg_lab_results') }} lr on v.visit_id = lr.visit_id
    group by v.department
),

monthly_trends as (
    select 
        department,
        date_trunc(visit_date, month) as month,
        count(*) as monthly_visits,
        avg(duration_minutes) as avg_monthly_duration,
        sum(visit_cost) as monthly_revenue
    from {{ ref('stg_visits') }}
    group by department, date_trunc(visit_date, month)
)

select 
    dv.department,
    dv.total_visits,
    dv.unique_patients,
    dv.unique_doctors,
    dv.avg_visit_duration,
    dv.total_revenue,
    dv.total_insurance_payments,
    dv.total_patient_payments,
    dv.emergency_visits,
    dv.followup_visits,
    dv.completed_visits,
    dv.cancelled_visits,
    
    -- Lab metrics
    coalesce(dlr.total_lab_tests, 0) as total_lab_tests,
    coalesce(dlr.abnormal_tests, 0) as abnormal_tests,
    coalesce(dlr.unique_test_types, 0) as unique_test_types,
    dlr.avg_numeric_result,
    
    -- Calculated metrics
    round(dv.total_revenue / nullif(dv.total_visits, 0), 2) as avg_revenue_per_visit,
    round(dv.avg_visit_duration / 60, 2) as avg_visit_duration_hours,
    round(dv.emergency_visits * 100.0 / nullif(dv.total_visits, 0), 2) as emergency_visit_percentage,
    round(dv.followup_visits * 100.0 / nullif(dv.total_visits, 0), 2) as followup_visit_percentage,
    round(dv.completed_visits * 100.0 / nullif(dv.total_visits, 0), 2) as completion_rate,
    
    -- Performance indicators
    case 
        when dv.avg_visit_duration < 30 then 'Efficient'
        when dv.avg_visit_duration between 30 and 60 then 'Standard'
        else 'Extended'
    end as efficiency_category,
    
    case 
        when dv.emergency_visits * 100.0 / nullif(dv.total_visits, 0) > 20 then 'High Emergency'
        when dv.emergency_visits * 100.0 / nullif(dv.total_visits, 0) between 10 and 20 then 'Moderate Emergency'
        else 'Low Emergency'
    end as emergency_category,
    
    current_timestamp() as created_date

from department_visits dv
left join department_lab_results dlr on dv.department = dlr.department
