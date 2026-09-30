@ECHO OFF
REM copy_to_MS_SQL.bat - копирование всех таблиц базы sales из PostgreSQL в MS SQL Server
REM Предварительно: make_sel2.bat (сборка sel2.exe) и ..\s_TCP.bat COPY\create_DB (база SALES)
REM Для каждой таблицы: данные (pg_dump_data) -> структура (pg_dump_str) ->
REM создание таблицы в MS SQL Server (cr_ТАБЛИЦА.txt) -> загрузка данных (шаблон BULK_)
CHCP 65001 >NUL
SETLOCAL
CD /D "%~dp0"
SET "copydir=%~dp0"
FOR %%t IN (КАТЕГОРИЯ,КЛИЕНТ,МАГАЗИН,ПОСТАВКА,ПОСТАВЩИК,ПРОДАЖА,РАБОТА,РАЙОН,СОТРУДНИК,ТОВАР) DO (
  ECHO %%t
  CALL "%~dp0pg_dump_data.bat" %%t
  CALL "%~dp0pg_dump_str.bat" %%t
  CALL ..\s_TCP.bat cr_%%t.txt 1251
  SET table=%%t
  CALL ..\s_TCP.bat BULK_
)
