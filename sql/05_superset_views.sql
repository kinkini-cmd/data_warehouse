-- ============================================================
-- Apache Superset Views & Datasets
--
-- These views are optimized for Superset's Explore and
-- SQL Lab.  Import them as "Virtual Datasets" pointing at
-- the LMS warehouse connection.
-- ============================================================

-- ----------------------------------------------------------
-- Dimension snapshots (current state only)
-- ----------------------------------------------------------
CREATE OR REPLACE VIEW vw_current_students AS
SELECT student_sk, student_id, first_name, last_name, gender, dob, email, department_id
  FROM dim_students WHERE is_current = TRUE;

CREATE OR REPLACE VIEW vw_current_courses AS
SELECT course_sk, course_id, course_name, credits, department_id
  FROM dim_courses WHERE is_current = TRUE;

CREATE OR REPLACE VIEW vw_current_instructors AS
SELECT instructor_sk, instructor_id, instructor_name, department_id
  FROM dim_instructors WHERE is_current = TRUE;

-- ----------------------------------------------------------
-- Main fact view – denormalized for Superset charts
-- ----------------------------------------------------------
CREATE OR REPLACE VIEW vw_enrollment_fact AS
SELECT
    fe.enrollment_sk,
    fe.enrollment_id,
    ds.student_id,
    ds.first_name,
    ds.last_name,
    ds.gender,
    ds.department_id     AS student_department_id,
    dc.course_id,
    dc.course_name,
    dc.credits           AS course_credits,
    di.instructor_id,
    di.instructor_name,
    dd.date_sk,
    fe.enrollment_date,
    dd.year              AS enrollment_year,
    dd.month             AS enrollment_month,
    dd.quarter           AS enrollment_quarter,
    dd.day_name          AS enrollment_day,
    dd.is_weekend,
    dd.month_name        AS enrollment_month_name,
    fe.semester,
    fe.grade,
    fe.credits           AS enrollment_credits,
    fe.created_at
FROM fact_enrollments fe
JOIN dim_students ds ON fe.student_sk = ds.student_sk
JOIN dim_courses dc ON fe.course_sk = dc.course_sk
JOIN dim_instructors di ON fe.instructor_sk = di.instructor_sk
JOIN dim_date dd ON fe.date_sk = dd.date_sk;

-- ----------------------------------------------------------
-- Department summary – enrollment counts and averages
-- ----------------------------------------------------------
CREATE OR REPLACE VIEW vw_department_summary AS
SELECT
    dd.department_id,
    dd.department_name,
    COUNT(fe.enrollment_sk)                   AS total_enrollments,
    COUNT(DISTINCT fe.student_sk)             AS unique_students,
    COUNT(DISTINCT fe.course_sk)              AS unique_courses,
    ROUND(AVG(fe.credits)::NUMERIC, 2)        AS avg_credits,
    COUNT(CASE WHEN fe.grade IN ('A+', 'A', 'A-') THEN 1 END) AS grade_a_count,
    COUNT(CASE WHEN fe.grade IN ('B+', 'B', 'B-') THEN 1 END) AS grade_b_count,
    COUNT(CASE WHEN fe.grade IN ('C+', 'C', 'C-') THEN 1 END) AS grade_c_count
FROM fact_enrollments fe
JOIN dim_students ds ON fe.student_sk = ds.student_sk
JOIN dim_departments dd ON ds.department_id = dd.department_id
GROUP BY dd.department_id, dd.department_name
ORDER BY total_enrollments DESC;

-- ----------------------------------------------------------
-- Course performance – enrollment counts and grade stats
-- ----------------------------------------------------------
CREATE OR REPLACE VIEW vw_course_performance AS
SELECT
    dc.course_id,
    dc.course_name,
    dd.department_id     AS course_department_id,
    COUNT(fe.enrollment_sk)                   AS total_enrollments,
    COUNT(DISTINCT fe.student_sk)             AS unique_students,
    COUNT(DISTINCT fe.instructor_sk)          AS unique_instructors,
    ROUND(AVG(fe.credits)::NUMERIC, 2)        AS avg_credits,
    COUNT(CASE WHEN fe.grade IN ('A+', 'A', 'A-') THEN 1 END) AS grade_a_count,
    COUNT(CASE WHEN fe.grade IN ('B+', 'B', 'B-') THEN 1 END) AS grade_b_count,
    COUNT(CASE WHEN fe.grade IN ('C+', 'C', 'C-') THEN 1 END) AS grade_c_count,
    MIN(fe.enrollment_date)                   AS first_enrollment,
    MAX(fe.enrollment_date)                   AS last_enrollment
FROM fact_enrollments fe
JOIN dim_courses dc ON fe.course_sk = dc.course_sk
JOIN dim_departments dd ON dc.department_id = dd.department_id
GROUP BY dc.course_id, dc.course_name, dd.department_id
ORDER BY total_enrollments DESC;

-- ----------------------------------------------------------
-- Monthly enrollment trends
-- ----------------------------------------------------------
CREATE OR REPLACE VIEW vw_monthly_trends AS
SELECT
    dd.year,
    dd.month,
    dd.month_name,
    dd.quarter,
    COUNT(fe.enrollment_sk)                   AS total_enrollments,
    COUNT(DISTINCT fe.student_sk)             AS unique_students,
    COUNT(DISTINCT fe.course_sk)              AS unique_courses,
    ROUND(AVG(fe.credits)::NUMERIC, 2)        AS avg_credits
FROM fact_enrollments fe
JOIN dim_date dd ON fe.date_sk = dd.date_sk
GROUP BY dd.year, dd.month, dd.month_name, dd.quarter
ORDER BY dd.year, dd.month;

-- ----------------------------------------------------------
-- Instructor workload – enrollment counts and course variety
-- ----------------------------------------------------------
CREATE OR REPLACE VIEW vw_instructor_workload AS
SELECT
    di.instructor_id,
    di.instructor_name,
    dd.department_id     AS instructor_department_id,
    COUNT(fe.enrollment_sk)                   AS total_enrollments,
    COUNT(DISTINCT fe.course_sk)              AS unique_courses,
    COUNT(DISTINCT fe.student_sk)             AS unique_students,
    MIN(fe.enrollment_date)                   AS first_enrollment,
    MAX(fe.enrollment_date)                   AS last_enrollment
FROM fact_enrollments fe
JOIN dim_instructors di ON fe.instructor_sk = di.instructor_sk
JOIN dim_departments dd ON di.department_id = dd.department_id
GROUP BY di.instructor_id, di.instructor_name, dd.department_id
ORDER BY total_enrollments DESC;
