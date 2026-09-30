@ECHO OFF
REM show1.bat <файл.dll> - список функций, экспортируемых динамической библиотекой
SET "VS-DIR=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.33.31629"
SET "PATH=%VS-DIR%\bin\HostX64\x64;C:\Windows\System32"
dumpbin /nologo /EXPORTS %1
