@ECHO OFF
REM s_TCP.bat <сценарий> [кодовая страница сценария] - выполнить сценарий T-SQL в MS SQL Server
REM Кодовая страница по умолчанию 65001 (UTF-8); cr_ТАБЛИЦА.txt из pg_dump_str.bat - 1251
CHCP 65001 >NUL
CALL "%~dp0config.bat"
SET "CP=%~2"
IF "%CP%"=="" SET CP=65001
"%SQLCMDBIN%\sqlcmd.exe" %MSSQL% -f i:%CP%,o:65001 -W -i "%~1"
