-- =====================================================================
-- ЛР5, вариант 20: функции на C из библиотеки v20.dll
--   f1 = v20_floor(x double) -> int          (список 1, k1 = 5: floor)
--   f2 = v20_alltrim(s varchar) -> varchar   (список 2, k2 = 6: ALLTRIM)
-- Сборка:  lab5\build.bat 20   (-> D:\PG_DLL\v20.dll)
-- Запуск:  ./h lr5 20 [каталог_dll]      s.bat lab5\v20_test.sql [каталог_dll]
-- =====================================================================
\set ON_ERROR_STOP on
\if :{?arg1} \else \set arg1 '' \endif
SELECT CASE WHEN :'arg1' > '' THEN :'arg1' ELSE 'D:/PG_DLL' END || '/v20.dll' AS dll \gset
\echo 'Библиотека:' :dll

-- спецификации STRICT-функций: при NULL-аргументе функция не вызывается, результат NULL
DROP FUNCTION IF EXISTS v20_floor(float8);
CREATE FUNCTION v20_floor(float8) RETURNS int
  AS :'dll', 'f1_floor'
  LANGUAGE C IMMUTABLE STRICT;

DROP FUNCTION IF EXISTS v20_alltrim(varchar);
CREATE FUNCTION v20_alltrim(varchar) RETURNS varchar
  AS :'dll', 'f2_alltrim'
  LANGUAGE C IMMUTABLE STRICT;

\df v20_*

-- таблица T с аргументами функций
DROP TABLE IF EXISTS t_lr5_v20;
CREATE TABLE t_lr5_v20 (
  n  int PRIMARY KEY,
  x  float8,          -- аргумент f1
  s  varchar(40)      -- аргумент f2
);
INSERT INTO t_lr5_v20 VALUES
  (1,  3.7,    '   Иванов Иван   '),
  (2, -3.2,    E'\t Товар\t№ 5 \t'),
  (3,  5.0,    'без пробелов'),
  (4, -0.5,    E' \t \t '),
  (5,  NULL,   NULL);

-- демонстрация: [ ] показывают границы строк; справа - встроенные аналоги для сверки
SELECT n,
       x,
       v20_floor(x)                          AS "f1: floor(x)",
       floor(x)::int                         AS "встроенная floor",
       '[' || s || ']'                       AS "s",
       '[' || v20_alltrim(s) || ']'          AS "f2: alltrim(s)",
       v20_alltrim(s) = btrim(s, E' \t')     AS "= btrim",
       length(v20_alltrim(s))                AS "длина"
  FROM t_lr5_v20
 ORDER BY n;

-- вызов с константами и проверка STRICT
SELECT v20_floor(2.999) AS "floor(2.999)", v20_floor(-2.001) AS "floor(-2.001)",
       v20_floor(NULL) IS NULL AS "floor(NULL) = NULL",
       '[' || v20_alltrim('  a b  ') || ']' AS "alltrim('  a b  ')";

-- ожидаемая ошибка: результат вне диапазона int
\set ON_ERROR_STOP off
SELECT v20_floor(1e12);
\set ON_ERROR_STOP on
