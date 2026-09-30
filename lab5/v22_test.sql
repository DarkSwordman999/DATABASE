-- =====================================================================
-- ЛР5, вариант 22: функции на C из библиотеки v22.dll
--   f1 = v22_cosd(x double [градус]) -> double    (список 1, k1 = 7: cosd)
--   f2 = v22_pos(s varchar, s1 varchar) -> int     (список 2, k2 = 8: номер символа,
--                                                   с которого s1 входит в s)
-- Сборка:  lab5\build.bat 22   (-> D:\PG_DLL\v22.dll)
-- Запуск:  ./h lr5 22 [каталог_dll]      s.bat lab5\v22_test.sql [каталог_dll]
-- =====================================================================
\set ON_ERROR_STOP on
\if :{?arg1} \else \set arg1 '' \endif
SELECT CASE WHEN :'arg1' > '' THEN :'arg1' ELSE 'D:/PG_DLL' END || '/v22.dll' AS dll \gset
\echo 'Библиотека:' :dll

-- спецификации STRICT-функций: при NULL-аргументе функция не вызывается, результат NULL
DROP FUNCTION IF EXISTS v22_cosd(float8);
CREATE FUNCTION v22_cosd(float8) RETURNS float8
  AS :'dll', 'f1_cosd'
  LANGUAGE C IMMUTABLE STRICT;

DROP FUNCTION IF EXISTS v22_pos(varchar, varchar);
CREATE FUNCTION v22_pos(varchar, varchar) RETURNS int
  AS :'dll', 'f2_pos'
  LANGUAGE C IMMUTABLE STRICT;

\df v22_*

-- таблица T с аргументами функций
DROP TABLE IF EXISTS t_lr5_v22;
CREATE TABLE t_lr5_v22 (
  n   int PRIMARY KEY,
  x   float8,          -- аргумент f1, градусы
  s   varchar(40),     -- 1-й аргумент f2
  s1  varchar(20)      -- 2-й аргумент f2
);
INSERT INTO t_lr5_v22 VALUES
  (1,   60,   'база данных sales',   'данных'),
  (2,  -90,   'ООО Кр. Вымпел',      'Вымпел'),
  (3,  135,   'abcabc',              'cab'),
  (4,  390,   'мебель',              'одежда'),
  (5,  NULL,  'пусто',               NULL);

-- демонстрация; справа - встроенные аналоги cosd() и position() для сверки
SELECT n,
       x,
       round(v22_cosd(x)::numeric, 10)          AS "f1: cosd(x)",
       round(cosd(x)::numeric, 10)              AS "встроенная cosd",
       s,
       s1,
       v22_pos(s, s1)                           AS "f2: pos(s, s1)",
       position(s1 IN s)                        AS "встроенная position"
  FROM t_lr5_v22
 ORDER BY n;

-- вызов с константами и проверка STRICT
SELECT v22_cosd(0) AS "cosd(0)", v22_cosd(60) AS "cosd(60)", v22_cosd(180) AS "cosd(180)",
       v22_cosd(-240) AS "cosd(-240)", v22_cosd(NULL) IS NULL AS "cosd(NULL) = NULL",
       v22_pos('Привет, мир', 'мир') AS "pos('Привет, мир','мир')",
       v22_pos('abc', '') AS "pos('abc','')";

-- ожидаемая ошибка: бесконечный угол
\set ON_ERROR_STOP off
SELECT v22_cosd('Infinity');
\set ON_ERROR_STOP on
