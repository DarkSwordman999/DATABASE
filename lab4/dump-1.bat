@ECHO OFF
REM dump-1.bat - п.2.1: выгрузка базы BASE утилитой pg_dump в текстовый файл base_save
REM >pg_dump.exe BASE > base_save
CALL "%~dp0config.bat"
CD /D "%WORK%"
"%PGBIN%\pg_dump.exe" -E UTF8 %BASE% > base_save
FOR %%f IN (base_save) DO ECHO base_save: %%~zf байт
