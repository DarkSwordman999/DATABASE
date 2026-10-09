-- Прервать запуск при неверных параметрах (big_db_indexes/def_config.sql, helper/check_db_one.sql).
-- \quit во вложенном \ir завершает только этот файл, поэтому обёртки ./h и ./help запускают
-- проверку (big_db_indexes/def_check_args.sql, helper/check_db.sql) с ON_ERROR_STOP: ошибка здесь
-- останавливает psql (код 3), и команда не выполняется
\set VERBOSITY terse
\set SHOW_CONTEXT never
DO $$ BEGIN RAISE EXCEPTION 'запуск прерван: неверные параметры'; END $$;
