@ECHO OFF
REM s.bat <сценарий> [arg1 [arg2 [arg3]]] - выполнить сценарий в БД sales с параметрами
REM Пример: s.bat tasks\v20_task1.sql 21.08.2020 20.08.2023 мебель
REM Для работы по локальной сети заменить PGHOST на IPv4-адрес сервера (например 192.168.1.50)
REM Параметры передаются через stdin командами \set (аналог -v arg1=%2 ...):
REM psql под Windows получает argv в CP1251, и кириллица в -v ломается при UTF8.
CHCP 65001 >NUL
SET PGHOST=localhost
SET PGPORT=5432
SET PGUSER=postgres
SET PGDATABASE=sales
SET PGCLIENTENCODING=UTF8
SET "SCRIPT=%~1"
SET "SCRIPT=%SCRIPT:\=/%"
(ECHO \set arg1 '%~2'& ECHO \set arg2 '%~3'& ECHO \set arg3 '%~4'& ECHO \i '%SCRIPT%') | psql.exe -q -P "null=<null>" -P pager=off -f -
