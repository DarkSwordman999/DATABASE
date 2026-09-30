@ECHO OFF
REM s.bat <сценарий> [D1 D2 P|alpha M|G [N]] - сценарий ЛР7 в MS SQL Server (через lab6\s.bat)
REM Пример: lab7\s.bat lab7\calculate1.sql 01.01.2021 30.06.2021 8.5 10.5 Иван
CALL "%~dp0..\lab6\s.bat" %*
