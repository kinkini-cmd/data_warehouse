-- Create the warehouse database and project user
CREATE DATABASE lms_warehouse;

CREATE USER lms_user WITH PASSWORD 'lms_password';

GRANT ALL PRIVILEGES ON DATABASE lms_warehouse TO lms_user;
