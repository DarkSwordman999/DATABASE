@ECHO OFF
REM s0.bat - интерактивная консоль psql, подключение к системной БД postgres сервера
REM Для работы по локальной сети заменить PGHOST на IPv4-адрес сервера (например 192.168.1.50)
CHCP 65001 >NUL
SET PGHOST=localhost
SET PGPORT=5432
SET PGUSER=postgres
SET PGCLIENTENCODING=UTF8
psql.exe -d postgres
