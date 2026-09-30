@ECHO OFF
REM c1.bat <файл.c> - компиляция функции PostgreSQL на C в объектный файл (.obj)
REM Пути к MS Visual Studio 2022, Windows Kits и PostgreSQL 18 - по установке на ПК
SET "VS-DIR=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.33.31629"
SET "Win-Kits=C:\Program Files (x86)\Windows Kits\10"
SET "SDK=10.0.19041.0"
SET "PGinc=C:\Program Files\PostgreSQL\18\include"
SET "PATH=%VS-DIR%\bin\HostX64\x64;C:\Windows\System32"
SET "INCLUDE=%VS-DIR%\include;%Win-Kits%\Include\%SDK%\ucrt;%Win-Kits%\Include\%SDK%\um;%Win-Kits%\Include\%SDK%\shared;%PGinc%;%PGinc%\server;%PGinc%\server\port\win32_msvc;%PGinc%\server\port\win32"
cl /nologo /c /TC /std:c17 /O2 /W3 /wd5105 /D_WIN64 /DWIN32 %1
