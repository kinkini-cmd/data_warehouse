-- ============================================================
-- Power BI Helper Views & Queries
-- Import these views directly into Power BI for reporting
-- ============================================================

-- View: Current dimension snapshot (only active rows)
CREATE OR REPLACE VIEW vw_current_students AS
SELECT student_sk, student_id, first_name, last_name, gender, dob, email, department_id
  FROM dim_students WHERE is_current = TRUE;

CREATE OR REPLACE VIEW vw_current_courses AS
SELECT course_sk, course_id, course_name, credits, department_id
  FROM dim_courses WHERE is_current = TRUE;

CREATE OR REPLACE VIEW vw_current_instructors AS
SELECT instructor_sk, instructor_id, instructor_name, department_id
  FROM dim_instructors WHERE is_current = TRUE;

-- View: Enrollment fact with denormalized dimension fields (ready for Power BI)
CREATE OR REPLACE VIEW vw_enrollment_fact AS
SELECT
    fe.enrollment_sk,
    fe.enrollment_id,
    ds.student_id,
    ds.first_name,
    ds.last_name,
    ds.gender,
    ds.department_id,
    dc.course_id,
    dc.course_name,
    dc.credits,
    di.instructor_id,
    di.instructor_name,
    fe.enrollment_date,
    fe.semester,
    fe.grade,
    fe.created_at
FROM fact_enrollments fe
JOIN dim_students ds ON fe.student_sk = ds.student_sk
JOIN dim_courses dc ON fe.course_sk = dc.course_sk
JOIN dim_instructors di ON fe.instructor_sk = di.instructor_sk;
