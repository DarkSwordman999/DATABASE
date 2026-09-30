@ECHO OFF
REM pg_dump_data.bat <ТАБЛИЦА> - данные таблицы PostgreSQL -> d_ТАБЛИЦА.txt
REM (поля через табуляцию, без заголовка, даты ISO, кодировка WIN1251 - для BULK INSERT)
CALL "%~dp0..\config.bat"
SET PGDATESTYLE=ISO
SET PGCLIENTENCODING=WIN1251
"%PGBIN%\psql.exe" -q -t -A -c "\pset fieldsep '\t'" -c "\pset null ''" -c "\pset pager off" -c "SELECT * FROM %~1" > "d_%~1.txt"
