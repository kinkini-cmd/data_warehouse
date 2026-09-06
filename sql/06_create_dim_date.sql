-- ============================================================
-- dim_date – Standalone creation / migration script
--
-- Run this if you already have a warehouse and want to add
-- the date dimension without dropping all tables.
-- ============================================================

CREATE TABLE IF NOT EXISTS dim_date (
    date_sk           INTEGER      PRIMARY KEY,
    date              DATE         NOT NULL,
    day               INTEGER      NOT NULL,
    month             INTEGER      NOT NULL,
    year              INTEGER      NOT NULL,
    quarter           INTEGER      NOT NULL,
    day_of_week       INTEGER      NOT NULL,
    day_name          VARCHAR(10)  NOT NULL,
    month_name        VARCHAR(10)  NOT NULL,
    is_weekend        BOOLEAN      NOT NULL,
    fiscal_year       INTEGER      NOT NULL,
    fiscal_quarter    INTEGER      NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_dim_date_date   ON dim_date(date);
CREATE INDEX IF NOT EXISTS idx_dim_date_year   ON dim_date(year);
CREATE INDEX IF NOT EXISTS idx_dim_date_month  ON dim_date(month);
CREATE INDEX IF NOT EXISTS idx_dim_date_quarter ON dim_date(quarter);

TRUNCATE TABLE dim_date RESTART IDENTITY CASCADE;

INSERT INTO dim_date (date_sk, date, day, month, year, quarter, day_of_week, day_name, month_name, is_weekend, fiscal_year, fiscal_quarter)
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
FROM generate_series('2026-01-01'::DATE, '2026-12-31'::DATE, '1 day'::INTERVAL) AS d;

ALTER TABLE fact_enrollments ADD COLUMN IF NOT EXISTS date_sk INTEGER;

UPDATE fact_enrollments fe
SET date_sk = dd.date_sk
FROM dim_date dd
WHERE dd.date = fe.enrollment_date;

ALTER TABLE fact_enrollments ALTER COLUMN date_sk SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_fact_enrollments_date_sk ON fact_enrollments(date_sk);
