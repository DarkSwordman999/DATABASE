@ECHO OFF
REM config.bat - переменные окружения ЛР4: подключение к серверу PostgreSQL
REM с правами владельца/администратора базы BASE и пути к утилитам
CHCP 65001 >NUL
SET PGHOST=localhost
SET PGPORT=5432
SET PGUSER=postgres
REM SET PGPASSWORD=...   (если в pg_hba.conf для localhost задан метод scram-sha-256/md5)
SET PGCLIENTENCODING=UTF8
SET BASE=base
SET "PGBIN=C:\Program Files\PostgreSQL\18\bin"
SET "RAR=C:\Program Files\WinRAR\Rar.exe"
REM рабочий каталог копий: lab4\work или каталог из переменной LR4_WORK
REM (например, SET LR4_WORK=D:\LR4_WORK, если на системном диске мало места)
SET "WORK=%~dp0work"
IF NOT "%LR4_WORK%"=="" SET "WORK=%LR4_WORK%"
REM не выводить замечания сервера (NOTICE) в протокол
SET PGOPTIONS=-c client_min_messages=warning
IF NOT EXIST "%WORK%" MKDIR "%WORK%"
