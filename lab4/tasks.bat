@ECHO OFF
REM tasks.bat <N> [база] - контрольные прикладные задачи варианта в базе (по умолчанию BASE)
REM с выводом результатов в файлы taskN-01, taskN-02, taskN-03 (каталог lab4\work)
REM Вариант - переменная LR4_VARIANT (20 или 22, задаётся в run_all.bat; по умолчанию 20):
REM   01 - задание 1 варианта из ЛР1 (tasks\vNN_task1.sql)
REM   02 - задание 2 варианта из ЛР1 (tasks\vNN_task2.sql)
REM   03 - контроль количества строк во всех таблицах (helper\counts.sql)
CALL "%~dp0config.bat"
SET "DB=%~2"
IF "%DB%"=="" SET "DB=%BASE%"
IF "%LR4_VARIANT%"=="" SET LR4_VARIANT=20
SET "ROOT=%~dp0.."
CD /D "%WORK%"
"%PGBIN%\psql.exe" -q -X -P footer=off -P pager=off -d %DB% -f "%ROOT%\tasks\v%LR4_VARIANT%_task1.sql" > task%1-01
"%PGBIN%\psql.exe" -q -X -P footer=off -P pager=off -d %DB% -f "%ROOT%\tasks\v%LR4_VARIANT%_task2.sql" > task%1-02
"%PGBIN%\psql.exe" -q -X -P footer=off -P pager=off -d %DB% -f "%ROOT%\helper\counts.sql" > task%1-03
ECHO Задачи варианта %LR4_VARIANT% решены в базе %DB%: task%1-01, task%1-02, task%1-03
