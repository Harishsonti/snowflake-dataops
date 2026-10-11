-- Least-privilege role setup for the snowflake-dataops demo.
-- Review and execute manually in a Snowflake worksheet as a role authorized
-- to create roles and grant privileges. This script does not change any
-- GitHub secrets or automatically switch the workflows to this role.

USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS DATAOPS_DEPLOY_ROLE
  COMMENT = 'Least-privilege role for the snowflake-dataops demo migrations';

-- Allow the deployment role to use the existing warehouse/database/schema.
GRANT USAGE ON WAREHOUSE DATAOPS_WH TO ROLE DATAOPS_DEPLOY_ROLE;
GRANT USAGE ON DATABASE DATAOPS_DB TO ROLE DATAOPS_DEPLOY_ROLE;
GRANT USAGE ON SCHEMA DATAOPS_DB.DATAOPS_DEMO TO ROLE DATAOPS_DEPLOY_ROLE;

-- Current demo migrations create tables and views. The schema migration is
-- idempotent and the schema already exists. CREATE SCHEMA is intentionally
-- not granted because the existing demo schema is the deployment target.
GRANT CREATE TABLE, CREATE VIEW
  ON SCHEMA DATAOPS_DB.DATAOPS_DEMO
  TO ROLE DATAOPS_DEPLOY_ROLE;

-- schemachange reads and appends migration records in the existing history.
GRANT SELECT, INSERT
  ON TABLE DATAOPS_DB.DATAOPS_DEMO.CHANGE_HISTORY
  TO ROLE DATAOPS_DEPLOY_ROLE;

-- Grant the role to the current demo user so it can be selected for testing.
-- For a production implementation, prefer a dedicated service user instead.
GRANT ROLE DATAOPS_DEPLOY_ROLE TO USER HARISHSONTI12;

-- Verify grants after the script runs:
SHOW GRANTS TO ROLE DATAOPS_DEPLOY_ROLE;
SHOW GRANTS TO USER HARISHSONTI12;
