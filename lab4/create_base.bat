@ECHO OFF
REM create_base.bat - формирование базы BASE (база ЛР1: таблицы и данные из DATA\SOURCE)
REM Используется, если база 4-го семестра не сохранилась (см. задание ЛР4)
CALL "%~dp0config.bat"
CD /D "%~dp0.."
"%PGBIN%\psql.exe" -q -X -d postgres -c "DROP DATABASE IF EXISTS %BASE%" -c "CREATE DATABASE %BASE% ENCODING 'UTF8' TEMPLATE template0"
"%PGBIN%\psql.exe" -q -X -P pager=off -d %BASE% -f DATA\create_tables >NUL
"%PGBIN%\psql.exe" -q -X -P pager=off -d %BASE% -f DATA\load_data
