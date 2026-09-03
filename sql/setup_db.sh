#!/bin/bash
# Setup script: run as postgres OS user via:
#   sudo -u postgres bash sql/setup_db.sh
#
# This creates the lms_warehouse database and grants privileges to lms_user.
# The lms_user role already exists, so we skip CREATE USER.

createdb lms_warehouse 2>/dev/null && echo "Database lms_warehouse created." || echo "Database lms_warehouse already exists."

psql -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE lms_warehouse TO lms_user;" 2>&1

psql -d postgres -c "GRANT ALL ON SCHEMA public TO lms_user;" 2>&1
psql -d postgres -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO lms_user;" 2>&1
psql -d postgres -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO lms_user;" 2>&1
psql -d postgres -c "GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO lms_user;" 2>&1

echo "=== Database setup complete ==="
