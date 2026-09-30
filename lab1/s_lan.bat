@ECHO OFF
REM s_lan.bat <сценарий> [arg1 [arg2 [arg3]]] - клиент К: сценарий в БД sales на сервере С по сети
REM Каталог клиента (например D:\TO_PG) содержит этот файл и подкаталог bin с минимальным
REM набором файлов psql (см. lab1\client_files.txt). Адрес сервера - IPv4 компьютера с PostgreSQL.
REM Пароль лучше хранить в %APPDATA%\postgresql\pgpass.conf, а не в командном файле.
CHCP 65001 >NUL
SET PGHOST=192.168.0.102
SET PGPORT=5432
SET PGUSER=postgres
SET PGDATABASE=sales
SET PGCLIENTENCODING=UTF8
SET "PATH=C:\Windows\System32;%~dp0bin"
SET "SCRIPT=%~1"
SET "SCRIPT=%SCRIPT:\=/%"
(ECHO \set arg1 '%~2'& ECHO \set arg2 '%~3'& ECHO \set arg3 '%~4'& ECHO \i '%SCRIPT%') | psql.exe -q -P "null=<null>" -P pager=off -f -
