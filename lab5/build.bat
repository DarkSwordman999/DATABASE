@ECHO OFF
REM build.bat 20|22 [каталог] - полная сборка библиотеки варианта:
REM   c1.bat vNN_f1.c, c1.bat vNN_f2.c -> dll.bat vNN.dll -> show1.bat vNN.dll
REM   и копирование vNN.dll в каталог, доступный серверу PostgreSQL (по умолчанию D:\PG_DLL).
REM Служба PostgreSQL работает от NETWORK SERVICE и не читает файлы из профиля пользователя,
REM поэтому библиотеку нужно разместить вне C:\Users (права: icacls D:\PG_DLL /grant "*S-1-5-20:(OI)(CI)RX").
SETLOCAL
CD /D "%~dp0"
SET "V=%~1"
IF "%V%"=="" SET "V=20"
SET "DST=%~2"
IF "%DST%"=="" SET "DST=D:\PG_DLL"
IF NOT EXIST build MKDIR build
CD build
CALL ..\c1.bat ..\v%V%_f1.c || EXIT /B 1
CALL ..\c1.bat ..\v%V%_f2.c || EXIT /B 1
CALL ..\dll.bat v%V%.dll v%V%_f1.obj v%V%_f2.obj || EXIT /B 1
CALL ..\show1.bat v%V%.dll
IF NOT EXIST "%DST%" MKDIR "%DST%"
COPY /Y v%V%.dll "%DST%\" >NUL && ECHO Библиотека скопирована: %DST%\v%V%.dll
