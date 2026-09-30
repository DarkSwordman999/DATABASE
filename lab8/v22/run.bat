@ECHO OFF
REM run.bat [дата1 дата2 [поставщик]] - запуск программы ЛР8 варианта 22 (Python + pyodbc)
REM Пример: lab8\v22\run.bat 01.10.2021 31.01.2024 "ООО Турман"
REM Модуль pyodbc: pip install -r lab8\v22\requirements.txt
REM (если на системном диске нет места - pip install --target D:\PY_LIBS pyodbc; каталог подключается ниже)
CHCP 65001 >NUL
IF EXIST D:\PY_LIBS\pyodbc*.pyd SET "PYTHONPATH=D:\PY_LIBS;%PYTHONPATH%"
python "%~dp0lab08.py" %*
