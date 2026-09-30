-- ЛР3, п.1: воспроизведение примеров из сценария cmplx (тип complex_ и домен complex)
-- Исправлены недочёты исходника: преждевременный \q, повторное создание оператора *.
-- Запуск: ./h lr3 cmplx      s.bat lab3\cmplx.sql
\set ON_ERROR_STOP on

-- 1) строковые значения (ROW) и разбор их текстового представления
SELECT ROW(1,2,3);
SELECT ROW(2,3,5) AS t \gset
\echo :t
SELECT substring(:'t', 2, length(:'t') - 2);
SELECT string_to_array(substring(:'t', 2, length(:'t') - 2), ',');
SELECT (string_to_array(substring(:'t', 2, length(:'t') - 2), ','))[2];

-- 2) составной тип complex_ и его автономное использование
DROP TYPE IF EXISTS complex_ CASCADE;
CREATE TYPE complex_ AS (
  x float,
  y float
);

SELECT (1,2)::complex_;
SELECT ((1,2)::complex_).x;
SELECT ((1,2)::complex_).y;
SELECT ((1,2)::complex_).*;
SELECT x, y FROM (SELECT ((1,2)::complex_).*) \gset
\echo :x
\echo :y
SELECT ARRAY[x, y] FROM (SELECT ((1,2)::complex_).*);
SELECT (2,1)::complex_ AS val1 \gset
SELECT string_to_array(substring(:'val1', 2, length(:'val1') - 2), ',');

-- домен поверх составного типа: ограничение CHECK, недопустимое в CREATE TYPE
CREATE DOMAIN complex AS complex_
  CHECK ((VALUE).x >= 0);

-- 3) использование домена во временной таблице
CREATE TEMPORARY TABLE tmp (
  code  integer,
  z     complex NULL DEFAULT (0,0)
);

INSERT INTO tmp VALUES (1, (1,2));
INSERT INTO tmp
  SELECT x + 1, CASE WHEN x > 3 THEN (1,1)::complex ELSE (0,0)::complex END
  FROM generate_series(1,5) AS x;
INSERT INTO tmp SELECT x + 6, (x,x)::complex FROM generate_series(1,5) AS x;
SELECT * FROM tmp ORDER BY code;

-- нарушение ограничения домена (x < 0) - ожидаемая ошибка
\set ON_ERROR_STOP off
INSERT INTO tmp VALUES (99, (-1,0));
\set ON_ERROR_STOP on

-- 4) функции и операторы для домена complex
CREATE OR REPLACE FUNCTION complex_add(z1 complex, z2 complex, OUT z complex) AS $$
BEGIN
  z.x := z1.x + z2.x;
  z.y := z1.y + z2.y;
END;
$$ LANGUAGE plpgsql;

SELECT z, complex_add(z, z) FROM tmp;

CREATE OPERATOR + (
  leftarg = complex,
  rightarg = complex,
  procedure = complex_add
);

CREATE OR REPLACE FUNCTION complex_mulRL(a float, z1 complex, OUT z complex) AS $$
BEGIN
  z.x := a * z1.x;
  z.y := a * z1.y;
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR * (
  leftarg = float,
  rightarg = complex,
  procedure = complex_mulRL
);

CREATE OR REPLACE FUNCTION complex_mulRR(z1 complex, a float, OUT z complex) AS $$
BEGIN
  z.x := a * z1.x;
  z.y := a * z1.y;
END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR * (
  leftarg = complex,
  rightarg = float,
  procedure = complex_mulRR
);

SELECT z, z + z AS sum FROM tmp;
SELECT z, z + (1,-1)::complex AS sum FROM tmp;
SELECT z, z + '(1,-1)' AS sum FROM tmp;
SELECT z, z + ROW(1,-1) AS sum FROM tmp;
SELECT z, 2 * z AS prod1 FROM tmp;
SELECT z, z * 2 AS prod2 FROM tmp;
-- операторы сравнения = и <> для составных типов существуют по умолчанию
SELECT z, z = 2 * z AS equ FROM tmp;
SELECT z, z != z AS notequ FROM tmp;
