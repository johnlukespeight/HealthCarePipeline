-- ============================================================
-- MODULE 2: Aggregations — GROUP BY, HAVING, COUNT/SUM/AVG/MIN/MAX
-- Healthcare SQL Analytics Interview Prep
-- ============================================================
-- This is the #1 most tested area in analytics interviews.
-- Master the mental model: GROUP BY collapses many rows into one per group.
-- ============================================================


-- ── CONCEPT 1: Aggregate functions ───────────────────────────
-- COUNT, SUM, AVG, MIN, MAX operate on a set of rows.

-- Overall stats for all visits
SELECT
    COUNT(*)                        AS total_visits,
    COUNT(DISTINCT patient_id)      AS unique_patients,
    SUM(visit_cost)                 AS total_revenue,
    AVG(visit_cost)                 AS avg_visit_cost,
    MIN(visit_cost)                 AS cheapest_visit,
    MAX(visit_cost)                 AS most_expensive_visit,
    AVG(duration_minutes)           AS avg_duration_min
FROM visits;

-- COUNT(*) vs COUNT(column):
--   COUNT(*)           counts all rows including NULLs
--   COUNT(column)      counts only non-NULL values in that column
--   COUNT(DISTINCT x)  counts unique non-NULL values

SELECT
    COUNT(*)                        AS total_rows,
    COUNT(follow_up_date)           AS rows_with_followup_date,  -- excludes NULLs
    COUNT(DISTINCT patient_id)      AS unique_patients
FROM visits;


-- ── CONCEPT 2: GROUP BY ───────────────────────────────────────
-- Splits rows into groups; aggregate functions apply per group.
-- Rule: every column in SELECT must either be in GROUP BY or inside an aggregate.

-- Visit counts and revenue by department
SELECT
    department,
    COUNT(*)            AS total_visits,
    SUM(visit_cost)     AS total_revenue,
    AVG(visit_cost)     AS avg_cost,
    AVG(duration_minutes) AS avg_duration_min
FROM visits
GROUP BY department
ORDER BY total_revenue DESC;

-- Visits broken down by visit_type
SELECT
    visit_type,
    COUNT(*)                            AS visit_count,
    COUNT(DISTINCT patient_id)          AS unique_patients,
    ROUND(AVG(visit_cost), 2)           AS avg_cost
FROM visits
GROUP BY visit_type
ORDER BY visit_count DESC;

-- Two-level grouping: department + visit_type
SELECT
    department,
    visit_type,
    COUNT(*)        AS visit_count,
    SUM(visit_cost) AS revenue
FROM visits
GROUP BY department, visit_type
ORDER BY department, visit_count DESC;


-- ── CONCEPT 3: HAVING — filtering groups ─────────────────────
-- WHERE filters individual rows (before grouping).
-- HAVING filters aggregated groups (after grouping).

-- Departments with more than 1 visit
SELECT
    department,
    COUNT(*) AS visit_count
FROM visits
GROUP BY department
HAVING COUNT(*) > 1;

-- Departments where average visit cost exceeds $200
SELECT
    department,
    ROUND(AVG(visit_cost), 2) AS avg_cost
FROM visits
GROUP BY department
HAVING AVG(visit_cost) > 200
ORDER BY avg_cost DESC;

-- WHERE + HAVING together:
-- Only completed visits, grouped by department, showing departments with avg cost > $150
SELECT
    department,
    COUNT(*)                    AS completed_visits,
    ROUND(AVG(visit_cost), 2)  AS avg_cost
FROM visits
WHERE visit_status = 'Completed'   -- filters rows first
GROUP BY department
HAVING AVG(visit_cost) > 150        -- filters groups after aggregation
ORDER BY avg_cost DESC;


-- ── CONCEPT 4: Conditional aggregation (CASE inside COUNT/SUM) ─
-- Count or sum rows that meet a condition within a group.
-- This avoids multiple subqueries and is a key interview pattern.

SELECT
    department,
    COUNT(*)                                                        AS total_visits,
    -- Count only emergency visits
    COUNT(CASE WHEN visit_type = 'Emergency' THEN 1 END)           AS emergency_visits,
    -- Count visits requiring follow-up
    COUNT(CASE WHEN follow_up_required = true THEN 1 END)          AS followup_visits,
    -- Total cost for completed visits only
    SUM(CASE WHEN visit_status = 'Completed' THEN visit_cost END)  AS completed_revenue,
    -- % emergency (multiply by 1.0 to avoid integer division)
    ROUND(
        COUNT(CASE WHEN visit_type = 'Emergency' THEN 1 END) * 100.0
        / COUNT(*), 1
    )                                                               AS emergency_pct
FROM visits
GROUP BY department
ORDER BY total_visits DESC;


-- ── CONCEPT 5: ROLLUP / GROUPING SETS (advanced) ─────────────
-- Generate subtotals and grand totals in one query.
-- BigQuery supports ROLLUP and GROUPING SETS.

-- Department subtotals + grand total (ROLLUP)
SELECT
    COALESCE(department, 'ALL DEPARTMENTS') AS department,
    COUNT(*)                                AS total_visits,
    SUM(visit_cost)                         AS total_revenue
FROM visits
GROUP BY ROLLUP(department)
ORDER BY department NULLS LAST;


-- ── CONCEPT 6: Lab result aggregations ───────────────────────
-- Aggregating by test category to find abnormality rates

SELECT
    test_category,
    COUNT(*)                                                AS total_tests,
    COUNT(CASE WHEN is_abnormal = true THEN 1 END)         AS abnormal_count,
    ROUND(
        COUNT(CASE WHEN is_abnormal = true THEN 1 END) * 100.0 / COUNT(*), 1
    )                                                       AS abnormal_pct,
    ROUND(AVG(result_value), 2)                             AS avg_result_value
FROM lab_results
GROUP BY test_category
ORDER BY abnormal_pct DESC;


-- ── PRACTICE PROBLEMS ─────────────────────────────────────────
/*
  1. How many visits occurred per month? Show year-month and visit count,
     ordered by most recent month first.
     Hint: use DATE_TRUNC(visit_date, MONTH) in BigQuery, or
           DATE_FORMAT(visit_date, '%Y-%m') in MySQL.

  2. Which insurance provider has the highest total insurance coverage paid?
     Join visits to patients. Show: insurance_provider, total_coverage.

  3. Find all doctors who have seen more than 1 unique patient.
     Show: doctor_name, unique_patients, total_visits.

  4. What percentage of visits in each department resulted in a follow-up?
     Show: department, total_visits, followup_count, followup_pct.

  5. Which patients have had at least one abnormal lab result?
     Show: patient_id, total_tests, abnormal_tests. Order by abnormal_tests DESC.
*/

-- ANSWERS ────────────────────────────────────────────────────
-- 1.
SELECT
    DATE_TRUNC(visit_date, MONTH)   AS visit_month,
    COUNT(*)                        AS visit_count
FROM visits
GROUP BY visit_month
ORDER BY visit_month DESC;

-- 2.
SELECT
    p.insurance_provider,
    SUM(v.insurance_coverage)   AS total_coverage
FROM visits v
JOIN patients p ON v.patient_id = p.patient_id
GROUP BY p.insurance_provider
ORDER BY total_coverage DESC;

-- 3.
SELECT
    doctor_name,
    COUNT(DISTINCT patient_id)  AS unique_patients,
    COUNT(*)                    AS total_visits
FROM visits
GROUP BY doctor_name
HAVING COUNT(DISTINCT patient_id) > 1
ORDER BY unique_patients DESC;

-- 4.
SELECT
    department,
    COUNT(*)                                                AS total_visits,
    COUNT(CASE WHEN follow_up_required = true THEN 1 END)  AS followup_count,
    ROUND(
        COUNT(CASE WHEN follow_up_required = true THEN 1 END) * 100.0 / COUNT(*), 1
    )                                                       AS followup_pct
FROM visits
GROUP BY department
ORDER BY followup_pct DESC;

-- 5.
SELECT
    patient_id,
    COUNT(*)                                            AS total_tests,
    COUNT(CASE WHEN is_abnormal = true THEN 1 END)     AS abnormal_tests
FROM lab_results
GROUP BY patient_id
HAVING COUNT(CASE WHEN is_abnormal = true THEN 1 END) >= 1
ORDER BY abnormal_tests DESC;
