-- Проверка параметров команд ./h и ./help по базе sales (перед запуском сценария)
-- arg1 arg2, arg3 arg4 - пары «тип значение» (до двух параметров), типы - из helper/args.txt
-- и helper/menu.txt: cat, cat~ (часть наименования), prov, prov#, goods, goods#, client#,
-- surname, emp, emp#, district# (# - код). При ошибке выводит её и допустимые значения;
-- обёртка запускает сценарий с ON_ERROR_STOP - psql завершается с кодом 3
-- Пример: ./help helper/check_db.sql cat мебель goods# 7
\set QUIET on
\if :{?arg1} \else \set arg1 '' \endif
\if :{?arg2} \else \set arg2 '' \endif
\if :{?arg3} \else \set arg3 '' \endif
\if :{?arg4} \else \set arg4 '' \endif
\pset footer off
\set t :arg1
\set v :arg2
\ir check_db_one.sql
\set t :arg3
\set v :arg4
\ir check_db_one.sql
