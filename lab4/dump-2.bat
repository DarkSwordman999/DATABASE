@ECHO OFF
REM dump-2.bat - п.2.2: выгрузка базы BASE в однотомный rar-архив base_rar.rar
REM >pg_dump.exe BASE | rar a -si base_rar
REM (ключ -si: архивировать данные из stdin, файл в архиве получает имя stdin)
CALL "%~dp0config.bat"
CD /D "%WORK%"
IF EXIST base_rar.rar DEL base_rar.rar
"%PGBIN%\pg_dump.exe" -E UTF8 %BASE% | "%RAR%" a -si -inul base_rar
FOR %%f IN (base_rar.rar) DO ECHO base_rar.rar: %%~zf байт
