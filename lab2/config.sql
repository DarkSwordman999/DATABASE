-- Выбор варианта ЛР2 по первому параметру (20 или 22, по умолчанию 20)
-- и загрузка его настроек из vNN_config.sql
-- Пример: ./help lr2 time 22  (arg1 = 22 - настройки из v22_config.sql)
\if :{?arg1} \else \set arg1 '' \endif
SELECT CASE WHEN :'arg1' IN ('20', '22') THEN :'arg1' ELSE '20' END AS variant \gset
\set cfg v :variant _config.sql
\ir :cfg
SELECT :'variant' = '20' AS is_v20 \gset
\set idx_name ПРОДАЖА_ :ref_fk _idx
