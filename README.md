# LMS Data Warehouse

A star-schema data warehouse for a Learning Management System (LMS) built with PostgreSQL, Python ETL, and Apache Superset.

## Stack

- PostgreSQL 16 – warehouse database
- Python + SQLAlchemy + pandas – ETL pipeline
- Apache Superset – BI and dashboards

## Prerequisites

- PostgreSQL running on port 5434
- Python 3.10+ with virtualenv activated

## Setup

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Database Setup

```bash
# Create database and user
sudo -u postgres psql -f sql/01_create_database.sql

# Grant privileges
sudo -u postgres bash sql/setup_db.sh

# Create staging tables
PGPASSWORD=lms_password psql -h localhost -p 5434 -U lms_user -d lms_warehouse -f sql/02_create_staging_tables.sql

# Create warehouse tables
PGPASSWORD=lms_password psql -h localhost -p 5434 -U lms_user -d lms_warehouse -f sql/03_create_warehouse_tables.sql

# Load dim_date (calendar dimension)
PGPASSWORD=lms_password psql -h localhost -p 5434 -U lms_user -d lms_warehouse -f sql/06_create_dim_date.sql

# Create Superset views
PGPASSWORD=lms_password psql -h localhost -p 5434 -U lms_user -d lms_warehouse -f sql/05_superset_views.sql
```

## Run ETL

```bash
python etl/etl_pipeline.py
```

## Superset Setup

```bash
docker compose -f docker-compose.superset.yml up -d
```

1. Open http://localhost:8088
2. Log in with admin / admin (or set ADMIN_USER/ADMIN_PASSWORD env vars)
3. Go to **Data → Databases → + Database**
4. Select **PostgreSQL**
5. Connection string:
   ```
   postgresql+psycopg2://lms_user:lms_password@host.docker.internal:5434/lms_warehouse
   ```
   (Use `localhost` instead of `host.docker.internal` if connecting from host, not Docker)
6. Click **Connect** and save

### Import Datasets

In Superset, go to **Data → Datasets → + Dataset** and select the following views:

- `vw_enrollment_fact` – main fact dataset for most charts
- `vw_department_summary` – department-level metrics
- `vw_course_performance` – course-level metrics
- `vw_monthly_trends` – time-series trends
- `vw_instructor_workload` – instructor metrics
- `vw_current_students`, `vw_current_courses`, `vw_current_instructors` – dimension lookups

## Schema

**Dimensions:**
- `dim_departments` – SCD Type 1
- `dim_courses` – SCD Type 2
- `dim_instructors` – SCD Type 2
- `dim_students` – SCD Type 2
- `dim_date` – calendar dimension

**Fact:**
- `fact_enrollments` – transactional enrollment events
