@ECHO OFF
REM dump-3.bat [размер тома] - п.2.3: выгрузка базы BASE в многотомный rar-архив base_rarM
REM >pg_dump.exe BASE | rar a -si -v10k base_rarM
REM Размер тома подобран так, чтобы получилось 2-3 части (по умолчанию 8k для базы из ЛР1)
CALL "%~dp0config.bat"
CD /D "%WORK%"
SET "VOL=%~1"
IF "%VOL%"=="" SET VOL=8k
IF EXIST base_rarM.part*.rar DEL base_rarM.part*.rar
"%PGBIN%\pg_dump.exe" -E UTF8 %BASE% | "%RAR%" a -si -inul -v%VOL% base_rarM
FOR %%f IN (base_rarM.part*.rar) DO ECHO %%f: %%~zf байт
