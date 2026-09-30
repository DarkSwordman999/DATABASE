@ECHO OFF
REM config.bat - параметры подключения для ЛР6/ЛР7 (вызывается остальными командными файлами)
REM Источник - PostgreSQL (база sales), приёмник - MS SQL Server (база SALES)
SET PGHOST=localhost
SET PGPORT=5432
SET PGUSER=postgres
SET PGDATABASE=sales
SET "PGBIN=C:\Program Files\PostgreSQL\18\bin"
REM MS SQL Server: локальный экземпляр LocalDB с Windows-аутентификацией.
REM Для сервера в локальной сети (SQL Server Express, TCP-порт 1433, SQL-аутентификация):
REM SET "MSSQL=-S 192.168.1.41\SQLEXPRESS,1433 -U sa -P 234"
SET "MSSQL=-S (localdb)\MSSQLLocalDB -E"
SET "SQLCMDBIN=C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn"
