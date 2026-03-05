-- ============================================================
-- MODULE 1: SELECT, WHERE, ORDER BY, LIMIT
-- Healthcare SQL Analytics Interview Prep
-- ============================================================
-- Schema reference:
--   patients   (patient_id, first_name, last_name, date_of_birth, gender,
--               blood_type, insurance_provider, city, state)
--   visits     (visit_id, patient_id, visit_date, department, doctor_name,
--               visit_type, diagnosis, duration_minutes, visit_cost,
--               insurance_coverage, patient_payment, visit_status,
--               follow_up_required, follow_up_date)
--   lab_results (lab_result_id, patient_id, visit_id, test_name,
--               test_category, result_value, reference_range_min,
--               reference_range_max, is_abnormal, test_date)
-- ============================================================


-- ── CONCEPT 1: Basic SELECT ───────────────────────────────────
-- Retrieve specific columns instead of SELECT * for clarity and efficiency.

SELECT
    patient_id,
    first_name,
    last_name,
    gender,
    blood_type,
    insurance_provider
FROM patients;


-- ── CONCEPT 2: Column aliases (AS) ───────────────────────────
-- Rename columns in output — common in reports and dashboards.

SELECT
    patient_id                                      AS id,
    first_name || ' ' || last_name                 AS full_name,  -- concat
    insurance_provider                             AS payer
FROM patients;


-- ── CONCEPT 3: WHERE — filtering rows ───────────────────────
-- Only return rows that match a condition.

-- Single condition
SELECT visit_id, patient_id, department, visit_cost
FROM visits
WHERE department = 'Emergency';

-- Multiple conditions with AND
SELECT visit_id, patient_id, visit_cost, visit_status
FROM visits
WHERE department = 'Cardiology'
  AND visit_status = 'Completed';

-- OR — any matching condition
SELECT visit_id, patient_id, visit_type
FROM visits
WHERE visit_type = 'Emergency'
   OR visit_type = 'Urgent';

-- Equivalent using IN (cleaner for lists)
SELECT visit_id, patient_id, visit_type
FROM visits
WHERE visit_type IN ('Emergency', 'Urgent');

-- NOT IN — exclude values
SELECT visit_id, patient_id, department
FROM visits
WHERE department NOT IN ('Pediatrics', 'Orthopedics');


-- ── CONCEPT 4: Numeric comparisons ───────────────────────────

-- Greater than / less than
SELECT visit_id, patient_id, visit_cost
FROM visits
WHERE visit_cost > 300;

-- BETWEEN (inclusive on both ends)
SELECT visit_id, duration_minutes, visit_cost
FROM visits
WHERE duration_minutes BETWEEN 30 AND 60;

-- Combining numeric filters
SELECT visit_id, visit_cost, insurance_coverage, patient_payment
FROM visits
WHERE visit_cost > 200
  AND patient_payment < 100;


-- ── CONCEPT 5: NULL handling ──────────────────────────────────
-- NULL means "unknown/missing". Use IS NULL / IS NOT NULL, never = NULL.

-- Visits that have a scheduled follow-up date
SELECT visit_id, patient_id, follow_up_date
FROM visits
WHERE follow_up_date IS NOT NULL;

-- Visits with no follow-up scheduled
SELECT visit_id, patient_id, follow_up_required
FROM visits
WHERE follow_up_date IS NULL;

-- COALESCE: return first non-null value (great for fallback values)
SELECT
    visit_id,
    follow_up_date,
    COALESCE(follow_up_date, visit_date) AS effective_next_date
FROM visits;


-- ── CONCEPT 6: LIKE — pattern matching ───────────────────────
-- % matches any sequence; _ matches exactly one character.

-- Doctor names starting with "Dr. S"
SELECT DISTINCT doctor_name
FROM visits
WHERE doctor_name LIKE 'Dr. S%';

-- Diagnoses containing "infection"
SELECT visit_id, diagnosis
FROM visits
WHERE LOWER(diagnosis) LIKE '%infection%';


-- ── CONCEPT 7: ORDER BY ───────────────────────────────────────
-- Sort results. Default is ASC; use DESC for highest first.

-- Most expensive visits first
SELECT visit_id, department, visit_cost
FROM visits
ORDER BY visit_cost DESC;

-- Sort by department then by cost within each department
SELECT visit_id, department, visit_cost
FROM visits
ORDER BY department ASC, visit_cost DESC;


-- ── CONCEPT 8: LIMIT / TOP ────────────────────────────────────
-- Return only the first N rows. Useful for "Top N" questions.
-- BigQuery/PostgreSQL use LIMIT; SQL Server uses TOP.

-- Top 3 most expensive visits
SELECT visit_id, department, visit_cost
FROM visits
ORDER BY visit_cost DESC
LIMIT 3;


-- ── CONCEPT 9: DISTINCT ───────────────────────────────────────
-- Remove duplicate rows from results.

-- How many unique departments exist?
SELECT DISTINCT department
FROM visits
ORDER BY department;

-- Unique combinations of department + visit_type
SELECT DISTINCT department, visit_type
FROM visits
ORDER BY department, visit_type;


-- ── PRACTICE PROBLEMS ─────────────────────────────────────────
/*
  1. List all completed visits where the visit_cost is over $200.
     Show: visit_id, department, doctor_name, visit_cost.

  2. Find all patients with insurance from 'Blue Cross'.
     Show: patient_id, first_name, last_name, city, state.

  3. Retrieve the 5 longest visits (by duration_minutes).
     Show: visit_id, department, doctor_name, duration_minutes.

  4. Find all lab results where the result is abnormal AND no retest is required.
     (Assume column: is_abnormal = true, retest_required = false)

  5. List distinct blood types present in the patients table, sorted alphabetically.
*/

-- ANSWERS (try yourself first!) ─────────────────────────────
-- 1.
SELECT visit_id, department, doctor_name, visit_cost
FROM visits
WHERE visit_status = 'Completed'
  AND visit_cost > 200
ORDER BY visit_cost DESC;

-- 2.
SELECT patient_id, first_name, last_name, city, state
FROM patients
WHERE insurance_provider = 'Blue Cross';

-- 3.
SELECT visit_id, department, doctor_name, duration_minutes
FROM visits
ORDER BY duration_minutes DESC
LIMIT 5;

-- 4.
SELECT lab_result_id, patient_id, test_name, result_value
FROM lab_results
WHERE is_abnormal = true
  AND retest_required = false;

-- 5.
SELECT DISTINCT blood_type
FROM patients
ORDER BY blood_type;
