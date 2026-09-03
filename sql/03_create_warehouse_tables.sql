-- ============================================================
-- Star-Schema Warehouse Tables
-- Dimension tables use SCD Type 2 (where attributes change over
-- time) or SCD Type 1 (reference data).  The fact table records
-- enrollment events.
-- ============================================================

DROP TABLE IF EXISTS fact_enrollments;
DROP TABLE IF EXISTS dim_students;
DROP TABLE IF EXISTS dim_instructors;
DROP TABLE IF EXISTS dim_courses;
DROP TABLE IF EXISTS dim_departments;

-- ----------------------------------------------------------
-- dim_departments  – SCD Type 1 (reference / master data)
-- ----------------------------------------------------------
CREATE TABLE dim_departments (
    department_sk   SERIAL PRIMARY KEY,
    department_id   VARCHAR(50)  NOT NULL,
    department_name VARCHAR(100) NOT NULL,
    is_active       BOOLEAN      DEFAULT TRUE,
    created_at      TIMESTAMP    DEFAULT NOW(),
    updated_at      TIMESTAMP    DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_dim_departments_id  ON dim_departments(department_id);
CREATE INDEX idx_dim_departments_active    ON dim_departments(is_active);

-- ----------------------------------------------------------
-- dim_courses  – SCD Type 2
-- Tracks changes to course name / credits / department.
-- ----------------------------------------------------------
CREATE TABLE dim_courses (
    course_sk       SERIAL PRIMARY KEY,
    course_id       VARCHAR(50)  NOT NULL,
    course_name     VARCHAR(200) NOT NULL,
    credits         INTEGER,
    department_id   VARCHAR(50),
    effective_date  DATE         NOT NULL,
    expiry_date     DATE,
    is_current      BOOLEAN      DEFAULT TRUE,
    is_active       BOOLEAN      DEFAULT TRUE,
    created_at      TIMESTAMP    DEFAULT NOW(),
    updated_at      TIMESTAMP    DEFAULT NOW()
);

CREATE INDEX idx_dim_courses_id        ON dim_courses(course_id);
CREATE INDEX idx_dim_courses_current   ON dim_courses(course_id, is_current) WHERE is_current;

-- ----------------------------------------------------------
-- dim_instructors  – SCD Type 2
-- Tracks changes to instructor name / department.
-- ----------------------------------------------------------
CREATE TABLE dim_instructors (
    instructor_sk   SERIAL PRIMARY KEY,
    instructor_id   VARCHAR(50)  NOT NULL,
    instructor_name VARCHAR(200) NOT NULL,
    department_id   VARCHAR(50),
    effective_date  DATE         NOT NULL,
    expiry_date     DATE,
    is_current      BOOLEAN      DEFAULT TRUE,
    is_active       BOOLEAN      DEFAULT TRUE,
    created_at      TIMESTAMP    DEFAULT NOW(),
    updated_at      TIMESTAMP    DEFAULT NOW()
);

CREATE INDEX idx_dim_instructors_id     ON dim_instructors(instructor_id);
CREATE INDEX idx_dim_instructors_curr   ON dim_instructors(instructor_id, is_current) WHERE is_current;

-- ----------------------------------------------------------
-- dim_students  – SCD Type 2
-- Tracks changes to student attributes (name, email, dept).
-- ----------------------------------------------------------
CREATE TABLE dim_students (
    student_sk      SERIAL PRIMARY KEY,
    student_id      VARCHAR(50)  NOT NULL,
    first_name      VARCHAR(100),
    last_name       VARCHAR(100),
    gender          VARCHAR(20),
    dob             DATE,
    email           VARCHAR(200),
    department_id   VARCHAR(50),
    effective_date  DATE         NOT NULL,
    expiry_date     DATE,
    is_current      BOOLEAN      DEFAULT TRUE,
    is_active       BOOLEAN      DEFAULT TRUE,
    created_at      TIMESTAMP    DEFAULT NOW(),
    updated_at      TIMESTAMP    DEFAULT NOW()
);

CREATE INDEX idx_dim_students_id     ON dim_students(student_id);
CREATE INDEX idx_dim_students_curr   ON dim_students(student_id, is_current) WHERE is_current;

-- ----------------------------------------------------------
-- fact_enrollments  – Transactional fact table
-- ----------------------------------------------------------
CREATE TABLE fact_enrollments (
    enrollment_sk      SERIAL PRIMARY KEY,
    enrollment_id      VARCHAR(50)  NOT NULL,
    student_sk         INTEGER      NOT NULL REFERENCES dim_students(student_sk),
    course_sk          INTEGER      NOT NULL REFERENCES dim_courses(course_sk),
    instructor_sk      INTEGER      NOT NULL REFERENCES dim_instructors(instructor_sk),
    enrollment_date    DATE,
    semester           VARCHAR(100),
    grade              VARCHAR(10),
    credits            INTEGER,
    created_at         TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_fact_enrollments_student     ON fact_enrollments(student_sk);
CREATE INDEX idx_fact_enrollments_course      ON fact_enrollments(course_sk);
CREATE INDEX idx_fact_enrollments_instructor  ON fact_enrollments(instructor_sk);
