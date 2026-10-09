-- =====================================================================
-- Защита ЛР3, вариант 22: для рационального числа x = a/b (тип rational) задано
--   -x = b/a, если a <> 0, и -x = 0/1, если a = 0 (обратное число);
--   показывается, что (-x)*x и x*(-x) равны 1 (a <> 0) или 0 (a = 0).
--   -x из задания - функция rat_inv и префиксный оператор ~ (оператор - у типа rational
--   уже означает смену знака: -(3/4) = -3/4).
-- Параметры: arg1, arg2 - целые a и b (b <> 0, |a|, |b| <= 2^53), по умолчанию 3 и 4
-- Запуск:    ./help lr3 def 22 [a b]   (тип создаёт lab3/v22_rational.sql)
-- Пример:    ./help lr3 def 22 -3 4      ./help lr3 def 22 0 7
-- =====================================================================
\set QUIET on
SET client_min_messages TO warning;
\if :{?arg1} \else \set arg1 '' \endif
\if :{?arg2} \else \set arg2 '' \endif
SELECT coalesce(nullif(:'arg1', ''), '3') AS pa, coalesce(nullif(:'arg2', ''), '4') AS pb \gset
-- проверка параметров: целые числа домена rational, b <> 0 (сначала формат, затем значения)
SELECT CASE WHEN :'pa' !~ '^[+-]?[0-9]+$' THEN format('a «%s» - нужно целое число', :'pa')
            WHEN :'pb' !~ '^[+-]?[0-9]+$' THEN format('b «%s» - нужно целое число', :'pb')
            ELSE '' END AS err \gset
SELECT :'err' = '' AS fmt_ok \gset
\if :fmt_ok
SELECT CASE WHEN abs(:'pa'::numeric) > 9007199254740992 OR abs(:'pb'::numeric) > 9007199254740992
              THEN 'a и b по модулю не больше 2^53 = 9007199254740992 (ограничение домена rational)'
            WHEN :'pb'::numeric = 0 THEN 'знаменатель b не может быть равен 0'
            ELSE '' END AS err \gset
\endif
SELECT :'err' <> '' AS bad \gset
\if :bad
    \echo 'ОШИБКА:' :err
    \echo 'Пример: ./help lr3 def 22 3 4      ./help lr3 def 22 0 7'
    \ir ../helper/abort.sql
\endif

-- -x из задания: b/a при a <> 0, 0/1 при a = 0 -> rational
CREATE OR REPLACE FUNCTION rat_inv(x rational) RETURNS rational AS $$
  SELECT CASE WHEN x.a = 0 THEN rat(0) ELSE rat(x.b, x.a) END
$$ LANGUAGE sql IMMUTABLE STRICT;
-- запись 'a/b' целыми числами без экспоненты (для крайних значений домена) -> text
CREATE OR REPLACE FUNCTION def_str(x rational) RETURNS text AS $$
  SELECT CASE WHEN n.b = 1 THEN n.a::bigint::text ELSE n.a::bigint || '/' || n.b::bigint END
    FROM (SELECT (rat_norm(x)).*) AS n
$$ LANGUAGE sql IMMUTABLE STRICT;
DROP OPERATOR IF EXISTS ~ (NONE, rational);
CREATE OPERATOR ~ (rightarg = rational, procedure = rat_inv);
\set QUIET off

\echo '=============================================================================='
\echo 'ВАРИАНТ 22. x = a/b, -x = b/a (a <> 0) или 0/1 (a = 0); (-x)*x и x*(-x) = 1 или 0'
\echo '=============================================================================='
\echo 'Функции и оператор (файл lab3/def_v22_inverse.sql; rat_mul - lab3/v22_rational.sql):'
\sf rat_inv
\sf rat_mul
SELECT oprname AS "оператор", oprleft::regtype AS "левый", oprright::regtype AS "правый",
       oprresult::regtype AS "результат", oprcode AS "функция"
  FROM pg_operator WHERE oprname IN ('~', '-', '*') AND oprright = 'rational'::regtype
   AND oprleft IN (0, 'rational'::regtype) ORDER BY 1, 2;

\set h1 '1) Заданное число: a = ' :pa ', b = ' :pb
\echo :h1
SELECT def_str(x) AS "x = a/b", def_str(~x) AS "-x", def_str(-x) AS "смена знака (не -x)",
       def_str((~x) * x) AS "(-x)*x", def_str(x * (~x)) AS "x*(-x)",
       CASE WHEN (x).a = 0 THEN '0' ELSE '1' END AS "ожидается",
       def_str((~x) * x) = CASE WHEN (x).a = 0 THEN '0' ELSE '1' END
         AND def_str(x * (~x)) = CASE WHEN (x).a = 0 THEN '0' ELSE '1' END AS "верно"
  FROM (SELECT rat(:'pa'::float, :'pb'::float) AS x) t;

\echo '2) Набор чисел: положительные, отрицательные, ноль, целые, ненормализованные, крайние'
\echo '   значения домена (|a|, |b| до 2^53)'
\set QUIET on
CREATE TEMP TABLE def_nums (№ serial, a float, b float);
INSERT INTO def_nums (a, b) VALUES
  (3, 4), (-3, 4), (3, -4), (0, 5), (0, -7), (7, 1), (1, 9), (6, 8), (-10, -4), (22, 7),
  (9007199254740991, 2), (-9007199254740992, 9007199254740991), (1, 9007199254740992);
\set QUIET off
SELECT №, a::bigint AS a, b::bigint AS b, def_str(rat(a, b)) AS "x", def_str(~rat(a, b)) AS "-x",
       def_str((~rat(a, b)) * rat(a, b)) AS "(-x)*x",
       def_str(rat(a, b) * (~rat(a, b))) AS "x*(-x)",
       CASE WHEN a = 0 THEN '0' ELSE '1' END AS "ожидается"
  FROM def_nums ORDER BY №;

\echo '3) Проверка на 10 000 случайных дробей a/b домена rational (каждое 10-е a = 0)'
SELECT count(*) AS "дробей",
       count(*) FILTER (WHERE a = 0) AS "из них a = 0",
       count(*) FILTER (WHERE p1 == rat(1) AND p2 == rat(1)) AS "(-x)*x = x*(-x) = 1",
       count(*) FILTER (WHERE p1 == rat(0) AND p2 == rat(0)) AS "(-x)*x = x*(-x) = 0",
       count(*) FILTER (WHERE NOT ((a <> 0 AND p1 == rat(1) AND p2 == rat(1))
                                OR (a = 0 AND p1 == rat(0) AND p2 == rat(0)))) AS "ошибок"
  FROM (SELECT a, (~x) * x AS p1, x * (~x) AS p2
          FROM (SELECT a, rat(a, b) AS x
                  FROM (SELECT CASE WHEN i % 10 = 0 THEN 0
                                    ELSE floor(random() * 18014398509481984) - 9007199254740992 END AS a,
                               CASE WHEN r = 0 THEN 1 ELSE r END AS b
                          FROM (SELECT i, floor(random() * 18014398509481984) - 9007199254740992 AS r
                                  FROM generate_series(1, 10000) AS i) s) t) u) v;
\echo 'Итог: при a <> 0 произведения (-x)*x и x*(-x) равны 1, при a = 0 - равны 0;'
\echo 'порядок множителей результат не меняет.'
