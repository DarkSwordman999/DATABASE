@ECHO OFF
REM help.cmd - запуск задач ПАБД из PowerShell или cmd: ./help <команда> [параметры]
REM Логика - в helper\help.ps1 (PowerShell-версия сценария h для Git Bash)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0helper\help.ps1" %*
