# Rationale for Design Decisions

## Business Domain

The Learning Management System (LMS) domain was selected because it is a well-understood, data-rich environment that mirrors real-world institutional analytics needs. Educational institutions generate structured, high-volume transactional data across students, courses, instructors, and departments, making it ideal for demonstrating dimensional modeling patterns. The domain also provides natural examples of slowly changing dimensions—such as course name updates, instructor transfers between departments, and student record changes—which are essential for teaching data warehouse concepts.

## Business Process

The enrollment process was chosen as the core business process because it is the central transactional event in any LMS. Every academic record, grade, and instructor assignment originates from a student enrolling in a course. Focusing on enrollment captures the relationship between all key entities (students, courses, instructors, departments, and time), enabling comprehensive analytical queries. This single grain allows us to answer critical business questions about academic performance, workload distribution, and institutional trends without overcomplicating the initial scope.

## Data Warehouse

A data warehouse is required for this business process because operational LMS systems are optimized for transactional processing, not analytical queries. The operational database (represented here by the CSV source files) is designed for insert/update operations and day-to-day administration. Analytical questions—such as "What is the average grade per department over the last semester?" or "How has course enrollment changed month-over-month?"—require joining large volumes of historical data across multiple entities, which is inefficient and disruptive on operational systems. The warehouse provides a dedicated, read-optimized environment that preserves historical accuracy, supports SCD tracking, and enables self-service reporting without impacting production operations.

## Data Sources

CSV files were selected as data sources for three practical reasons:
- **Simplicity and portability:** CSVs require no database drivers or network access, making the project easy to distribute, test, and demonstrate in a classroom or portfolio setting.
- **Realistic staging pattern:** In production ETL, source data often arrives as flat files from diverse systems (SIS exports, HR systems, etc.). Using CSVs mirrors this common pattern and justifies the staging layer.
- **Deterministic testing:** Fixed CSV files ensure reproducible ETL runs, which is essential for validating design decisions and debugging.

## Fact Table

`fact_enrollments` was selected as the fact table because enrollment is the transactional event that ties together all dimensions of interest. It records a specific student's participation in a specific course, taught by a specific instructor, on a specific date. This aligns with Kimball's definition of a transaction fact table—each row represents an immutable business event. Alternative fact tables (such as a student snapshot or a course catalog fact) would either duplicate data or fail to capture the many-to-many relationships inherent in enrollment analytics.

## Grain

The grain is **one row per enrollment event**, defined by the composite of `(student, course, instructor, date)`. This grain was chosen because:
- It is the most atomic, actionable level for the business process.
- It preserves full flexibility: analysts can aggregate upward (to student, course, department, or date levels) as needed.
- It eliminates aggregation loss—every enrollment is individually traceable and auditable.
- It supports accurate measure calculation (credits, grades) at the event level.

A coarser grain (e.g., one row per student per course per semester) would risk data loss if multiple instructors teach the same course section, while a finer grain (e.g., daily class attendance snapshots) would introduce data sparsity and overcomplicate the ETL.

## Measures

The selected measures are:
- **enrollment_sk** – Surrogate key for row identity
- **enrollment_id** – Natural key from the source system for traceability
- **enrollment_date** – The date the enrollment transaction occurred
- **semester** – Academic term for period-based analysis
- **grade** – Student performance outcome
- **credits** – Academic weight of the course for GPA and load calculations

These measures are required because they answer the core analytical questions of the LMS domain. Grade and credits enable academic performance analysis; semester and date enable time-series reporting; enrollment_id ensures traceability back to the operational system. Without these measures, the fact table would lack the quantitative attributes necessary for aggregation, filtering, and calculation.

## Generated Measures

Generated measures are calculated in the Superset views rather than persisted in the fact table because:
- **Denormalization for performance:** Views like `vw_department_summary` and `vw_course_performance` pre-join dimension attributes and compute aggregates (`COUNT`, `AVG`, grade distributions) that analysts need immediately. This reduces query complexity in Superset's Explore interface.
- **Business logic centralization:** Grade bucket counts (`grade_a_count`, `grade_b_count`, `grade_c_count`) and `avg_credits` encapsulate business rules in one place, ensuring consistency across dashboards.
- **Dynamic time intelligence:** Monthly trends and year-over-quarter comparisons are derived from `dim_date` attributes, avoiding redundant date parsing in every query.

These calculations are useful because they transform raw transactional data into actionable KPIs—department performance rankings, course popularity metrics, and instructor workload summaries—that drive institutional decision-making.

## Dimensions

The dimension tables were selected based on Kimball's four-step dimension design process, asking "by whom, what, where, when, and why" about the business process:
- **dim_departments:** Organizational unit; required for grouping courses, instructors, and students for departmental reporting.
- **dim_courses:** Academic offering; required for analyzing course popularity, difficulty, and curriculum trends.
- **dim_instructors:** Teaching resource; required for workload analysis, performance evaluation, and resource planning.
- **dim_students:** Learner entity; required for enrollment history, demographic analysis, and academic progression tracking.
- **dim_date:** Calendar context; required for time-series analysis, seasonal trend detection, and fiscal period alignment.

Each dimension supports slicing and dicing the fact table. Omitting any dimension would create a blind spot—for example, without `dim_date`, time-based analysis would require parsing dates in every query.

## Surrogate Keys

Surrogate keys (`*_sk` columns) are required instead of natural keys because:
- **Stability:** Natural keys (e.g., student IDs like "S001") may change over time due to administrative merges, re-enrollments, or source system migrations. Surrogate keys are immutable integers, ensuring referential integrity never breaks.
- **SCD support:** SCD Type 2 requires multiple versions of the same natural key to coexist (e.g., a student who changes their name). Surrogate keys uniquely identify each version without ambiguity.
- **Performance:** Integer surrogate keys are smaller and faster to join and index than composite natural keys or long string identifiers.
- **Integration:** Surrogate keys abstract the source system, allowing the warehouse to evolve independently of upstream schema changes.

## SCD

Two SCD approaches were selected based on the nature of each dimension's attributes:
- **SCD Type 1 (dim_departments):** Department names are master/reference data that do not require historical tracking. If a department is renamed, the new name should apply retroactively to all historical enrollments for accurate current reporting. Type 1 achieves this with simple overwrites and minimal complexity.
- **SCD Type 2 (dim_courses, dim_instructors, dim_students):** These dimensions contain attributes that change over time and where historical accuracy matters. For example:
  - A course's credits may change, but historical enrollments should reflect the credits at the time of enrollment.
  - An instructor's department assignment may change, but past teaching assignments must remain linked to the correct historical department.
  - A student's name or email may change, but transcripts must preserve the student's identity at enrollment time.

Type 2 was chosen over Type 3 or hybrid approaches because it provides full historical fidelity, supports unlimited change tracking, and is the industry standard for dimensional modeling of mutable entities.

## ETL

The ETL architecture uses Python with SQLAlchemy and pandas, executed via a scheduled pipeline script, for the following reasons:
- **Technology familiarity and ecosystem:** Python is the dominant language for data engineering, with extensive libraries for data manipulation (pandas), database connectivity (SQLAlchemy), and scheduling (cron, Airflow).
- **COPY-based staging load:** Using PostgreSQL's `COPY` command via raw psycopg2 connections provides high-performance bulk loading for CSV files, far exceeding row-by-row INSERT performance.
- **SQL-driven transformations:** Dimension processing and fact loading are implemented in SQL rather than Python to leverage the database's set-based processing, indexing, and transaction management. This separation keeps the pipeline maintainable and performant.
- **Idempotent design:** Truncating staging tables before each run ensures reproducibility. The pipeline can be re-run safely without creating duplicate data.

Alternative architectures (such as ELT with dbt or cloud-native tools like AWS Glue) were not selected because they introduce external dependencies and infrastructure complexity that outweigh their benefits for a project of this scope.

## Schema

The **Star Schema** was selected over Snowflake Schema for the following reasons:
- **Query performance:** Star schemas minimize join depth. The fact table connects directly to each dimension via foreign keys, enabling fast aggregation and simple query construction in Superset.
- **Business user accessibility:** Superset's point-and-click interface works best with flat, denormalized structures. Star schemas reduce the cognitive load for analysts building dashboards.
- **Optimization:** Dimensions are designed for filtering (WHERE clauses) and grouping (GROUP BY), while the fact table is optimized for aggregation. This separation aligns with how BI tools generate SQL.
- **No redundancy justification:** While the Snowflake Schema normalizes dimensions further (e.g., splitting `dim_courses` into course and department tables), the LMS dimensions have few attributes and minimal redundancy. Normalization would add unnecessary join complexity without meaningful storage savings or data integrity improvements.
