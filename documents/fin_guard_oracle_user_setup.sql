
-- =====================================================================
-- FinGuard AI – Oracle USER, TABLESPACES, ROLES, GRANTS
-- Compatible with Oracle 12c and above
-- Run as a DBA user (e.g., SYS as SYSDBA or a user with CREATE USER/TS)
-- =====================================================================

-- 0) Variables (change as needed)
-- :FG_USER = schema/user name (e.g., FINGUARD)
-- :FG_PASS = strong password
-- :FG_TBS  = main tablespace name (e.g., FINGUARD_TBS)
-- :FG_TMP  = temp tablespace name (e.g., FINGUARD_TMP)
-- :FG_QUOTA_GB = numeric quota in GB (e.g., 10)
-- If you run via SQL*Plus or SQLcl, you can define:
-- DEFINE FG_USER = 'FINGUARD'
-- DEFINE FG_PASS = 'Strong#Password1'
-- DEFINE FG_TBS  = 'FINGUARD_TBS'
-- DEFINE FG_TMP  = 'FINGUARD_TMP'
-- DEFINE FG_QUOTA_GB = 20

-- 1) TABLESPACES (skip if you will reuse USERS/TEMP)
DECLARE
  v_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_exists FROM dba_tablespaces WHERE tablespace_name = UPPER('&FG_TBS');
  IF v_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLESPACE '||'&FG_TBS'||' DATAFILE SIZE 2G AUTOEXTEND ON NEXT 512M MAXSIZE UNLIMITED';
  END IF;

  SELECT COUNT(*) INTO v_exists FROM dba_tablespaces WHERE tablespace_name = UPPER('&FG_TMP');
  IF v_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TEMPORARY TABLESPACE '||'&FG_TMP'||' TEMPFILE SIZE 2G AUTOEXTEND ON NEXT 512M MAXSIZE UNLIMITED';
  END IF;
END;
/
SHOW ERRORS

-- 2) PROFILE (optional: basic password/session controls)
BEGIN
  EXECUTE IMMEDIATE q'[CREATE PROFILE FINGUARD_PROFILE LIMIT
    FAILED_LOGIN_ATTEMPTS 8
    PASSWORD_LIFE_TIME 180
    PASSWORD_REUSE_TIME 365
    PASSWORD_GRACE_TIME 7
    SESSIONS_PER_USER UNLIMITED
    CONNECT_TIME UNLIMITED
    IDLE_TIME 60]';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -519 THEN RAISE; END IF; -- ORA-00519: profile exists (placeholder for existing code)
END;
/
SHOW ERRORS

-- 3) USER
DECLARE
  v_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_exists FROM dba_users WHERE username = UPPER('&FG_USER');
  IF v_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER '||'&FG_USER'||' IDENTIFIED BY "'||'&FG_PASS'||'" '||
                      ' DEFAULT TABLESPACE '||'&FG_TBS'||
                      ' TEMPORARY TABLESPACE '||'&FG_TMP'||
                      ' PROFILE FINGUARD_PROFILE';
  ELSE
    EXECUTE IMMEDIATE 'ALTER USER '||'&FG_USER'||' IDENTIFIED BY "'||'&FG_PASS||'" ACCOUNT UNLOCK';
  END IF;
END;
/
SHOW ERRORS

-- 4) QUOTA & BASIC PRIVILEGES
ALTER USER &FG_USER QUOTA &FG_QUOTA_GB G ON &FG_TBS;

GRANT CREATE SESSION,
      CREATE TABLE, CREATE VIEW, CREATE SEQUENCE, CREATE TRIGGER,
      CREATE PROCEDURE, CREATE TYPE, CREATE MATERIALIZED VIEW
TO &FG_USER;

-- Optional (if you plan to create and manage jobs from the schema):
GRANT CREATE JOB TO &FG_USER;

-- Optional JSON & AQ (depending on features used)
-- GRANT EXECUTE ON DBMS_SCHEDULER TO &FG_USER;
-- GRANT AQ_ADMINISTRATOR_ROLE TO &FG_USER;
-- GRANT EXECUTE ON DBMS_CRYPTO TO &FG_USER;

-- 5) ROLES (analyst vs. svc)
-- Create minimal roles to separate least-privilege access.
BEGIN
  EXECUTE IMMEDIATE 'CREATE ROLE FINGUARD_ROLE_APP';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -01921 THEN RAISE; END IF; END;
/
BEGIN
  EXECUTE IMMEDIATE 'CREATE ROLE FINGUARD_ROLE_READONLY';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -01921 THEN RAISE; END IF; END;
/
GRANT FINGUARD_ROLE_APP TO &FG_USER;

-- Read-only role will be granted after objects are created:
-- Example (post-object creation):
--   GRANT SELECT ON &FG_USER..fg_transactions  TO FINGUARD_ROLE_READONLY;
--   GRANT SELECT ON &FG_USER..fg_alerts        TO FINGUARD_ROLE_READONLY;
--   GRANT SELECT ON &FG_USER..vw_alerts_open   TO FINGUARD_ROLE_READONLY;

-- 6) (Optional) Network ACL if schema needs UTL_HTTP for webhooks/ORDS calls
-- BEGIN
--   DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
--     host => '*',
--     lower_port => null,
--     upper_port => null,
--     ace => xs$ace_type(privilege_list => xs$name_list('connect'),
--                        principal_name => UPPER('&FG_USER'), principal_type => xs_acl.ptype_db)
--   );
-- END;
-- /

PROMPT =====================================================================
PROMPT User &FG_USER is ready. Next steps:
PROMPT 1) Connect:   sqlplus &FG_USER/"&FG_PASS"@//host:port/service
PROMPT 2) Run objects:  @fin_guard_oracle_schema.sql
PROMPT 3) Grant read-only as needed and create synonyms for the UI/API user.
PROMPT =====================================================================
