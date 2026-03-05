-- ============================================================
-- MODULE 5: CTEs, Subqueries, and Query Structure
-- Healthcare SQL Analytics Interview Prep
-- ============================================================
-- CTEs (Common Table Expressions) and subqueries let you break complex
-- queries into readable, reusable steps.
--
-- CTE syntax:
--   WITH cte_name AS (
--       SELECT ...
--   )
--   SELECT * FROM cte_name;
--
-- When to use what:
--   Subquery  → simple inline filter or scalar lookup
--   CTE       → reuse the same result multiple times, multi-step logic
--   Temp table → very large intermediate results (performance)
-- ============================================================


-- ── CONCEPT 1: Inline subquery in WHERE ───────────────────────
-- Filter rows based on the result of another query.

-- Visits from patients in 'California'
SELECT visit_id, patient_id, department, visit_cost
FROM visits
WHERE patient_id IN (
    SELECT patient_id FROM patients WHERE state = 'CA'
);

-- Visits more expensive than the overall average visit cost
SELECT visit_id, department, visit_cost
FROM visits
WHERE visit_cost > (
    SELECT AVG(visit_cost) FROM visits
);


-- ── CONCEPT 2: Correlated subquery ───────────────────────────
-- A subquery that references the outer query row by row.
-- Powerful but can be slow on large tables — know the trade-off.

-- For each visit, show whether its cost is above the department average
SELECT
    v.visit_id,
    v.department,
    v.visit_cost,
    (SELECT ROUND(AVG(v2.visit_cost), 2)
     FROM visits v2
     WHERE v2.department = v.department) AS dept_avg_cost,
    CASE
        WHEN v.visit_cost > (
            SELECT AVG(v2.visit_cost)
            FROM visits v2
            WHERE v2.department = v.department
        ) THEN 'Above Average'
        ELSE 'Below/At Average'
    END AS vs_dept_avg
FROM visits v;

-- Preferred modern approach (window function — same result, faster):
SELECT
    visit_id,
    department,
    visit_cost,
    ROUND(AVG(visit_cost) OVER (PARTITION BY department), 2) AS dept_avg_cost,
    CASE
        WHEN visit_cost > AVG(visit_cost) OVER (PARTITION BY department)
        THEN 'Above Average'
        ELSE 'Below/At Average'
    END AS vs_dept_avg
FROM visits;


-- ── CONCEPT 3: CTE — basic single-step ───────────────────────
-- Name an intermediate result and reference it cleanly.

WITH emergency_visits AS (
    SELECT
        patient_id,
        COUNT(*) AS emergency_count,
        SUM(visit_cost) AS emergency_spend
    FROM visits
    WHERE visit_type = 'Emergency'
    GROUP BY patient_id
)
SELECT
    p.patient_id,
    p.first_name,
    p.last_name,
    p.insurance_provider,
    ev.emergency_count,
    ev.emergency_spend
FROM patients p
INNER JOIN emergency_visits ev ON p.patient_id = ev.patient_id
ORDER BY ev.emergency_spend DESC;


-- ── CONCEPT 4: CTE — multi-step pipeline ─────────────────────
-- Chain multiple CTEs for complex logic. Each can reference prior ones.
-- This mirrors the staging → mart pattern already in this repo!

WITH

-- Step 1: summarise visits per patient
visit_summary AS (
    SELECT
        patient_id,
        COUNT(*)                                                    AS total_visits,
        SUM(visit_cost)                                             AS total_spend,
        COUNT(CASE WHEN visit_type = 'Emergency' THEN 1 END)        AS emergency_visits,
        MAX(visit_date)                                             AS last_visit_date
    FROM visits
    GROUP BY patient_id
),

-- Step 2: summarise lab results per patient
lab_summary AS (
    SELECT
        patient_id,
        COUNT(*)                                                    AS total_labs,
        COUNT(CASE WHEN is_abnormal = true THEN 1 END)             AS abnormal_labs
    FROM lab_results
    GROUP BY patient_id
),

-- Step 3: combine with patient demographics
patient_profile AS (
    SELECT
        p.patient_id,
        p.first_name || ' ' || p.last_name     AS full_name,
        p.age_group,
        p.insurance_provider,
        COALESCE(vs.total_visits, 0)            AS total_visits,
        COALESCE(vs.total_spend, 0)             AS total_spend,
        COALESCE(vs.emergency_visits, 0)        AS emergency_visits,
        vs.last_visit_date,
        COALESCE(ls.total_labs, 0)              AS total_labs,
        COALESCE(ls.abnormal_labs, 0)           AS abnormal_labs
    FROM stg_patients p
    LEFT JOIN visit_summary vs  ON p.patient_id = vs.patient_id
    LEFT JOIN lab_summary ls    ON p.patient_id = ls.patient_id
)

-- Step 4: add risk classification
SELECT
    *,
    CASE
        WHEN emergency_visits >= 2 AND abnormal_labs >= 2  THEN 'High Risk'
        WHEN emergency_visits >= 1 OR  abnormal_labs >= 1  THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM patient_profile
ORDER BY emergency_visits DESC, abnormal_labs DESC;


-- ── CONCEPT 5: Recursive CTEs (advanced) ─────────────────────
-- For hierarchical data (org charts, referral chains).
-- Healthcare use case: follow-up chains (visit → follow-up visit → follow-up).

-- Example: expand a simple follow-up chain by patient
-- (Conceptual — requires a self-referential follow_up_visit_id column)

WITH RECURSIVE followup_chain AS (
    -- Anchor: first visits (no prior follow-up)
    SELECT
        visit_id,
        patient_id,
        visit_date,
        visit_type,
        follow_up_date,
        1 AS chain_depth
    FROM visits
    WHERE visit_type IN ('Emergency', 'Urgent')  -- starting conditions

    UNION ALL

    -- Recursive: next visit that is a follow-up within 30 days
    SELECT
        v.visit_id,
        v.patient_id,
        v.visit_date,
        v.visit_type,
        v.follow_up_date,
        fc.chain_depth + 1
    FROM visits v
    JOIN followup_chain fc
      ON v.patient_id = fc.patient_id
     AND v.visit_date = fc.follow_up_date
    WHERE fc.chain_depth < 5   -- prevent infinite loops
)
SELECT * FROM followup_chain ORDER BY patient_id, chain_depth;


-- ── CONCEPT 6: EXISTS vs IN ───────────────────────────────────
-- EXISTS is often faster than IN for large datasets because it short-circuits.

-- Patients who have at least one abnormal lab result (using EXISTS)
SELECT p.patient_id, p.first_name, p.last_name
FROM patients p
WHERE EXISTS (
    SELECT 1
    FROM lab_results lr
    WHERE lr.patient_id = p.patient_id
      AND lr.is_abnormal = true
);

-- Equivalent using IN:
SELECT patient_id, first_name, last_name
FROM patients
WHERE patient_id IN (
    SELECT patient_id FROM lab_results WHERE is_abnormal = true
);

-- Patients with NO abnormal results (NOT EXISTS anti-join)
SELECT p.patient_id, p.first_name, p.last_name
FROM patients p
WHERE NOT EXISTS (
    SELECT 1
    FROM lab_results lr
    WHERE lr.patient_id = p.patient_id
      AND lr.is_abnormal = true
);


-- ── PRACTICE PROBLEMS ─────────────────────────────────────────
/*
  1. Write a multi-step CTE that:
     a) calculates average visit duration per department
     b) classifies each department as 'Efficient' (<30 min), 'Standard' (30-60), 'Extended' (>60)
     c) returns the final classification table.

  2. Using a subquery, find all visits where the patient's age_group is 'Senior'.
     (Hint: age_group is in stg_patients.)

  3. Write a CTE to find the "most loyal" patient per department —
     the patient with the most visits in each department.

  4. Using EXISTS, find patients who have had both a Cardiology visit AND an abnormal lab result.

  5. Build a patient risk score using a multi-CTE approach:
     - Score +3 for each emergency visit
     - Score +2 for each abnormal lab
     - Score +1 for each follow-up visit
     Order by total risk score DESC.
*/

-- ANSWERS ────────────────────────────────────────────────────
-- 1.
WITH dept_durations AS (
    SELECT
        department,
        AVG(duration_minutes) AS avg_duration
    FROM visits
    GROUP BY department
)
SELECT
    department,
    ROUND(avg_duration, 1) AS avg_duration_min,
    CASE
        WHEN avg_duration < 30  THEN 'Efficient'
        WHEN avg_duration <= 60 THEN 'Standard'
        ELSE 'Extended'
    END AS efficiency_category
FROM dept_durations
ORDER BY avg_duration;

-- 2.
SELECT v.visit_id, v.patient_id, v.department, v.visit_date, v.visit_cost
FROM visits v
WHERE v.patient_id IN (
    SELECT patient_id FROM stg_patients WHERE age_group = 'Senior'
);

-- 3.
WITH visit_counts AS (
    SELECT
        department,
        patient_id,
        COUNT(*) AS visit_count,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY COUNT(*) DESC) AS rn
    FROM visits
    GROUP BY department, patient_id
)
SELECT
    vc.department,
    vc.patient_id,
    p.first_name,
    p.last_name,
    vc.visit_count
FROM visit_counts vc
JOIN patients p ON vc.patient_id = p.patient_id
WHERE vc.rn = 1;

-- 4.
SELECT DISTINCT p.patient_id, p.first_name, p.last_name
FROM patients p
WHERE EXISTS (
    SELECT 1 FROM visits v
    WHERE v.patient_id = p.patient_id
      AND v.department = 'Cardiology'
)
AND EXISTS (
    SELECT 1 FROM lab_results lr
    WHERE lr.patient_id = p.patient_id
      AND lr.is_abnormal = true
);

-- 5.
WITH scores AS (
    SELECT
        p.patient_id,
        SUM(
            CASE WHEN v.visit_type = 'Emergency' THEN 3
                 WHEN v.visit_type = 'Follow-up'  THEN 1
                 ELSE 0 END
        ) AS visit_score,
        SUM(CASE WHEN lr.is_abnormal = true THEN 2 ELSE 0 END) AS lab_score
    FROM patients p
    LEFT JOIN visits      v  ON p.patient_id = v.patient_id
    LEFT JOIN lab_results lr ON p.patient_id = lr.patient_id
    GROUP BY p.patient_id
)
SELECT
    patient_id,
    visit_score,
    lab_score,
    COALESCE(visit_score, 0) + COALESCE(lab_score, 0) AS total_risk_score
FROM scores
ORDER BY total_risk_score DESC;
