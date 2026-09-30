@ECHO OFF
REM dll.bat <файл.dll> <файл1.obj> [<файл2.obj> ...] - сборка динамической библиотеки
SET "VS-DIR=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.33.31629"
SET "Win-Kits=C:\Program Files (x86)\Windows Kits\10"
SET "SDK=10.0.19041.0"
SET "PATH=%VS-DIR%\bin\HostX64\x64;C:\Windows\System32"
SET "LIB=%VS-DIR%\lib\x64;%Win-Kits%\Lib\%SDK%\um\x64;%Win-Kits%\Lib\%SDK%\ucrt\x64;C:\Program Files\PostgreSQL\18\lib"
link /nologo /DLL /out:%1 %2 %3 %4 %5 postgres.lib
