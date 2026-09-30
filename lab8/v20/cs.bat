@ECHO OFF
REM cs.bat [файл.cs] - компиляция программы на C# компилятором .NET Framework 4 (csc.exe)
REM Результат - Lab08.exe в каталоге lab8\v20
CD /D "%~dp0"
SET "SRC=%~1"
IF "%SRC%"=="" SET SRC=Lab08.cs
SET "PATH=C:\Windows\Microsoft.NET\Framework64\v4.0.30319;C:\Windows\System32"
SET LIBS=/reference:System.dll;System.Data.dll
SET csOPT=/nologo /warn:4 /optimize+ /target:exe /codepage:65001
csc.exe %csOPT% %LIBS% %SRC%
