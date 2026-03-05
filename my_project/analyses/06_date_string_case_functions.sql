-- ============================================================
-- MODULE 6: Date Functions, String Functions, CASE, and NULLIF
-- Healthcare SQL Analytics Interview Prep
-- ============================================================
-- Dialect note: examples use BigQuery syntax.
-- MySQL/PostgreSQL alternatives are noted where they differ.
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- PART A: DATE & TIME FUNCTIONS
-- ════════════════════════════════════════════════════════════

-- ── DATE_DIFF: days between two dates ─────────────────────────
-- BigQuery:    DATE_DIFF(end_date, start_date, DAY)
-- PostgreSQL:  end_date - start_date  (returns integer days)
-- MySQL:       DATEDIFF(end_date, start_date)

SELECT
    visit_id,
    patient_id,
    visit_date,
    follow_up_date,
    DATE_DIFF(follow_up_date, visit_date, DAY)  AS days_until_followup
FROM visits
WHERE follow_up_date IS NOT NULL;


-- ── DATE_TRUNC: round down to a period ───────────────────────
-- Useful for grouping by month, quarter, year.
-- BigQuery:    DATE_TRUNC(date_col, MONTH|QUARTER|YEAR)
-- PostgreSQL:  DATE_TRUNC('month', date_col)
-- MySQL:       DATE_FORMAT(date_col, '%Y-%m-01')

-- Visits per month
SELECT
    DATE_TRUNC(visit_date, MONTH)   AS visit_month,
    COUNT(*)                        AS visit_count,
    SUM(visit_cost)                 AS monthly_revenue
FROM visits
GROUP BY visit_month
ORDER BY visit_month;

-- Revenue by quarter
SELECT
    DATE_TRUNC(visit_date, QUARTER) AS visit_quarter,
    SUM(visit_cost)                 AS quarterly_revenue
FROM visits
GROUP BY visit_quarter
ORDER BY visit_quarter;


-- ── EXTRACT: pull components from a date ─────────────────────
-- BigQuery:    EXTRACT(YEAR|MONTH|DAY|DAYOFWEEK FROM date_col)
-- PostgreSQL:  EXTRACT(year FROM date_col) or DATE_PART('year', date_col)
-- MySQL:       YEAR(date_col), MONTH(date_col), DAY(date_col)

SELECT
    visit_id,
    visit_date,
    EXTRACT(YEAR  FROM visit_date)  AS visit_year,
    EXTRACT(MONTH FROM visit_date)  AS visit_month_num,
    EXTRACT(DAY   FROM visit_date)  AS visit_day,
    -- Day of week: 1=Sunday … 7=Saturday in BigQuery
    EXTRACT(DAYOFWEEK FROM visit_date) AS day_of_week
FROM visits;

-- Which day-of-week has the most visits?
SELECT
    EXTRACT(DAYOFWEEK FROM visit_date)  AS day_of_week,
    COUNT(*)                            AS visit_count
FROM visits
GROUP BY day_of_week
ORDER BY visit_count DESC;


-- ── DATE_ADD / DATE_SUB ───────────────────────────────────────
-- BigQuery:    DATE_ADD(date, INTERVAL n DAY|MONTH|YEAR)
-- PostgreSQL:  date_col + INTERVAL '30 days'
-- MySQL:       DATE_ADD(date_col, INTERVAL 30 DAY)

-- Expected follow-up window: visit_date + 30 days
SELECT
    visit_id,
    visit_date,
    DATE_ADD(visit_date, INTERVAL 30 DAY)  AS expected_followup_by,
    follow_up_date,
    -- Was the follow-up late?
    CASE
        WHEN follow_up_date > DATE_ADD(visit_date, INTERVAL 30 DAY)
        THEN 'Late'
        WHEN follow_up_date IS NULL THEN 'Not Scheduled'
        ELSE 'On Time'
    END AS followup_timeliness
FROM visits;


-- ── CURRENT_DATE / TODAY ──────────────────────────────────────
-- BigQuery:    CURRENT_DATE()
-- PostgreSQL:  CURRENT_DATE
-- MySQL:       CURDATE()

-- Patients who haven't had a visit in the last 365 days
SELECT
    patient_id,
    MAX(visit_date) AS last_visit_date,
    DATE_DIFF(CURRENT_DATE(), MAX(visit_date), DAY) AS days_since_last_visit
FROM visits
GROUP BY patient_id
HAVING DATE_DIFF(CURRENT_DATE(), MAX(visit_date), DAY) > 365;

-- Patient age from date_of_birth
SELECT
    patient_id,
    date_of_birth,
    DATE_DIFF(CURRENT_DATE(), date_of_birth, YEAR)  AS age_years
FROM patients;


-- ── FORMAT_DATE: display dates as strings ────────────────────
-- BigQuery:    FORMAT_DATE('%B %Y', date_col)  → "January 2024"
-- PostgreSQL:  TO_CHAR(date_col, 'Month YYYY')
-- MySQL:       DATE_FORMAT(date_col, '%M %Y')

SELECT
    visit_id,
    visit_date,
    FORMAT_DATE('%B %Y', visit_date)    AS visit_month_label,
    FORMAT_DATE('%Y-Q%Q', visit_date)   AS quarter_label   -- BigQuery-specific
FROM visits;


-- ════════════════════════════════════════════════════════════
-- PART B: STRING FUNCTIONS
-- ════════════════════════════════════════════════════════════

-- ── Concatenation ─────────────────────────────────────────────
-- BigQuery/PostgreSQL: || operator or CONCAT()
-- MySQL: CONCAT() only (|| is OR)

SELECT
    patient_id,
    CONCAT(first_name, ' ', last_name)     AS full_name,
    first_name || ' ' || last_name         AS full_name_alt
FROM patients;


-- ── UPPER / LOWER / INITCAP ───────────────────────────────────
SELECT
    UPPER(first_name)   AS name_upper,
    LOWER(email)        AS email_lower,
    INITCAP(city)       AS city_title_case   -- BigQuery supports INITCAP
FROM patients;


-- ── LENGTH / LEN ─────────────────────────────────────────────
SELECT
    patient_id,
    first_name,
    LENGTH(first_name)  AS name_length
FROM patients
ORDER BY name_length DESC;


-- ── TRIM / LTRIM / RTRIM ─────────────────────────────────────
-- Remove whitespace (or specific characters) from ends of strings.
SELECT TRIM('  hello world  ')   AS trimmed;  -- 'hello world'


-- ── SUBSTR / SUBSTRING ───────────────────────────────────────
-- Extract part of a string. SUBSTR(string, start_position, length)
SELECT
    diagnosis_code,
    SUBSTR(diagnosis_code, 1, 1)    AS icd_chapter   -- first character of ICD-10
FROM visits;

-- ICD-10 code category counts
SELECT
    SUBSTR(diagnosis_code, 1, 1)    AS icd_chapter,
    COUNT(*)                        AS visit_count
FROM visits
GROUP BY icd_chapter;


-- ── REPLACE ───────────────────────────────────────────────────
SELECT
    phone,
    REPLACE(REPLACE(REPLACE(phone, '(', ''), ')', ''), '-', '') AS clean_phone
FROM patients;


-- ── SPLIT / SPLIT_PART ────────────────────────────────────────
-- BigQuery:    SPLIT(string, delimiter)[OFFSET(n)]
-- PostgreSQL:  SPLIT_PART(string, delimiter, n)
-- MySQL:       SUBSTRING_INDEX(string, delimiter, n)

-- Extract first word of chief_complaint
SELECT
    visit_id,
    chief_complaint,
    SPLIT(chief_complaint, ' ')[OFFSET(0)] AS first_word   -- BigQuery syntax
FROM visits;


-- ── REGEXP ────────────────────────────────────────────────────
-- Test against a regular expression pattern.
-- BigQuery:    REGEXP_CONTAINS(string, pattern)

-- Validate email format: contains @ and a dot after @
SELECT
    patient_id,
    email,
    REGEXP_CONTAINS(email, r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') AS is_valid_email
FROM patients;


-- ════════════════════════════════════════════════════════════
-- PART C: CASE WHEN — conditional logic
-- ════════════════════════════════════════════════════════════

-- ── Searched CASE (most common) ───────────────────────────────
SELECT
    visit_id,
    visit_cost,
    CASE
        WHEN visit_cost < 100               THEN 'Low'
        WHEN visit_cost BETWEEN 100 AND 300 THEN 'Medium'
        WHEN visit_cost > 300               THEN 'High'
        ELSE 'Unknown'
    END AS cost_tier
FROM visits;

-- ── Simple CASE (equality checks only) ───────────────────────
SELECT
    visit_id,
    visit_type,
    CASE visit_type
        WHEN 'Emergency'  THEN 'Urgent Care'
        WHEN 'Urgent'     THEN 'Urgent Care'
        WHEN 'Routine'    THEN 'Scheduled Care'
        WHEN 'Follow-up'  THEN 'Scheduled Care'
        ELSE 'Other'
    END AS care_category
FROM visits;

-- ── CASE inside aggregation ───────────────────────────────────
-- (Reviewed in Module 2 — here for completeness)
SELECT
    department,
    COUNT(*)                                                    AS total,
    SUM(CASE WHEN visit_cost > 300 THEN 1 ELSE 0 END)          AS high_cost_visits,
    SUM(CASE WHEN visit_type = 'Emergency' THEN visit_cost END) AS emergency_revenue
FROM visits
GROUP BY department;


-- ════════════════════════════════════════════════════════════
-- PART D: NULL-safe functions
-- ════════════════════════════════════════════════════════════

-- COALESCE: returns first non-NULL value
SELECT
    visit_id,
    follow_up_date,
    COALESCE(follow_up_date, DATE_ADD(visit_date, INTERVAL 90 DAY)) AS effective_next_touchpoint
FROM visits;

-- NULLIF: returns NULL if two values are equal; useful to avoid division by zero
SELECT
    department,
    SUM(visit_cost)                                        AS total_cost,
    COUNT(*)                                               AS visit_count,
    SUM(visit_cost) / NULLIF(COUNT(*), 0)                 AS safe_avg_cost
FROM visits
GROUP BY department;

-- IFNULL (MySQL) / ISNULL (SQL Server) — single-argument COALESCE alternative
-- BigQuery equivalent: IFNULL(value, replace_with)
SELECT
    patient_id,
    IFNULL(follow_up_date, DATE '9999-12-31') AS next_visit_placeholder
FROM visits;


-- ── PRACTICE PROBLEMS ─────────────────────────────────────────
/*
  1. For each visit, add a column showing the visit month as 'Jan 2024',
     'Feb 2024', etc.

  2. Classify patients by age into risk tiers using CASE:
     - 'Low Risk'    : age < 40
     - 'Medium Risk' : age 40–64
     - 'High Risk'   : age 65+
     Calculate the count and avg visit cost per tier (join with visits).

  3. Find all patients whose email address does NOT contain '@'.
     (Data quality check.)

  4. Show each visit and a clean doctor first name (extract from
     "Dr. FirstName LastName" format — remove "Dr. " prefix).

  5. For each month, calculate the running total revenue since the
     start of the dataset (combine DATE_TRUNC + window SUM).
*/

-- ANSWERS ────────────────────────────────────────────────────
-- 1.
SELECT
    visit_id,
    visit_date,
    FORMAT_DATE('%b %Y', visit_date) AS visit_month_label
FROM visits;

-- 2.
SELECT
    CASE
        WHEN DATE_DIFF(CURRENT_DATE(), p.date_of_birth, YEAR) < 40  THEN 'Low Risk'
        WHEN DATE_DIFF(CURRENT_DATE(), p.date_of_birth, YEAR) <= 64 THEN 'Medium Risk'
        ELSE 'High Risk'
    END                             AS risk_tier,
    COUNT(DISTINCT p.patient_id)    AS patient_count,
    ROUND(AVG(v.visit_cost), 2)    AS avg_visit_cost
FROM patients p
LEFT JOIN visits v ON p.patient_id = v.patient_id
GROUP BY risk_tier;

-- 3.
SELECT patient_id, email
FROM patients
WHERE NOT REGEXP_CONTAINS(IFNULL(email, ''), r'@');

-- 4.
SELECT
    visit_id,
    doctor_name,
    TRIM(SUBSTR(doctor_name, STRPOS(doctor_name, ' ') + 1)) AS doctor_name_no_prefix
FROM visits;

-- 5.
SELECT
    visit_month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (ORDER BY visit_month) AS running_total_revenue
FROM (
    SELECT
        DATE_TRUNC(visit_date, MONTH) AS visit_month,
        SUM(visit_cost)               AS monthly_revenue
    FROM visits
    GROUP BY visit_month
)
ORDER BY visit_month;
