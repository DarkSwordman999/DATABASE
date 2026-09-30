@ECHO OFF
REM s.bat <сценарий> [arg1 [arg2 [arg3 [arg4 [arg5]]]]] - сценарий T-SQL с параметрами (ЛР6, ЛР7)
REM Пример: lab6\s.bat lab6\tasks\v20_task1.sql 21.08.2020 20.08.2023 мебель
REM sqlcmd не принимает пустые значения -v, поэтому к каждому параметру добавляется префикс «#»,
REM который сценарий отбрасывает: SUBSTRING(N'$(arg1)', 2, 100).
CHCP 65001 >NUL
CALL "%~dp0config.bat"
"%SQLCMDBIN%\sqlcmd.exe" %MSSQL% -d SALES -f 65001 -W -s " " -v arg1="#%~2" arg2="#%~3" arg3="#%~4" arg4="#%~5" arg5="#%~6" -i "%~1"
