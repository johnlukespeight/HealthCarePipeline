-- ============================================================
-- MODULE 3: JOINs — INNER, LEFT, RIGHT, FULL, SELF, CROSS
-- Healthcare SQL Analytics Interview Prep
-- ============================================================
-- JOINs combine rows from two or more tables based on a related column.
-- This is among the most frequently tested topics in analytics interviews.
--
-- Mental model for JOIN types:
--   INNER JOIN  → only rows that match in BOTH tables
--   LEFT JOIN   → all rows from left table + matching rows from right (NULLs if no match)
--   RIGHT JOIN  → all rows from right table + matching rows from left (rarely used; flip tables instead)
--   FULL JOIN   → all rows from both tables (NULLs where no match on either side)
--   SELF JOIN   → joining a table to itself
-- ============================================================


-- ── CONCEPT 1: INNER JOIN ─────────────────────────────────────
-- Returns only rows with a match in both tables.
-- Use when you only care about records that exist in both tables.

-- Get patient name alongside their visits (only patients who have visited)
SELECT
    p.patient_id,
    p.first_name,
    p.last_name,
    v.visit_id,
    v.visit_date,
    v.department,
    v.visit_cost
FROM patients p
INNER JOIN visits v ON p.patient_id = v.patient_id
ORDER BY p.patient_id, v.visit_date;

-- Three-table join: patient + visit + lab result
SELECT
    p.first_name || ' ' || p.last_name     AS patient_name,
    v.department,
    v.visit_date,
    lr.test_name,
    lr.result_value,
    lr.is_abnormal
FROM patients p
INNER JOIN visits v      ON p.patient_id = v.patient_id
INNER JOIN lab_results lr ON v.visit_id  = lr.visit_id
ORDER BY p.patient_id, v.visit_date;


-- ── CONCEPT 2: LEFT JOIN ──────────────────────────────────────
-- Returns ALL rows from the LEFT table.
-- Right-table columns are NULL when there's no match.
-- Use for "find records that may or may not have related data".

-- All patients, with their visit counts (including patients who have never visited)
SELECT
    p.patient_id,
    p.first_name,
    p.last_name,
    COUNT(v.visit_id)   AS total_visits   -- counts non-NULL visit_ids
FROM patients p
LEFT JOIN visits v ON p.patient_id = v.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name
ORDER BY total_visits DESC;

-- Patients with NO visits (anti-join pattern using LEFT JOIN + IS NULL)
SELECT
    p.patient_id,
    p.first_name,
    p.last_name
FROM patients p
LEFT JOIN visits v ON p.patient_id = v.patient_id
WHERE v.visit_id IS NULL;  -- no matching visit row → patient never visited


-- ── CONCEPT 3: Finding unmatched rows (Anti-join) ─────────────
-- "Which patients have never had a lab result?"
-- Same pattern: LEFT JOIN + filter for NULL on the right side.

SELECT
    p.patient_id,
    p.first_name,
    p.last_name
FROM patients p
LEFT JOIN lab_results lr ON p.patient_id = lr.patient_id
WHERE lr.lab_result_id IS NULL;


-- ── CONCEPT 4: FULL OUTER JOIN ────────────────────────────────
-- Returns all rows from both tables. NULLs on either side when no match.
-- Useful for reconciliation — finding rows that exist in one table but not both.

SELECT
    COALESCE(p.patient_id, lr.patient_id)   AS patient_id,
    p.first_name,
    p.last_name,
    COUNT(lr.lab_result_id)                 AS lab_count
FROM patients p
FULL OUTER JOIN lab_results lr ON p.patient_id = lr.patient_id
GROUP BY COALESCE(p.patient_id, lr.patient_id), p.first_name, p.last_name;


-- ── CONCEPT 5: SELF JOIN ──────────────────────────────────────
-- Joining a table to itself. Classic use case: hierarchies, comparisons within same table.
-- Here: find pairs of patients in the same city (common in matching/dedup problems)

SELECT
    a.patient_id    AS patient_1,
    b.patient_id    AS patient_2,
    a.city
FROM patients a
JOIN patients b ON a.city = b.city
                AND a.patient_id < b.patient_id  -- avoid duplicates and self-pairs
ORDER BY a.city;


-- ── CONCEPT 6: JOIN with aggregation ──────────────────────────
-- Combine JOINs with GROUP BY for richer analytics.

-- Revenue breakdown by insurance provider
SELECT
    p.insurance_provider,
    COUNT(DISTINCT p.patient_id)        AS total_patients,
    COUNT(v.visit_id)                   AS total_visits,
    SUM(v.visit_cost)                   AS gross_revenue,
    SUM(v.insurance_coverage)           AS insurance_paid,
    SUM(v.patient_payment)              AS patient_paid,
    ROUND(AVG(v.visit_cost), 2)         AS avg_visit_cost
FROM patients p
LEFT JOIN visits v ON p.patient_id = v.patient_id
GROUP BY p.insurance_provider
ORDER BY gross_revenue DESC;

-- Department performance: visits + average abnormal lab rate
SELECT
    v.department,
    COUNT(DISTINCT v.visit_id)                                      AS total_visits,
    COUNT(DISTINCT lr.lab_result_id)                                AS total_lab_tests,
    COUNT(CASE WHEN lr.is_abnormal = true THEN 1 END)              AS abnormal_tests,
    ROUND(
        COUNT(CASE WHEN lr.is_abnormal = true THEN 1 END) * 100.0
        / NULLIF(COUNT(DISTINCT lr.lab_result_id), 0), 1
    )                                                               AS abnormal_pct
FROM visits v
LEFT JOIN lab_results lr ON v.visit_id = lr.visit_id
GROUP BY v.department
ORDER BY total_visits DESC;
-- Note: NULLIF(x, 0) prevents division-by-zero errors.


-- ── CONCEPT 7: JOIN pitfall — row multiplication ──────────────
-- If the right table has multiple rows per key, LEFT JOIN multiplies left rows.
-- Always check COUNT before and after JOINs during development.

-- WRONG: if a patient has 3 visits and 2 lab results per visit,
-- joining all three tables naively multiplies rows.
-- FIX: aggregate the child table first, then join.

-- Safe pattern: pre-aggregate lab results before joining
WITH lab_summary AS (
    SELECT
        patient_id,
        COUNT(*)                                            AS total_labs,
        COUNT(CASE WHEN is_abnormal = true THEN 1 END)     AS abnormal_labs
    FROM lab_results
    GROUP BY patient_id
)
SELECT
    p.patient_id,
    p.first_name,
    p.last_name,
    COALESCE(ls.total_labs, 0)      AS total_labs,
    COALESCE(ls.abnormal_labs, 0)   AS abnormal_labs
FROM patients p
LEFT JOIN lab_summary ls ON p.patient_id = ls.patient_id;


-- ── PRACTICE PROBLEMS ─────────────────────────────────────────
/*
  1. For each patient, show their full name, total visits, total spend
     (visit_cost), and total amount covered by insurance.
     Include patients with zero visits.

  2. Find all patients who have had an emergency visit but have NO
     abnormal lab results on record.

  3. List every visit along with the patient's age_group and insurance_provider.
     (Hint: join visits to stg_patients which has age_group.)

  4. For each doctor, show: doctor_name, departments they've worked in
     (comma-separated), total visits, and average visit duration.

  5. Identify patients whose total patient_payment (out-of-pocket) exceeds
     their total insurance_coverage across all visits.
*/

-- ANSWERS ────────────────────────────────────────────────────
-- 1.
SELECT
    p.patient_id,
    p.first_name || ' ' || p.last_name     AS full_name,
    COUNT(v.visit_id)                       AS total_visits,
    COALESCE(SUM(v.visit_cost), 0)          AS total_spend,
    COALESCE(SUM(v.insurance_coverage), 0)  AS insurance_covered
FROM patients p
LEFT JOIN visits v ON p.patient_id = v.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name
ORDER BY total_spend DESC;

-- 2.
SELECT DISTINCT
    p.patient_id,
    p.first_name,
    p.last_name
FROM patients p
INNER JOIN visits v     ON p.patient_id = v.patient_id
LEFT  JOIN lab_results lr ON p.patient_id = lr.patient_id AND lr.is_abnormal = true
WHERE v.visit_type = 'Emergency'
  AND lr.lab_result_id IS NULL;

-- 3.
SELECT
    v.visit_id,
    v.visit_date,
    v.department,
    v.visit_type,
    sp.first_name,
    sp.last_name,
    sp.age_group,
    sp.insurance_provider
FROM visits v
JOIN stg_patients sp ON v.patient_id = sp.patient_id
ORDER BY v.visit_date;

-- 4.
SELECT
    doctor_name,
    STRING_AGG(DISTINCT department, ', ' ORDER BY department)  AS departments,
    COUNT(*)                                                    AS total_visits,
    ROUND(AVG(duration_minutes), 1)                            AS avg_duration_min
FROM visits
GROUP BY doctor_name
ORDER BY total_visits DESC;

-- 5.
SELECT
    p.patient_id,
    p.first_name,
    p.last_name,
    SUM(v.patient_payment)      AS total_out_of_pocket,
    SUM(v.insurance_coverage)   AS total_insurance
FROM patients p
JOIN visits v ON p.patient_id = v.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name
HAVING SUM(v.patient_payment) > SUM(v.insurance_coverage)
ORDER BY total_out_of_pocket DESC;
