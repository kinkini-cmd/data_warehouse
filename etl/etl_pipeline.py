"""
LMS Data Warehouse ETL Pipeline

Extracts data from CSV source files, loads into staging tables,
processes Slowly Changing Dimensions (Type 1 and Type 2), and
populates the star-schema warehouse (dimension + fact tables).

Usage:
    python etl/etl_pipeline.py
"""

import logging
import sys
from pathlib import Path

import pandas as pd
from sqlalchemy import text

from config import DATA_DIR, LOG_DIR, get_engine, get_raw_connection

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(LOG_DIR / "etl.log"),
    ],
)
logger = logging.getLogger(__name__)

CSV_TABLE_MAP = {
    "stg_departments": "departments.csv",
    "stg_courses": "courses.csv",
    "stg_instructors": "instructors.csv",
    "stg_students": "students.csv",
    "stg_enrollments": "enrollments.csv",
}


# ------------------------------------------------------------------ #
#  Staging load
# ------------------------------------------------------------------ #
def truncate_staging(engine):
    """Empty all staging tables before reload."""
    tables = list(CSV_TABLE_MAP.keys())
    with engine.begin() as conn:
        for t in tables:
            conn.execute(text(f"TRUNCATE TABLE {t}"))
        conn.execute(text("TRUNCATE TABLE fact_enrollments RESTART IDENTITY"))
    logger.info("Staging and fact tables truncated.")


def load_staging_tables(engine):
    """Load CSV files into staging tables using PostgreSQL COPY."""
    for table, csv_name in CSV_TABLE_MAP.items():
        csv_path = DATA_DIR / csv_name
        with get_raw_connection(engine) as raw_conn:
            cursor = raw_conn.cursor()
            with open(csv_path, "r") as f:
                cursor.copy_expert(
                    f'COPY {table} FROM STDIN WITH (FORMAT csv, HEADER true)',
                    f,
                )
            raw_conn.commit()
        df = pd.read_csv(csv_path)
        logger.info(f"Loaded {len(df)} rows into {table}")


# ------------------------------------------------------------------ #
#  Dimension processing
# ------------------------------------------------------------------ #
def process_dim_departments(engine):
    """SCD Type 1 – insert new, update changed attributes."""
    with engine.begin() as conn:
        # Insert new departments
        conn.execute(text("""
            INSERT INTO dim_departments (department_id, department_name)
            SELECT DISTINCT "DepartmentID", "DepartmentName"
            FROM stg_departments s
            WHERE NOT EXISTS (
                SELECT 1 FROM dim_departments d
                WHERE d.department_id = s."DepartmentID"
            )
        """))
        # Update changed attributes
        conn.execute(text("""
            UPDATE dim_departments d
            SET department_name = s."DepartmentName",
                updated_at = NOW()
            FROM stg_departments s
            WHERE d.department_id = s."DepartmentID"
              AND d.department_name <> s."DepartmentName"
        """))
        result = conn.execute(text("SELECT COUNT(*) FROM dim_departments"))
        count = result.scalar()
    logger.info(f"dim_departments (SCD Type 1) – {count} rows")


def process_dim_courses(engine):
    """SCD Type 2 – expire changed records, insert new versions."""
    with engine.begin() as conn:
        # 1. Close out expired records where attributes changed
        conn.execute(text("""
            UPDATE dim_courses d
            SET expiry_date = CURRENT_DATE,
                is_current  = FALSE,
                updated_at  = NOW()
            FROM stg_courses s
            WHERE d.course_id = s."CourseID"
              AND d.is_current = TRUE
              AND ( COALESCE(d.course_name, '')   <> COALESCE(s."CourseName", '')
                 OR COALESCE(d.credits::TEXT, '')  <> COALESCE(s."Credits"::TEXT, '')
                 OR COALESCE(d.department_id, '')  <> COALESCE(s."DepartmentID", '') )
        """))
        # 2. Insert new/changed records as new current versions
        conn.execute(text("""
            INSERT INTO dim_courses (
                course_id, course_name, credits, department_id, effective_date
            )
            SELECT DISTINCT s."CourseID", s."CourseName", s."Credits",
                   s."DepartmentID", CURRENT_DATE
            FROM stg_courses s
            WHERE NOT EXISTS (
                SELECT 1 FROM dim_courses d
                WHERE d.course_id = s."CourseID"
                  AND d.is_current = TRUE
                  AND COALESCE(d.course_name, '')   = COALESCE(s."CourseName", '')
                  AND COALESCE(d.credits::TEXT, '')  = COALESCE(s."Credits"::TEXT, '')
                  AND COALESCE(d.department_id, '')  = COALESCE(s."DepartmentID", '')
            )
        """))
        result = conn.execute(
            text("SELECT COUNT(*) FROM dim_courses WHERE is_current = TRUE")
        )
        count = result.scalar()
    logger.info(f"dim_courses (SCD Type 2) – {count} current rows")


def process_dim_instructors(engine):
    """SCD Type 2 – expire changed records, insert new versions."""
    with engine.begin() as conn:
        conn.execute(text("""
            UPDATE dim_instructors d
            SET expiry_date = CURRENT_DATE,
                is_current  = FALSE,
                updated_at  = NOW()
            FROM stg_instructors s
            WHERE d.instructor_id = s."InstructorID"
              AND d.is_current = TRUE
              AND ( COALESCE(d.instructor_name, '')  <> COALESCE(s."InstructorName", '')
                 OR COALESCE(d.department_id, '')    <> COALESCE(s."DepartmentID", '') )
        """))
        conn.execute(text("""
            INSERT INTO dim_instructors (
                instructor_id, instructor_name, department_id, effective_date
            )
            SELECT DISTINCT s."InstructorID", s."InstructorName",
                   s."DepartmentID", CURRENT_DATE
            FROM stg_instructors s
            WHERE NOT EXISTS (
                SELECT 1 FROM dim_instructors d
                WHERE d.instructor_id = s."InstructorID"
                  AND d.is_current = TRUE
                  AND COALESCE(d.instructor_name, '') = COALESCE(s."InstructorName", '')
                  AND COALESCE(d.department_id, '')   = COALESCE(s."DepartmentID", '')
            )
        """))
        result = conn.execute(
            text("SELECT COUNT(*) FROM dim_instructors WHERE is_current = TRUE")
        )
        count = result.scalar()
    logger.info(f"dim_instructors (SCD Type 2) – {count} current rows")


def process_dim_students(engine):
    """SCD Type 2 – expire changed records, insert new versions."""
    with engine.begin() as conn:
        conn.execute(text("""
            UPDATE dim_students d
            SET expiry_date = CURRENT_DATE,
                is_current  = FALSE,
                updated_at  = NOW()
            FROM stg_students s
            WHERE d.student_id = s."StudentID"
              AND d.is_current = TRUE
              AND ( COALESCE(d.first_name, '')  <> COALESCE(s."FirstName", '')
                 OR COALESCE(d.last_name, '')   <> COALESCE(s."LastName", '')
                 OR COALESCE(d.gender, '')      <> COALESCE(s."Gender", '')
                 OR COALESCE(d.email, '')       <> COALESCE(s."Email", '')
                 OR COALESCE(d.department_id, '') <> COALESCE(s."DepartmentID", '') )
        """))
        conn.execute(text("""
            INSERT INTO dim_students (
                student_id, first_name, last_name, gender,
                dob, email, department_id, effective_date
            )
            SELECT DISTINCT s."StudentID", s."FirstName", s."LastName", s."Gender",
                   s."DOB", s."Email", s."DepartmentID", CURRENT_DATE
            FROM stg_students s
            WHERE NOT EXISTS (
                SELECT 1 FROM dim_students d
                WHERE d.student_id = s."StudentID"
                  AND d.is_current = TRUE
                  AND COALESCE(d.first_name, '')  = COALESCE(s."FirstName", '')
                  AND COALESCE(d.last_name, '')   = COALESCE(s."LastName", '')
                  AND COALESCE(d.gender, '')      = COALESCE(s."Gender", '')
                  AND COALESCE(d.email, '')       = COALESCE(s."Email", '')
                  AND COALESCE(d.department_id, '') = COALESCE(s."DepartmentID", '')
            )
        """))
        result = conn.execute(
            text("SELECT COUNT(*) FROM dim_students WHERE is_current = TRUE")
        )
        count = result.scalar()
    logger.info(f"dim_students (SCD Type 2) – {count} current rows")


# ------------------------------------------------------------------ #
#  Date dimension processing
# ------------------------------------------------------------------ #
def process_dim_date(engine):
    """Load dim_date for the calendar year."""
    with engine.begin() as conn:
        conn.execute(text("TRUNCATE TABLE dim_date RESTART IDENTITY CASCADE"))
        conn.execute(text("""
            INSERT INTO dim_date (
                date_sk, date, day, month, year, quarter,
                day_of_week, day_name, month_name, is_weekend,
                fiscal_year, fiscal_quarter
            )
            SELECT
                TO_CHAR(d, 'YYYYMMDD')::INTEGER        AS date_sk,
                d                                       AS date,
                EXTRACT(DAY FROM d)::INTEGER            AS day,
                EXTRACT(MONTH FROM d)::INTEGER          AS month,
                EXTRACT(YEAR FROM d)::INTEGER           AS year,
                EXTRACT(QUARTER FROM d)::INTEGER        AS quarter,
                EXTRACT(DOW FROM d)::INTEGER            AS day_of_week,
                TRIM(TO_CHAR(d, 'FMDay'))               AS day_name,
                TRIM(TO_CHAR(d, 'FMMonth'))             AS month_name,
                CASE WHEN EXTRACT(DOW FROM d) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend,
                EXTRACT(YEAR FROM d)::INTEGER           AS fiscal_year,
                EXTRACT(QUARTER FROM d)::INTEGER        AS fiscal_quarter
            FROM generate_series('2026-01-01'::DATE, '2026-12-31'::DATE, '1 day'::INTERVAL) AS d
        """))
        result = conn.execute(text("SELECT COUNT(*) FROM dim_date"))
        count = result.scalar()
    logger.info(f"dim_date – {count} rows")


# ------------------------------------------------------------------ #
#  Fact table
# ------------------------------------------------------------------ #
def load_fact_enrollments(engine):
    """Load fact_enrollments by joining staging to dimension surrogate keys."""
    with engine.begin() as conn:
        conn.execute(text("""
            INSERT INTO fact_enrollments (
                enrollment_id, student_sk, course_sk, instructor_sk, date_sk,
                enrollment_date, semester, grade, credits
            )
            SELECT
                se."EnrollmentID",
                ds.student_sk,
                dc.course_sk,
                di.instructor_sk,
                dd.date_sk,
                se."EnrollmentDate",
                se."Semester",
                se."Grade",
                sc."Credits"
            FROM stg_enrollments se
            JOIN dim_students ds
              ON ds.student_id = se."StudentID"
              AND ds.is_current = TRUE
            JOIN dim_courses dc
              ON dc.course_id = se."CourseID"
              AND dc.is_current = TRUE
            JOIN dim_instructors di
              ON di.instructor_id = se."InstructorID"
              AND di.is_current = TRUE
            JOIN dim_date dd
              ON dd.date = se."EnrollmentDate"
            JOIN stg_courses sc
              ON sc."CourseID" = se."CourseID"
        """))
        result = conn.execute(text("SELECT COUNT(*) FROM fact_enrollments"))
        count = result.scalar()
    logger.info(f"fact_enrollments – {count} rows")


# ------------------------------------------------------------------ #
#  Main
# ------------------------------------------------------------------ #
def main():
    logger.info("=== LMS Data Warehouse ETL Pipeline – starting ===")
    engine = get_engine()

    truncate_staging(engine)
    load_staging_tables(engine)

    process_dim_departments(engine)
    process_dim_courses(engine)
    process_dim_instructors(engine)
    process_dim_students(engine)
    process_dim_date(engine)

    load_fact_enrollments(engine)

    logger.info("=== ETL Pipeline complete ===")


if __name__ == "__main__":
    main()
