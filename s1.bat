@ECHO OFF
REM s1.bat <сценарий> - выполнить сценарий в системной БД postgres (например: s1.bat DATA\create_DB)
CHCP 65001 >NUL
SET PGHOST=localhost
SET PGPORT=5432
SET PGUSER=postgres
SET PGCLIENTENCODING=UTF8
psql.exe -q -c "\pset null '<null>'" -c "\pset pager off" -d postgres -f %1
