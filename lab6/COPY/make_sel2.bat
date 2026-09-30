@ECHO OFF
REM make_sel2.bat - сборка фильтра sel2.exe (sel2.cpp) компилятором MS Visual Studio 2022
CD /D "%~dp0"
SET "VS-DIR=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.33.31629"
SET "Win-Kits=C:\Program Files (x86)\Windows Kits\10"
SET "SDK=10.0.19041.0"
SET "PATH=%VS-DIR%\bin\HostX64\x64;C:\Windows\System32"
SET "INCLUDE=%VS-DIR%\include;%Win-Kits%\Include\%SDK%\ucrt;%Win-Kits%\Include\%SDK%\um;%Win-Kits%\Include\%SDK%\shared"
SET "LIB=%VS-DIR%\lib\x64;%Win-Kits%\Lib\%SDK%\um\x64;%Win-Kits%\Lib\%SDK%\ucrt\x64"
cl /nologo /EHsc /O2 sel2.cpp && DEL sel2.obj
