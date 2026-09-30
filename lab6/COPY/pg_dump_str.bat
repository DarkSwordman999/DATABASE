@ECHO OFF
REM pg_dump_str.bat <ТАБЛИЦА> - структура таблицы PostgreSQL -> cr_ТАБЛИЦА.txt (CREATE TABLE для MS SQL Server)
REM pg_dump выводит структуру, sel2.exe переводит её в синтаксис T-SQL.
REM Кодировка WIN1251: psql/pg_dump получают имя таблицы из командной строки в CP1251.
CALL "%~dp0..\config.bat"
SET PGCLIENTENCODING=WIN1251
"%PGBIN%\pg_dump.exe" -s -t """%~1""" %PGDATABASE% | "%~dp0sel2.exe" > "cr_%~1.txt"
