@ECHO OFF
REM disp.bat - проверка копирования: число строк и первые записи каждой таблицы в MS SQL Server
CHCP 65001 >NUL
SETLOCAL
CD /D "%~dp0"
FOR %%t IN (КАТЕГОРИЯ,КЛИЕНТ,МАГАЗИН,ПОСТАВКА,ПОСТАВЩИК,ПРОДАЖА,РАБОТА,РАЙОН,СОТРУДНИК,ТОВАР) DO (
  SET table=%%t
  CALL ..\s_TCP.bat select_
)
