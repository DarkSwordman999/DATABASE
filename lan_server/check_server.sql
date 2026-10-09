-- ЛР1: проверка подключения к серверу PostgreSQL в локальной сети (./help srv check)
-- Показывает, к какому серверу, базе и под каким пользователем выполнено подключение,
-- и количество строк в таблицах базы SALES на этом сервере.
\set QUIET on
\echo
\echo '=== Подключение к серверу PostgreSQL ==='
\set QUIET off
SELECT inet_server_addr()   AS "адрес сервера",
       inet_server_port()   AS "порт",
       current_database()   AS "база",
       current_user         AS "пользователь",
       inet_client_addr()   AS "адрес клиента",
       split_part(version(), ',', 1) AS "версия";
\set QUIET on
\echo
\echo '=== Таблицы базы на сервере ==='
\set QUIET off
\ir ../helper/counts.sql
