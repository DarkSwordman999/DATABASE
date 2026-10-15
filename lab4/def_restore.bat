@ECHO OFF
REM def_restore.bat <20|22> - защита ЛР4: удаление базы BASE и восстановление её из архива
REM   в.20 - из однотомного rar-архива base_rar.rar (создаёт dump-2.bat),
REM   в.22 - из многотомного rar-архива base_rarM.part*.rar (создаёт dump-3.bat);
REM затем прикладная задача варианта в восстановленной базе:
REM   в.20 - задача 1 (tasks\v20_task1.sql), в.22 - задача 2 (tasks\v22_task2.sql)
REM LR4_DEF_NOTASK=1 - задачу не решать (./h lr4 def и ./help lr4 def решают её сами,
REM с параметрами пользователя)
CALL "%~dp0config.bat"
SET "V=%~1"
SET "ARC="
IF "%V%"=="20" (SET "ARC=base_rar.rar" & SET "MASK=base_rar.rar" & SET "T=1" & SET "KIND=однотомного")
IF "%V%"=="22" (SET "ARC=base_rarM.part1.rar" & SET "MASK=base_rarM.part*.rar" & SET "T=2" & SET "KIND=многотомного")
IF "%ARC%"=="" (ECHO ОШИБКА: укажите вариант 20 или 22 & EXIT /B 1)
SET "ROOT=%~dp0.."
SET "PSQL="%PGBIN%\psql.exe" -q -X -d postgres"
CD /D "%WORK%"
IF NOT EXIST "%ARC%" (ECHO ОШИБКА: нет архива %WORK%\%ARC% - создайте копию: ./h lr4 dump2 или ./h lr4 dump3 & EXIT /B 1)
ECHO Защита ЛР4, вариант %V%: восстановление базы %BASE% из %KIND% rar-архива

ECHO ===== 1. Архив копии базы %BASE% (каталог %WORK%)
FOR %%f IN (%MASK%) DO ECHO %%f  %%~zf байт  %%~tf

ECHO ===== 2. DROP DATABASE %BASE%
%PSQL% -c "DROP DATABASE IF EXISTS %BASE% WITH (FORCE)"
%PSQL% -c "SELECT datname FROM pg_database ORDER BY 1"

ECHO ===== 3. Извлечение %ARC% в текстовый файл stdin
IF EXIST stdin DEL stdin
"%RAR%" e -o+ -inul %ARC%
IF NOT EXIST stdin (ECHO ОШИБКА: файл stdin не извлечён из %ARC% & EXIT /B 1)
FOR %%f IN (stdin) DO ECHO stdin: %%~zf байт

ECHO ===== 4. CREATE DATABASE %BASE%, psql %BASE% ^< stdin
%PSQL% -c "CREATE DATABASE %BASE%"
"%PGBIN%\psql.exe" -q -X -d %BASE% < stdin >NUL
%PSQL% -c "SELECT datname FROM pg_database ORDER BY 1"
"%PGBIN%\psql.exe" -q -X -P pager=off -d %BASE% -f "%ROOT%\helper\counts.sql"

ECHO ===== 5. Прикладная задача %T% варианта %V% в восстановленной базе %BASE%
IF "%LR4_DEF_NOTASK%"=="1" EXIT /B 0
"%PGBIN%\psql.exe" -q -X -P pager=off -d %BASE% -f "%ROOT%\tasks\v%V%_task%T%.sql"
