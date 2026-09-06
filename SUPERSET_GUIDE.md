# Superset Dashboard Guide

## Prerequisites

- Superset is running at http://localhost:8088
- Warehouse database is accessible at `localhost:5434`
- ETL has been run successfully (300 facts, dimensions populated)

---

## Step 1: Log In to Superset

1. Open http://localhost:8088 in your browser
2. Log in with default credentials:
   - **Username:** `admin`
   - **Password:** `admin`

---

## Step 2: Connect to the LMS Warehouse Database

1. Click **Data → Databases → + Database**
2. Select **PostgreSQL**
3. Enter connection details:

   | Field | Value |
   |-------|-------|
   | Database | `lms_warehouse` |
   | Host | `localhost` |
   | Port | `5434` |
   | Username | `lms_user` |
   | Password | `lms_password` |
   | Display Name | `LMS Warehouse` |

4. Click **Connect**
5. Click **Save**

> **Note:** If connecting from Docker, use `host.docker.internal` instead of `localhost`. If connecting from the host machine, use `localhost`.

---

## Step 3: Add Datasets

Datasets in Superset represent tables or views you can explore. Import the following datasets:

1. Click **Data → Datasets → + Dataset**
2. Select database: **LMS Warehouse**
3. Select schema: `public`
4. Select the following tables/views and click **Save** for each:

### Required Datasets

| Dataset Name | Source | Description |
|--------------|--------|-------------|
| `vw_enrollment_fact` | View | Main fact table for ad-hoc analysis |
| `vw_department_summary` | View | Department-level aggregated metrics |
| `vw_course_performance` | View | Course-level performance metrics |
| `vw_monthly_trends` | View | Time-series trends by month |
| `vw_instructor_workload` | View | Instructor workload metrics |
| `dim_departments` | Table | Department dimension |
| `dim_courses` | Table | Course dimension |
| `dim_students` | Table | Student dimension |
| `dim_instructors` | Table | Instructor dimension |
| `dim_date` | Table | Date dimension |

---

## Step 4: Create Charts

### Chart 1: Department Enrollment Distribution (Pie Chart)

1. Click **Charts → + Chart**
2. Dataset: **vw_department_summary**
3. Chart type: **Pie Chart**
4. Configure:
   - **Metric:** `SUM(total_enrollments)`
   - **Group by:** `department_name`
   - **Label:** `department_name`
   - **Value:** `total_enrollments`
5. Click **Run**
6. Save as: **"Department Enrollment Distribution"**

### Chart 2: Monthly Enrollment Trends (Line Chart)

1. Click **Charts → + Chart**
2. Dataset: **vw_monthly_trends**
3. Chart type: **Line Chart**
4. Configure:
   - **X-axis:** `month_name` (sort by `month`)
   - **Y-axis:** `SUM(total_enrollments)`
   - **Metric:** `SUM(total_enrollments)`
5. Click **Run**
6. Save as: **"Monthly Enrollment Trends"**

### Chart 3: Grade Distribution by Department (Bar Chart)

1. Click **Charts → + Chart**
2. Dataset: **vw_department_summary**
3. Chart type: **Bar Chart**
4. Configure:
   - **X-axis:** `department_name`
   - **Y-axis:** `SUM(grade_a_count)`, `SUM(grade_b_count)`, `SUM(grade_c_count)`
   - **Group by:** `department_name`
5. Click **Run**
6. Save as: **"Grade Distribution by Department"**

### Chart 4: Instructor Workload (Bar Chart)

1. Click **Charts → + Chart**
2. Dataset: **vw_instructor_workload**
3. Chart type: **Bar Chart**
4. Configure:
   - **X-axis:** `instructor_name`
   - **Y-axis:** `SUM(total_enrollments)`
   - **Group by:** `instructor_name`
   - **Sort:** Descending by `total_enrollments`
5. Click **Run**
6. Save as: **"Instructor Workload"**

### Chart 5: Course Success Rate (Bar Chart)

1. Click **Charts → + Chart**
2. Dataset: **vw_course_performance**
3. Chart type: **Bar Chart**
4. Configure:
   - **X-axis:** `course_name`
   - **Y-axis:** `AVG(success_rate)`
   - **Group by:** `course_name`
   - **Sort:** Descending by `success_rate`
5. Click **Run**
6. Save as: **"Course Success Rate"**

### Chart 6: Average Credits by Department (Big Number)

1. Click **Charts → + Chart**
2. Dataset: **vw_department_summary**
3. Chart type: **Big Number**
4. Configure:
   - **Metric:** `AVG(avg_credits)`
   - **Subtitle:** "Average Credits per Enrollment"
5. Click **Run**
6. Save as: **"Average Credits"**

---

## Step 5: Create Dashboard

1. Click **Dashboards → + Dashboard**
2. Dashboard title: **"LMS Analytics Dashboard"**
3. Click **Save**
4. Click **Edit dashboard** (pencil icon)
5. Drag and drop the charts you created into the dashboard grid:
   - Department Enrollment Distribution (top-left)
   - Monthly Enrollment Trends (top-right)
   - Grade Distribution by Department (middle-left)
   - Instructor Workload (middle-right)
   - Course Success Rate (bottom-left)
   - Average Credits (bottom-right)
6. Click **Save** to persist the layout
7. Click **Exit** to view the dashboard

---

## Step 6: Add Filters (Optional)

1. While editing the dashboard, click **Filters → + Add a filter**
2. Add the following filters:

### Filter 1: Department
- Dataset: `vw_enrollment_fact`
- Column: `student_department_id`
- Filter type: `Dropdown`
- Allow multiple selections: Yes

### Filter 2: Semester
- Dataset: `vw_enrollment_fact`
- Column: `semester`
- Filter type: `Dropdown`

### Filter 3: Grade
- Dataset: `vw_enrollment_fact`
- Column: `grade`
- Filter type: `Dropdown`

3. Click **Save**
4. Click **Exit**

Now you can filter the entire dashboard by department, semester, or grade.

---

## Step 7: Export Analysis

### Export Dashboard as PDF
1. View the dashboard
2. Click **⋯ (More actions) → Export to PDF**
3. The PDF will download automatically

### Export Dashboard as Image
1. View the dashboard
2. Click **⋯ (More actions) → Download**
3. Select **PNG** or **SVG**

### Export Individual Chart Data
1. Open a chart
2. Click **⋯ (More actions) → Export CSV**
3. The CSV will download automatically

---

## Step 8: Schedule Automatic Email Reports (Optional)

1. Go to **Data → Reports → + Add report**
2. Configure:
   - **Name:** "Weekly LMS Summary"
   - **Dashboard:** "LMS Analytics Dashboard"
   - **Recipients:** Add email addresses
   - **Schedule:** Select frequency (daily/weekly/monthly)
   - **Format:** PDF or CSV
3. Click **Save**

Superset will automatically email the dashboard PDF on the scheduled interval.

---

## Sample Analytical Outputs

### Output 1: Department Performance Summary

| Department | Total Enrollments | Unique Students | Avg Credits | Grade A % |
|------------|-------------------|-----------------|-------------|-----------|
| Computing | 60 | 20 | 3.00 | 38.33% |
| Cyber Security | 60 | 20 | 3.00 | 36.67% |
| Data Science | 60 | 20 | 3.67 | 38.33% |
| Information Technology | 60 | 20 | 3.00 | 36.67% |
| Software Engineering | 60 | 20 | 3.00 | 38.33% |

**Insight:** All departments have equal enrollment volume (60 each), but Data Science courses carry higher average credits (3.67 vs 3.00).

### Output 2: Monthly Enrollment Trends

| Month | Enrollments | Active Students | Avg Credits |
|-------|-------------|-----------------|-------------|
| January | 44 | 44 | 3.16 |
| February | 56 | 56 | 3.11 |
| March | 62 | 62 | 3.16 |
| April | 60 | 60 | 3.13 |
| May | 60 | 60 | 3.12 |
| June | 18 | 18 | 3.11 |

**Insight:** Enrollment peaks in March (62) and drops significantly in June (18), aligning with semester start/end patterns.

### Output 3: Instructor Workload

| Instructor | Department | Enrollments | Courses | Students |
|------------|------------|-------------|---------|----------|
| Tharindu Jayasinghe | Software Engineering | 60 | 2 | 20 |
| Piumi Senanayake | Cyber Security | 60 | 2 | 20 |
| Kasun Perera | Computing | 30 | 3 | 10 |
| Nadeesha Fernando | Information Technology | 30 | 1 | 10 |

**Insight:** Two instructors carry double the workload of others, indicating potential resource imbalance.

### Output 4: Course Success Rates

| Course | Department | Enrollments | Success Rate |
|--------|------------|-------------|--------------|
| Web Application Development | Software Engineering | 30 | 50.00% |
| Cyber Security Fundamentals | Cyber Security | 30 | 50.00% |
| Database Systems | Computing | 20 | 45.00% |
| Data Mining | Data Science | 20 | 45.00% |

**Insight:** Technical courses show success rates between 45-50%, suggesting consistent academic rigor across departments.

---

## Troubleshooting

### Cannot connect to database from Superset
- Ensure PostgreSQL is running on port 5434
- If using Docker, use `host.docker.internal` instead of `localhost`
- Verify credentials in `.env` file

### Charts show no data
- Ensure ETL has been run successfully
- Verify datasets are pointing to the correct tables/views
- Check that the warehouse database is not empty

### Slow dashboard performance
- Ensure indexes exist on foreign key columns
- Use the pre-aggregated views (`vw_department_summary`, etc.) instead of raw fact tables
- Enable Superset caching: **Settings → Caching**
