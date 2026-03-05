-- ============================================================
-- MODULE 4: Window Functions — The #1 Interview Differentiator
-- Healthcare SQL Analytics Interview Prep
-- ============================================================
-- Window functions compute values ACROSS a set of rows related to the
-- current row WITHOUT collapsing rows (unlike GROUP BY).
--
-- Syntax:
--   function() OVER (
--       PARTITION BY col1, col2   -- defines the "window" / group
--       ORDER BY col3 [ASC|DESC]  -- ordering within the window
--       ROWS/RANGE BETWEEN ...    -- optional frame clause
--   )
--
-- Key functions: ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD,
--                SUM/AVG/COUNT (as window), NTILE, FIRST_VALUE, LAST_VALUE
-- ============================================================


-- ── CONCEPT 1: ROW_NUMBER ─────────────────────────────────────
-- Assigns a unique sequential integer per row within a partition.
-- Useful for: deduplication, "most recent record per entity", pagination.

-- Number each visit per patient in chronological order
SELECT
    patient_id,
    visit_id,
    visit_date,
    department,
    visit_cost,
    ROW_NUMBER() OVER (
        PARTITION BY patient_id
        ORDER BY visit_date ASC
    ) AS visit_number
FROM visits;

-- Classic interview pattern: get MOST RECENT visit per patient
WITH ranked_visits AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY patient_id
            ORDER BY visit_date DESC
        ) AS rn
    FROM visits
)
SELECT
    patient_id,
    visit_id,
    visit_date,
    department,
    visit_cost
FROM ranked_visits
WHERE rn = 1;  -- keep only the latest visit per patient


-- ── CONCEPT 2: RANK vs DENSE_RANK ────────────────────────────
-- RANK:       ties get the same rank; next rank skips numbers (1,1,3,4)
-- DENSE_RANK: ties get the same rank; next rank does NOT skip  (1,1,2,3)

-- Rank departments by total revenue
SELECT
    department,
    SUM(visit_cost)                                     AS total_revenue,
    RANK()       OVER (ORDER BY SUM(visit_cost) DESC)  AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY SUM(visit_cost) DESC)  AS revenue_dense_rank
FROM visits
GROUP BY department;

-- Rank each patient's visits by cost (highest = rank 1)
SELECT
    patient_id,
    visit_id,
    visit_date,
    visit_cost,
    RANK() OVER (
        PARTITION BY patient_id
        ORDER BY visit_cost DESC
    ) AS cost_rank_within_patient
FROM visits;


-- ── CONCEPT 3: LAG and LEAD ───────────────────────────────────
-- LAG  → value from a PREVIOUS row in the window
-- LEAD → value from a NEXT row in the window
-- Both take: function(column, offset, default)
-- Critical for: day-over-day changes, churn detection, time between events.

-- For each visit, show the previous visit date and cost for that patient
SELECT
    patient_id,
    visit_id,
    visit_date,
    visit_cost,
    LAG(visit_date, 1)  OVER (PARTITION BY patient_id ORDER BY visit_date) AS prev_visit_date,
    LAG(visit_cost, 1)  OVER (PARTITION BY patient_id ORDER BY visit_date) AS prev_visit_cost
FROM visits;

-- Calculate days since last visit and cost change
SELECT
    patient_id,
    visit_id,
    visit_date,
    visit_cost,
    DATE_DIFF(
        visit_date,
        LAG(visit_date) OVER (PARTITION BY patient_id ORDER BY visit_date),
        DAY
    )                                                                       AS days_since_last_visit,
    visit_cost - LAG(visit_cost) OVER (PARTITION BY patient_id ORDER BY visit_date)
                                                                            AS cost_change
FROM visits;

-- LEAD: flag if a patient came back within 30 days (readmission signal)
SELECT
    patient_id,
    visit_id,
    visit_date,
    LEAD(visit_date) OVER (PARTITION BY patient_id ORDER BY visit_date) AS next_visit_date,
    CASE
        WHEN DATE_DIFF(
            LEAD(visit_date) OVER (PARTITION BY patient_id ORDER BY visit_date),
            visit_date, DAY
        ) <= 30 THEN true
        ELSE false
    END AS readmitted_within_30_days
FROM visits;


-- ── CONCEPT 4: Running totals and moving averages ─────────────
-- Use SUM/AVG as window functions with ORDER BY (and optional ROWS frame).

-- Running total of visit costs per patient over time
SELECT
    patient_id,
    visit_id,
    visit_date,
    visit_cost,
    SUM(visit_cost) OVER (
        PARTITION BY patient_id
        ORDER BY visit_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_cost
FROM visits;

-- Running count of visits per patient
SELECT
    patient_id,
    visit_id,
    visit_date,
    COUNT(*) OVER (
        PARTITION BY patient_id
        ORDER BY visit_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS visit_number   -- same as ROW_NUMBER in this case
FROM visits;

-- 3-visit rolling average visit cost per department
-- (frames: ROWS BETWEEN 2 PRECEDING AND CURRENT ROW = window of 3)
SELECT
    department,
    visit_id,
    visit_date,
    visit_cost,
    ROUND(
        AVG(visit_cost) OVER (
            PARTITION BY department
            ORDER BY visit_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS rolling_3_avg_cost
FROM visits;


-- ── CONCEPT 5: Partitioned aggregates (no GROUP BY collapse) ──
-- Compute group-level stats while keeping individual rows.
-- Great for "compare each row to its group average" questions.

-- Show each visit's cost vs. the department's average and total
SELECT
    visit_id,
    patient_id,
    department,
    visit_cost,
    ROUND(AVG(visit_cost) OVER (PARTITION BY department), 2)   AS dept_avg_cost,
    SUM(visit_cost)       OVER (PARTITION BY department)       AS dept_total_cost,
    visit_cost - AVG(visit_cost) OVER (PARTITION BY department) AS vs_dept_avg
FROM visits;

-- Percentage of total revenue per visit within its department
SELECT
    visit_id,
    department,
    visit_cost,
    ROUND(
        visit_cost * 100.0 / SUM(visit_cost) OVER (PARTITION BY department), 1
    ) AS pct_of_dept_revenue
FROM visits;


-- ── CONCEPT 6: NTILE — percentile buckets ────────────────────
-- Divide rows into N roughly equal buckets (1 = top bucket when using DESC).

-- Assign each visit to a cost quartile (4 buckets)
SELECT
    visit_id,
    patient_id,
    visit_cost,
    NTILE(4) OVER (ORDER BY visit_cost DESC) AS cost_quartile
FROM visits;
-- Quartile 1 = top 25% most expensive


-- ── CONCEPT 7: FIRST_VALUE / LAST_VALUE ──────────────────────
-- Return the first or last value in a window frame.

-- Show first visit department alongside each subsequent visit
SELECT
    patient_id,
    visit_id,
    visit_date,
    department,
    FIRST_VALUE(department) OVER (
        PARTITION BY patient_id
        ORDER BY visit_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS first_ever_department
FROM visits;


-- ── CONCEPT 8: Classic interview problems using windows ───────

-- Problem: "For each department, show the most expensive single visit
--           alongside all other visits in that department."
SELECT
    department,
    visit_id,
    visit_date,
    visit_cost,
    MAX(visit_cost) OVER (PARTITION BY department) AS dept_max_cost,
    CASE WHEN visit_cost = MAX(visit_cost) OVER (PARTITION BY department)
         THEN true ELSE false END                  AS is_most_expensive
FROM visits;

-- Problem: "Identify patients whose most recent visit was an Emergency."
WITH latest AS (
    SELECT
        patient_id,
        visit_type,
        ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY visit_date DESC) AS rn
    FROM visits
)
SELECT patient_id, visit_type AS last_visit_type
FROM latest
WHERE rn = 1 AND visit_type = 'Emergency';


-- ── PRACTICE PROBLEMS ─────────────────────────────────────────
/*
  1. Rank patients by total_visit_costs (highest first). Show ties using DENSE_RANK.

  2. For each lab result, show the patient's previous test date and whether
     the result went from normal to abnormal (flag: escalated = true/false).

  3. Compute a 2-visit rolling average of duration_minutes per department.

  4. Find the visit where each patient spent the most (rank 1 by cost per patient),
     and return those rows only.

  5. Calculate what percentage of each patient's total lifetime cost
     each individual visit represents.
*/

-- ANSWERS ────────────────────────────────────────────────────
-- 1.
SELECT
    patient_id,
    SUM(visit_cost)                                         AS total_cost,
    DENSE_RANK() OVER (ORDER BY SUM(visit_cost) DESC)      AS cost_rank
FROM visits
GROUP BY patient_id;

-- 2.
SELECT
    patient_id,
    lab_result_id,
    test_date,
    is_abnormal,
    LAG(test_date)    OVER (PARTITION BY patient_id ORDER BY test_date)  AS prev_test_date,
    LAG(is_abnormal)  OVER (PARTITION BY patient_id ORDER BY test_date)  AS prev_is_abnormal,
    CASE
        WHEN is_abnormal = true
         AND LAG(is_abnormal) OVER (PARTITION BY patient_id ORDER BY test_date) = false
        THEN true ELSE false
    END AS escalated
FROM lab_results;

-- 3.
SELECT
    department,
    visit_id,
    visit_date,
    duration_minutes,
    ROUND(
        AVG(duration_minutes) OVER (
            PARTITION BY department
            ORDER BY visit_date
            ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
        ), 1
    ) AS rolling_2_avg_duration
FROM visits;

-- 4.
WITH ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY patient_id ORDER BY visit_cost DESC) AS rk
    FROM visits
)
SELECT patient_id, visit_id, visit_date, department, visit_cost
FROM ranked
WHERE rk = 1;

-- 5.
SELECT
    patient_id,
    visit_id,
    visit_date,
    visit_cost,
    SUM(visit_cost) OVER (PARTITION BY patient_id)  AS patient_lifetime_cost,
    ROUND(
        visit_cost * 100.0 / SUM(visit_cost) OVER (PARTITION BY patient_id), 1
    )                                               AS pct_of_lifetime
FROM visits
ORDER BY patient_id, visit_date;
