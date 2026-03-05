-- ============================================================
-- MODULE 7: Advanced Analytics Patterns for Interviews
-- Healthcare SQL Analytics Interview Prep
-- ============================================================
-- These are the hardest, most-asked patterns at top tech and
-- healthcare companies (Google, Airbnb, Amazon, Epic, etc.).
-- Master these and you'll stand out in every analytics interview.
-- ============================================================


-- ══════════════════════════════════════════════════════════════
-- PATTERN 1: Retention / Cohort Analysis
-- ══════════════════════════════════════════════════════════════
-- "What % of patients who first visited in month X returned in month X+1, X+2, ...?"
-- Classic product analytics question translated to healthcare.

WITH first_visits AS (
    -- Cohort: the month each patient first appeared
    SELECT
        patient_id,
        DATE_TRUNC(MIN(visit_date), MONTH) AS cohort_month
    FROM visits
    GROUP BY patient_id
),

monthly_activity AS (
    -- Every month a patient was active
    SELECT DISTINCT
        patient_id,
        DATE_TRUNC(visit_date, MONTH) AS activity_month
    FROM visits
)

SELECT
    fv.cohort_month,
    DATE_DIFF(ma.activity_month, fv.cohort_month, MONTH)    AS months_after_cohort,
    COUNT(DISTINCT ma.patient_id)                            AS active_patients,
    COUNT(DISTINCT fv.patient_id)                            AS cohort_size,
    ROUND(
        COUNT(DISTINCT ma.patient_id) * 100.0
        / COUNT(DISTINCT fv.patient_id), 1
    )                                                        AS retention_pct
FROM first_visits fv
JOIN monthly_activity ma ON fv.patient_id = ma.patient_id
GROUP BY fv.cohort_month, months_after_cohort
ORDER BY fv.cohort_month, months_after_cohort;


-- ══════════════════════════════════════════════════════════════
-- PATTERN 2: Deduplication — keep latest record per entity
-- ══════════════════════════════════════════════════════════════
-- Extremely common in data pipelines. Two main approaches:

-- Approach A: ROW_NUMBER (most flexible)
WITH deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY patient_id
            ORDER BY visit_date DESC, visit_id DESC  -- tiebreak with visit_id
        ) AS rn
    FROM visits
)
SELECT * FROM deduped WHERE rn = 1;

-- Approach B: Self-join (less readable but portable)
SELECT v.*
FROM visits v
INNER JOIN (
    SELECT patient_id, MAX(visit_date) AS max_date
    FROM visits
    GROUP BY patient_id
) latest ON v.patient_id = latest.patient_id
         AND v.visit_date = latest.max_date;


-- ══════════════════════════════════════════════════════════════
-- PATTERN 3: Gap and Island Analysis
-- ══════════════════════════════════════════════════════════════
-- Find consecutive streaks or gaps in sequential events.
-- Example: identify "care gaps" — patients who went > 90 days without a visit.

WITH visit_gaps AS (
    SELECT
        patient_id,
        visit_id,
        visit_date,
        LAG(visit_date) OVER (PARTITION BY patient_id ORDER BY visit_date) AS prev_visit_date,
        DATE_DIFF(
            visit_date,
            LAG(visit_date) OVER (PARTITION BY patient_id ORDER BY visit_date),
            DAY
        ) AS days_gap
    FROM visits
)
SELECT
    patient_id,
    prev_visit_date         AS gap_start,
    visit_date              AS gap_end,
    days_gap
FROM visit_gaps
WHERE days_gap > 90
ORDER BY days_gap DESC;


-- ══════════════════════════════════════════════════════════════
-- PATTERN 4: Funnel Analysis
-- ══════════════════════════════════════════════════════════════
-- Track patients through a care pathway:
-- Step 1: Initial visit → Step 2: Follow-up scheduled → Step 3: Follow-up completed

WITH funnel AS (
    SELECT
        COUNT(DISTINCT patient_id)                                      AS step1_all_patients,
        COUNT(DISTINCT CASE WHEN follow_up_required = true
                            THEN patient_id END)                        AS step2_followup_required,
        COUNT(DISTINCT CASE WHEN follow_up_required = true
                             AND follow_up_date IS NOT NULL
                            THEN patient_id END)                        AS step3_followup_scheduled,
        COUNT(DISTINCT CASE WHEN follow_up_required = true
                             AND follow_up_date IS NOT NULL
                             AND visit_status = 'Completed'
                            THEN patient_id END)                        AS step4_completed
    FROM visits
)
SELECT
    step1_all_patients,
    step2_followup_required,
    ROUND(step2_followup_required * 100.0 / step1_all_patients, 1) AS step2_pct,
    step3_followup_scheduled,
    ROUND(step3_followup_scheduled * 100.0 / step1_all_patients, 1) AS step3_pct,
    step4_completed,
    ROUND(step4_completed * 100.0 / step1_all_patients, 1) AS step4_pct
FROM funnel;


-- ══════════════════════════════════════════════════════════════
-- PATTERN 5: Percentiles and Distribution Analysis
-- ══════════════════════════════════════════════════════════════

-- Approximate percentiles using PERCENTILE_CONT (exact, but slow on large data)
SELECT
    PERCENTILE_CONT(visit_cost, 0.25) OVER ()   AS p25,
    PERCENTILE_CONT(visit_cost, 0.50) OVER ()   AS median,
    PERCENTILE_CONT(visit_cost, 0.75) OVER ()   AS p75,
    PERCENTILE_CONT(visit_cost, 0.90) OVER ()   AS p90,
    PERCENTILE_CONT(visit_cost, 0.95) OVER ()   AS p95
FROM visits
LIMIT 1;   -- since these are window funcs over all rows, we just need one row

-- APPROX_QUANTILES (BigQuery — fast and scalable)
SELECT
    APPROX_QUANTILES(visit_cost, 100)[OFFSET(25)] AS p25,
    APPROX_QUANTILES(visit_cost, 100)[OFFSET(50)] AS median,
    APPROX_QUANTILES(visit_cost, 100)[OFFSET(75)] AS p75,
    APPROX_QUANTILES(visit_cost, 100)[OFFSET(90)] AS p90
FROM visits;

-- Distribution of visit costs in $100 buckets
SELECT
    FLOOR(visit_cost / 100) * 100   AS cost_bucket_start,
    COUNT(*)                        AS visit_count,
    RPAD('', COUNT(*), '▓')         AS bar_chart   -- ASCII bar chart!
FROM visits
GROUP BY cost_bucket_start
ORDER BY cost_bucket_start;


-- ══════════════════════════════════════════════════════════════
-- PATTERN 6: Year-over-Year / Period Comparisons
-- ══════════════════════════════════════════════════════════════

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC(visit_date, MONTH)   AS month,
        SUM(visit_cost)                 AS revenue
    FROM visits
    GROUP BY month
)
SELECT
    cur.month,
    cur.revenue                         AS current_revenue,
    prev.revenue                        AS prior_year_revenue,
    cur.revenue - prev.revenue          AS yoy_change,
    ROUND(
        (cur.revenue - prev.revenue) * 100.0 / NULLIF(prev.revenue, 0), 1
    )                                   AS yoy_pct_change
FROM monthly_revenue cur
LEFT JOIN monthly_revenue prev
    ON cur.month = DATE_ADD(prev.month, INTERVAL 12 MONTH);

-- Same result using LAG with an offset of 12 months:
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC(visit_date, MONTH) AS month,
        SUM(visit_cost)               AS revenue
    FROM visits
    GROUP BY month
)
SELECT
    month,
    revenue,
    LAG(revenue, 12) OVER (ORDER BY month) AS prior_year_revenue,
    ROUND(
        (revenue - LAG(revenue, 12) OVER (ORDER BY month)) * 100.0
        / NULLIF(LAG(revenue, 12) OVER (ORDER BY month), 0), 1
    ) AS yoy_pct_change
FROM monthly_revenue;


-- ══════════════════════════════════════════════════════════════
-- PATTERN 7: Sessionization / Event Grouping
-- ══════════════════════════════════════════════════════════════
-- Group events into "sessions" — visits within 30 days of each other.
-- Key insight: a new session starts whenever the gap from prior event exceeds threshold.

WITH visit_with_gaps AS (
    SELECT
        patient_id,
        visit_id,
        visit_date,
        DATE_DIFF(
            visit_date,
            LAG(visit_date) OVER (PARTITION BY patient_id ORDER BY visit_date),
            DAY
        ) AS days_since_prev
    FROM visits
),

session_flags AS (
    SELECT
        patient_id,
        visit_id,
        visit_date,
        days_since_prev,
        -- New session if first visit OR gap > 30 days
        CASE WHEN days_since_prev IS NULL OR days_since_prev > 30
             THEN 1 ELSE 0 END AS new_session_flag
    FROM visit_with_gaps
),

sessions AS (
    SELECT
        patient_id,
        visit_id,
        visit_date,
        -- Cumulative sum of new_session_flag = session ID
        SUM(new_session_flag) OVER (
            PARTITION BY patient_id
            ORDER BY visit_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS session_id
    FROM session_flags
)

SELECT
    patient_id,
    session_id,
    MIN(visit_date)                 AS session_start,
    MAX(visit_date)                 AS session_end,
    COUNT(*)                        AS visits_in_session,
    DATE_DIFF(MAX(visit_date), MIN(visit_date), DAY) AS session_duration_days
FROM sessions
GROUP BY patient_id, session_id
ORDER BY patient_id, session_id;


-- ══════════════════════════════════════════════════════════════
-- PATTERN 8: Pivoting data (PIVOT / conditional aggregation)
-- ══════════════════════════════════════════════════════════════
-- Transform rows into columns. In most SQL dialects use conditional aggregation.

-- Pivot: visit counts per department across visit types
SELECT
    department,
    COUNT(CASE WHEN visit_type = 'Routine'    THEN 1 END) AS routine_visits,
    COUNT(CASE WHEN visit_type = 'Emergency'  THEN 1 END) AS emergency_visits,
    COUNT(CASE WHEN visit_type = 'Follow-up'  THEN 1 END) AS followup_visits,
    COUNT(CASE WHEN visit_type = 'Urgent'     THEN 1 END) AS urgent_visits,
    COUNT(*)                                              AS total_visits
FROM visits
GROUP BY department
ORDER BY total_visits DESC;


-- ══════════════════════════════════════════════════════════════
-- PATTERN 9: Handling slowly changing dimensions (SCD Type 2 concept)
-- ══════════════════════════════════════════════════════════════
-- "What was the patient's insurance at the time of each visit?"
-- This requires point-in-time joins when insurance changes over time.

-- Simplified: get the insurance on record for each visit date
-- (If patients table stores current insurance only, we join on patient_id.
--  For true SCD2, you'd have effective_from / effective_to dates.)

WITH insurance_history AS (
    -- Hypothetical table with insurance changes over time
    SELECT
        patient_id,
        insurance_provider,
        DATE '2023-01-01'   AS effective_from,
        DATE '2024-06-30'   AS effective_to
    UNION ALL
    SELECT patient_id, 'New Insurer', DATE '2024-07-01', DATE '9999-12-31'
    FROM patients
    LIMIT 1   -- demo only
)
SELECT
    v.visit_id,
    v.patient_id,
    v.visit_date,
    ih.insurance_provider AS insurance_at_time_of_visit
FROM visits v
JOIN insurance_history ih
    ON v.patient_id = ih.patient_id
   AND v.visit_date BETWEEN ih.effective_from AND ih.effective_to;


-- ══════════════════════════════════════════════════════════════
-- PATTERN 10: The "Hardest" Interview Question Template
-- ══════════════════════════════════════════════════════════════
-- "For each month, show the top 3 departments by revenue,
--  along with their rank and % of that month's total revenue."

WITH monthly_dept_revenue AS (
    SELECT
        DATE_TRUNC(visit_date, MONTH)   AS month,
        department,
        SUM(visit_cost)                 AS revenue
    FROM visits
    GROUP BY month, department
),

ranked AS (
    SELECT
        month,
        department,
        revenue,
        SUM(revenue) OVER (PARTITION BY month)                  AS month_total,
        RANK() OVER (PARTITION BY month ORDER BY revenue DESC)  AS revenue_rank
    FROM monthly_dept_revenue
)

SELECT
    month,
    revenue_rank,
    department,
    revenue,
    ROUND(revenue * 100.0 / month_total, 1) AS pct_of_month_revenue
FROM ranked
WHERE revenue_rank <= 3
ORDER BY month, revenue_rank;


-- ── FINAL INTERVIEW TIPS ──────────────────────────────────────
/*
  BEFORE writing any query:
  1. Clarify the grain: what is one row in the output?
  2. Identify the tables and joins needed.
  3. Think about NULLs and edge cases.
  4. Write it step by step — CTEs first, then assemble.

  COMMON GOTCHAS to mention aloud:
  - NULL in aggregates (COUNT vs COUNT(*), SUM ignores NULLs)
  - Division by zero → use NULLIF(denominator, 0)
  - Duplicate rows from joins → pre-aggregate or use DISTINCT
  - INT division truncation → cast to FLOAT: x * 1.0 / y
  - HAVING vs WHERE: WHERE before GROUP, HAVING after
  - Window functions execute AFTER WHERE/GROUP/HAVING but BEFORE ORDER/LIMIT

  OPTIMIZATION talking points:
  - Partition tables by date column (done in this repo!)
  - Cluster by frequently filtered columns (patient_id, department)
  - Avoid SELECT * in production — specify columns
  - Push filters as early as possible in CTEs
  - APPROX functions for non-exact analytics at scale
*/
