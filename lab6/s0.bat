@ECHO OFF
REM s0.bat - интерактивная консоль sqlcmd, подключение к серверу MS SQL Server
CHCP 65001 >NUL
CALL "%~dp0config.bat"
"%SQLCMDBIN%\sqlcmd.exe" %MSSQL% -f 65001
