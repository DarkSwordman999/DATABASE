@ECHO OFF
REM run_all.bat - ЛР4 целиком: копирование базы BASE и восстановление (пп. 1-10 задания)
REM Протокол: lab4\run_all.bat > results\lr4_protocol.txt   (или ./h lr4 all)
CALL "%~dp0config.bat"
SET "L=%~dp0"
SET "PSQL="%PGBIN%\psql.exe" -q -X -d postgres"

ECHO ===== 0. База BASE (%BASE%) из данных ЛР1
CALL "%L%create_base.bat"

ECHO ===== 1. Контрольные задачи в BASE: task0-01..03
CALL "%L%tasks.bat" 0

ECHO ===== 2. Выгрузка BASE утилитой pg_dump тремя способами
CALL "%L%dump-1.bat"
CALL "%L%dump-2.bat"
CALL "%L%dump-3.bat"

ECHO ===== 3. CREATE DATABASE BASE2
%PSQL% -c "DROP DATABASE IF EXISTS %BASE%2" -c "CREATE DATABASE %BASE%2"

ECHO ===== 4. psql BASE2 ^< base_save
CD /D "%WORK%"
"%PGBIN%\psql.exe" -q -X -d %BASE%2 < base_save >NUL

ECHO ===== 5. Контрольные задачи в BASE2: task2-01..03, сравнение fc
CALL "%L%tasks.bat" 2 %BASE%2
CD /D "%WORK%"
FOR %%n IN (01 02 03) DO fc task0-%%n task2-%%n
IF ERRORLEVEL 1 (ECHO РЕЗУЛЬТАТЫ РАЗЛИЧАЮТСЯ) ELSE (ECHO task2-* совпадают с task0-*)

ECHO ===== 6. DROP DATABASE BASE, BASE2
%PSQL% -c "DROP DATABASE %BASE%" -c "DROP DATABASE %BASE%2"
%PSQL% -c "SELECT datname FROM pg_database ORDER BY 1"

ECHO ===== 7. Извлечение base_rar.rar в текстовый файл stdin
CD /D "%WORK%"
IF EXIST stdin DEL stdin
"%RAR%" e -o+ -inul base_rar.rar
FOR %%f IN (stdin) DO ECHO stdin: %%~zf байт

ECHO ===== 8. CREATE DATABASE BASE
%PSQL% -c "CREATE DATABASE %BASE%"

ECHO ===== 9. psql BASE ^< stdin
CD /D "%WORK%"
"%PGBIN%\psql.exe" -q -X -d %BASE% < stdin >NUL

ECHO ===== 10. Контрольные задачи в восстановленной BASE: task3-01..03, сравнение fc
CALL "%L%tasks.bat" 3
CD /D "%WORK%"
FOR %%n IN (01 02 03) DO fc task0-%%n task3-%%n
IF ERRORLEVEL 1 (ECHO РЕЗУЛЬТАТЫ РАЗЛИЧАЮТСЯ) ELSE (ECHO task3-* совпадают с task0-*)

ECHO ===== Размеры файлов копий
CD /D "%WORK%"
FOR %%f IN (base_save base_rar.rar base_rarM.part*.rar stdin) DO ECHO %%~nxf  %%~zf байт
