-- =====================================================================
-- ЛР3, вариант 20: k = mod15(20 - 1) + 1 = 5 - «Трёхмерный вектор»
-- Тип TYPE1:  vector3_ (x, y, z) - координаты вектора в R3
-- Домен:      vector3 - все координаты заданы (NOT NULL) и конечны
-- Операции:   сумма, разность, умножение на число (коммутативное), инверсия,
--             модуль, скалярное произведение, проекция одного вектора на другой,
--             проекция на ось координат, проекция на координатную плоскость
-- Запуск:     ./h lr3 20      s.bat lab3\v20_vector3.sql
-- =====================================================================
\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------
-- 2) создание и удаление типа
-- ---------------------------------------------------------------------
DROP TYPE IF EXISTS vector3_ CASCADE;

CREATE TYPE vector3_ AS (
  x float,   -- проекция на ось Ox
  y float,   -- проекция на ось Oy
  z float    -- проекция на ось Oz
);
\dT+ vector3_
DROP TYPE vector3_;          -- удаление типа (пока от него ничего не зависит)
\dT vector3_

CREATE TYPE vector3_ AS (
  x float,
  y float,
  z float
);

-- ---------------------------------------------------------------------
-- 3) домен: ограничение значений полей встроенного типа float
-- ---------------------------------------------------------------------
CREATE DOMAIN vector3 AS vector3_
  CHECK (    (VALUE).x IS NOT NULL AND (VALUE).y IS NOT NULL AND (VALUE).z IS NOT NULL
         AND (VALUE).x NOT IN ('NaN', 'Infinity', '-Infinity')
         AND (VALUE).y NOT IN ('NaN', 'Infinity', '-Infinity')
         AND (VALUE).z NOT IN ('NaN', 'Infinity', '-Infinity'));
\dD vector3

-- ---------------------------------------------------------------------
-- 4) «автономное» использование типа и домена
-- ---------------------------------------------------------------------
SELECT (1,2,3)::vector3_                       AS "значение типа";
SELECT ((1,2,3)::vector3).x                    AS x,
       ((1,2,3)::vector3).y                    AS y,
       ((1,2,3)::vector3).z                    AS z;
SELECT ((1,2,3)::vector3).*;
SELECT ROW(4,5,6)::vector3                     AS "из ROW",
       '(7,8,9)'::vector3                      AS "из строки";
SELECT (1,2,3)::vector3 AS v \gset
\echo 'переменная psql v =' :v
SELECT x, y, z FROM (SELECT ((1,2,3)::vector3).*) \gset
\echo 'координаты:' :x :y :z
SELECT ARRAY[x, y, z] AS "массив координат" FROM (SELECT ((1,2,3)::vector3).*);

-- тип без ограничений допускает неполный вектор, домен - нет (ожидаемые ошибки)
SELECT (1,NULL,3)::vector3_ AS "неполный vector3_";
\set ON_ERROR_STOP off
SELECT (1,NULL,3)::vector3 AS "неполный vector3";
SELECT (1,'NaN',3)::vector3 AS "NaN в vector3";
\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------
-- 5) тип и домен во временной таблице
-- ---------------------------------------------------------------------
CREATE TEMPORARY TABLE vectors (
  code  integer PRIMARY KEY,
  a     vector3 NOT NULL DEFAULT (0,0,0),
  b     vector3 NOT NULL DEFAULT (1,1,1)
);

INSERT INTO vectors (code) VALUES (1);
INSERT INTO vectors VALUES (2, (1,0,0), (0,1,0)),
                           (3, (3,4,0), (1,1,1)),
                           (4, ROW(1,2,2), '(2,-1,0)'),
                           (5, (-2,5,1.5), (4,0,-3));
INSERT INTO vectors
  SELECT 5 + i, (i, 2*i, -i)::vector3, (1, i, i*i)::vector3 FROM generate_series(1,3) AS i;
SELECT * FROM vectors ORDER BY code;
SELECT code, (a).x AS ax, (a).y AS ay, (a).z AS az FROM vectors WHERE (a).x > 0 ORDER BY code;
UPDATE vectors SET b = (0,0,1) WHERE code = 1;
UPDATE vectors SET a.z = 10 WHERE code = 2;      -- изменение отдельного атрибута
SELECT * FROM vectors WHERE code IN (1,2) ORDER BY code;

\set ON_ERROR_STOP off
INSERT INTO vectors VALUES (100, (1,2,NULL), (0,0,0));   -- нарушение домена
\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------
-- 6) функции-методы и операторы
-- ---------------------------------------------------------------------
-- сумма a + b -> vector3
CREATE OR REPLACE FUNCTION v3_add(a vector3, b vector3, OUT r vector3) AS $$
BEGIN
  r := ROW(a.x + b.x, a.y + b.y, a.z + b.z);
END $$ LANGUAGE plpgsql IMMUTABLE STRICT;
CREATE OPERATOR + (leftarg = vector3, rightarg = vector3, procedure = v3_add, commutator = +);

-- разность a - b -> vector3
CREATE OR REPLACE FUNCTION v3_sub(a vector3, b vector3, OUT r vector3) AS $$
BEGIN
  r := ROW(a.x - b.x, a.y - b.y, a.z - b.z);
END $$ LANGUAGE plpgsql IMMUTABLE STRICT;
CREATE OPERATOR - (leftarg = vector3, rightarg = vector3, procedure = v3_sub);

-- умножение на действительное число (коммутативное): k * a = a * k -> vector3
CREATE OR REPLACE FUNCTION v3_mul(k float, a vector3, OUT r vector3) AS $$
BEGIN
  r := ROW(k * a.x, k * a.y, k * a.z);
END $$ LANGUAGE plpgsql IMMUTABLE STRICT;
CREATE OR REPLACE FUNCTION v3_mul(a vector3, k float) RETURNS vector3 AS $$
  SELECT v3_mul(k, a)
$$ LANGUAGE sql IMMUTABLE STRICT;
CREATE OPERATOR * (leftarg = float, rightarg = vector3, procedure = v3_mul, commutator = *);
CREATE OPERATOR * (leftarg = vector3, rightarg = float, procedure = v3_mul, commutator = *);

-- инверсия: b = inv(a) = -a, a + b = 0 -> vector3
CREATE OR REPLACE FUNCTION v3_inv(a vector3) RETURNS vector3 AS $$
  SELECT ROW(0 - a.x, 0 - a.y, 0 - a.z)::vector3      -- 0 - x, чтобы не было «-0»
$$ LANGUAGE sql IMMUTABLE STRICT;
CREATE OPERATOR - (rightarg = vector3, procedure = v3_inv);

-- модуль |a| -> float (префиксный оператор @, как для встроенных числовых типов)
CREATE OR REPLACE FUNCTION v3_abs(a vector3) RETURNS float AS $$
  SELECT sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
$$ LANGUAGE sql IMMUTABLE STRICT;
CREATE OPERATOR @ (rightarg = vector3, procedure = v3_abs);

-- скалярное произведение a * b -> float
CREATE OR REPLACE FUNCTION v3_dot(a vector3, b vector3) RETURNS float AS $$
  SELECT a.x * b.x + a.y * b.y + a.z * b.z
$$ LANGUAGE sql IMMUTABLE STRICT;
CREATE OPERATOR * (leftarg = vector3, rightarg = vector3, procedure = v3_dot, commutator = *);

-- векторная проекция a на направление b: (a*b / |b|^2) * b -> vector3
CREATE OR REPLACE FUNCTION v3_proj(a vector3, b vector3) RETURNS vector3 AS $$
BEGIN
  IF v3_dot(b, b) = 0 THEN
    RAISE EXCEPTION 'проекция на нулевой вектор % не определена', b;
  END IF;
  RETURN v3_mul(v3_dot(a, b) / v3_dot(b, b), b);
END $$ LANGUAGE plpgsql IMMUTABLE STRICT;
CREATE OPERATOR ->> (leftarg = vector3, rightarg = vector3, procedure = v3_proj);

-- проекция на ось координат ('x' | 'y' | 'z') -> float
CREATE OR REPLACE FUNCTION v3_axis(a vector3, axis text) RETURNS float AS $$
BEGIN
  CASE lower(axis)
    WHEN 'x' THEN RETURN a.x;
    WHEN 'y' THEN RETURN a.y;
    WHEN 'z' THEN RETURN a.z;
    ELSE RAISE EXCEPTION 'неизвестная ось "%" (допустимо x, y, z)', axis;
  END CASE;
END $$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- проекция на координатную плоскость ('xy' | 'yz' | 'xz') -> vector3
CREATE OR REPLACE FUNCTION v3_plane(a vector3, plane text) RETURNS vector3 AS $$
BEGIN
  CASE lower(plane)
    WHEN 'xy', 'yx' THEN RETURN ROW(a.x, a.y, 0)::vector3;
    WHEN 'yz', 'zy' THEN RETURN ROW(0, a.y, a.z)::vector3;
    WHEN 'xz', 'zx' THEN RETURN ROW(a.x, 0, a.z)::vector3;
    ELSE RAISE EXCEPTION 'неизвестная плоскость "%" (допустимо xy, yz, xz)', plane;
  END CASE;
END $$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- округление координат до n знаков -> vector3 (для наглядного вывода; + 0 убирает «-0»)
CREATE OR REPLACE FUNCTION v3_round(a vector3, n int DEFAULT 4) RETURNS vector3 AS $$
  SELECT ROW(round(a.x::numeric, n)::float + 0,
             round(a.y::numeric, n)::float + 0,
             round(a.z::numeric, n)::float + 0)::vector3
$$ LANGUAGE sql IMMUTABLE STRICT;

\df v3_*
-- операторы, определённые для домена vector3
SELECT oprname AS "оператор", oprleft::regtype AS "левый", oprright::regtype AS "правый",
       oprresult::regtype AS "результат", oprcode AS "функция"
  FROM pg_operator WHERE 'vector3'::regtype IN (oprleft, oprright) ORDER BY oprname, oprleft, oprright;

-- ---------------------------------------------------------------------
-- демонстрация функций и операторов
-- ---------------------------------------------------------------------
SELECT (1,2,3)::vector3 + (4,5,6)::vector3   AS "a + b",
       (1,2,3)::vector3 - (4,5,6)::vector3   AS "a - b",
       2.5 * (1,2,3)::vector3                AS "2.5 * a",
       (1,2,3)::vector3 * 2.5                AS "a * 2.5",
       -(1,2,3)::vector3                     AS "-a",
       @ (3,4,12)::vector3                   AS "|a|";

SELECT code, a, b,
       a + b                          AS "a + b",
       a - b                          AS "a - b",
       -a                             AS "-a",
       a + (-a)                       AS "a + inv(a)",
       round((@ a)::numeric, 4)       AS "|a|",
       a * b                          AS "a * b",
       2 * a = a * 2                  AS "2a = a2"
  FROM vectors ORDER BY code;

SELECT code, a, b,
       v3_round(a ->> b)              AS "проекция a на b",
       v3_axis(a, 'x')                AS "a на Ox",
       v3_axis(a, 'z')                AS "a на Oz",
       v3_plane(a, 'xy')              AS "a на XY",
       v3_plane(b, 'yz')              AS "b на YZ"
  FROM vectors WHERE @ b > 0 ORDER BY code;

-- проверка: остаток a - proj(a, b) ортогонален b
SELECT code,
       round(((a - (a ->> b)) * b)::numeric, 10) AS "(a - proj) * b"
  FROM vectors WHERE @ b > 0 ORDER BY code;

-- сумма всех векторов a таблицы
SELECT (sum((a).x), sum((a).y), sum((a).z))::vector3 AS "сумма векторов a" FROM vectors;

-- ожидаемые ошибки
\set ON_ERROR_STOP off
SELECT (1,2,3)::vector3 ->> (0,0,0)::vector3;
SELECT v3_axis((1,2,3)::vector3, 'w');
\set ON_ERROR_STOP on
