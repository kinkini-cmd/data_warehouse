-- ============================================================
-- Staging Tables
-- Exact mirror of CSV source files for the LMS Data Warehouse
-- ============================================================

DROP TABLE IF EXISTS stg_enrollments;
DROP TABLE IF EXISTS stg_students;
DROP TABLE IF EXISTS stg_instructors;
DROP TABLE IF EXISTS stg_courses;
DROP TABLE IF EXISTS stg_departments;

CREATE TABLE stg_departments (
    "DepartmentID"   VARCHAR(50),
    "DepartmentName" VARCHAR(100)
);

CREATE TABLE stg_courses (
    "CourseID"      VARCHAR(50),
    "CourseName"    VARCHAR(200),
    "Credits"       INTEGER,
    "DepartmentID"  VARCHAR(50)
);

CREATE TABLE stg_instructors (
    "InstructorID"    VARCHAR(50),
    "InstructorName"  VARCHAR(200),
    "DepartmentID"    VARCHAR(50)
);

CREATE TABLE stg_students (
    "StudentID"     VARCHAR(50),
    "FirstName"     VARCHAR(100),
    "LastName"      VARCHAR(100),
    "Gender"        VARCHAR(20),
    "DOB"           DATE,
    "Email"         VARCHAR(200),
    "DepartmentID"  VARCHAR(50)
);

CREATE TABLE stg_enrollments (
    "EnrollmentID"     VARCHAR(50),
    "StudentID"        VARCHAR(50),
    "CourseID"         VARCHAR(50),
    "InstructorID"     VARCHAR(50),
    "EnrollmentDate"   DATE,
    "Semester"         VARCHAR(100),
    "Grade"            VARCHAR(10)
);
