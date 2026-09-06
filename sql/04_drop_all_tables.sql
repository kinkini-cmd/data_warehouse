-- ============================================================
-- Drop ALL tables (staging + warehouse) for a clean re-run
-- ============================================================

DROP TABLE IF EXISTS fact_enrollments;
DROP TABLE IF EXISTS dim_date;
DROP TABLE IF EXISTS dim_students;
DROP TABLE IF EXISTS dim_instructors;
DROP TABLE IF EXISTS dim_courses;
DROP TABLE IF EXISTS dim_departments;
DROP TABLE IF EXISTS stg_enrollments;
DROP TABLE IF EXISTS stg_students;
DROP TABLE IF EXISTS stg_instructors;
DROP TABLE IF EXISTS stg_courses;
DROP TABLE IF EXISTS stg_departments;

-- Reset serial sequences
DROP SEQUENCE IF EXISTS dim_departments_department_sk_seq CASCADE;
DROP SEQUENCE IF EXISTS dim_courses_course_sk_seq CASCADE;
DROP SEQUENCE IF EXISTS dim_instructors_instructor_sk_seq CASCADE;
DROP SEQUENCE IF EXISTS dim_students_student_sk_seq CASCADE;
DROP SEQUENCE IF EXISTS fact_enrollments_enrollment_sk_seq CASCADE;
