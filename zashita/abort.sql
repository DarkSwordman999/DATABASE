-- Защита ЛР2: прервать запуск при неверных параметрах (вызывается из config.sql).
-- \quit во вложенном \ir завершает только этот файл, поэтому обёртка (./h, ./help zas)
-- запускает zashita/check_args.sql с ON_ERROR_STOP: ошибка здесь останавливает psql (код 3)
\set VERBOSITY terse
\set SHOW_CONTEXT never
DO $$ BEGIN RAISE EXCEPTION 'запуск прерван: неверные параметры'; END $$;
