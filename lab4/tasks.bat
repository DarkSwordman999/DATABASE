@ECHO OFF
REM tasks.bat <N> [база] - контрольные прикладные задачи в базе (по умолчанию BASE)
REM с выводом результатов в файлы taskN-01, taskN-02, taskN-03 (каталог lab4\work)
REM   01 - вариант 20, задание 1: объём поставок по категории товара и кварталу
REM   02 - вариант 22, задание 1: выручка по поставщику и декаде месяца
REM   03 - вариант 22, задание 2: затраты клиентов по времени года и полу клиента
CALL "%~dp0config.bat"
SET "DB=%~2"
IF "%DB%"=="" SET "DB=%BASE%"
SET "ROOT=%~dp0.."
CD /D "%WORK%"
"%PGBIN%\psql.exe" -q -X -P footer=off -P pager=off -d %DB% -f "%ROOT%\tasks\v20_task1.sql" > task%1-01
"%PGBIN%\psql.exe" -q -X -P footer=off -P pager=off -d %DB% -f "%ROOT%\tasks\v22_task1.sql" > task%1-02
"%PGBIN%\psql.exe" -q -X -P footer=off -P pager=off -d %DB% -f "%ROOT%\tasks\v22_task2.sql" > task%1-03
ECHO Задачи решены в базе %DB%: task%1-01, task%1-02, task%1-03
