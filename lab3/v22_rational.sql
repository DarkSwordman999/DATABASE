-- =====================================================================
-- ЛР3, вариант 22: k = mod15(22 - 1) + 1 = 7
-- «Рациональное число (вида a/b) с целыми числами типа double»
-- Тип TYPE1:  rational_ (a, b) - числитель и знаменатель (double precision)
-- Домен:      rational - a и b заданы, целые (без дробной части), конечны,
--             |a|, |b| <= 2^53 (точное представление целых в double), b <> 0
-- Операции:   конструктор из 2-х чисел (a и b), конструктор из одного целого числа,
--             нормализация (сокращение на общий множитель),
--             арифметические операции (+, -, *, /) с рациональными числами,
--             умножение на целое, а также: смена знака, значение в виде float,
--             текстовая запись 'a/b', сравнение
-- Запуск:     ./h lr3 22      s.bat lab3\v22_rational.sql
-- =====================================================================
\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------
-- 2) создание и удаление типа
-- ---------------------------------------------------------------------
DROP TYPE IF EXISTS rational_ CASCADE;

CREATE TYPE rational_ AS (
  a float,   -- числитель
  b float    -- знаменатель
);
\dT+ rational_
DROP TYPE rational_;         -- удаление типа (пока от него ничего не зависит)
\dT rational_

CREATE TYPE rational_ AS (
  a float,
  b float
);

-- ---------------------------------------------------------------------
-- 3) домен: ограничение значений полей встроенного типа float
-- ---------------------------------------------------------------------
CREATE DOMAIN rational AS rational_
  CHECK (    (VALUE).a IS NOT NULL AND (VALUE).b IS NOT NULL
         AND (VALUE).a = trunc((VALUE).a) AND (VALUE).b = trunc((VALUE).b)
         AND abs((VALUE).a) <= 9007199254740992 AND abs((VALUE).b) <= 9007199254740992
         AND (VALUE).b <> 0);
\dD rational

-- ---------------------------------------------------------------------
-- 4) «автономное» использование типа и домена
-- ---------------------------------------------------------------------
SELECT (1,2)::rational_                        AS "значение типа";
SELECT ((3,4)::rational).a AS "числитель", ((3,4)::rational).b AS "знаменатель";
SELECT ((3,4)::rational).*;
SELECT ROW(5,6)::rational AS "из ROW", '(7,8)'::rational AS "из строки";
SELECT (2,3)::rational AS r \gset
\echo 'переменная psql r =' :r
SELECT a, b FROM (SELECT ((2,3)::rational).*) \gset
\echo 'числитель' :a ', знаменатель' :b
SELECT string_to_array(substring(:'r', 2, length(:'r') - 2), ',') AS "массив из текста";

-- тип допускает любые float, домен - нет (ожидаемые ошибки)
SELECT (1.5,0)::rational_ AS "некорректный rational_";
\set ON_ERROR_STOP off
SELECT (1,0)::rational   AS "нулевой знаменатель";
SELECT (1.5,2)::rational AS "дробный числитель";
SELECT (NULL,2)::rational AS "нет числителя";
\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------
-- 6) функции-методы и операторы (объявляются до таблицы, т.к. rat()
--    используется в её DEFAULT)
-- ---------------------------------------------------------------------
-- наибольший общий делитель целых чисел, записанных в double (алгоритм Евклида)
CREATE OR REPLACE FUNCTION rat_gcd(x float, y float) RETURNS float AS $$
DECLARE t numeric;
        p numeric := abs(x::numeric);
        q numeric := abs(y::numeric);
BEGIN
  WHILE q <> 0 LOOP
    t := mod(p, q); p := q; q := t;
  END LOOP;
  RETURN p;
END $$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- нормализация: сокращение на НОД, знак - в числителе (b > 0) -> rational
CREATE OR REPLACE FUNCTION rat_norm(r rational) RETURNS rational AS $$
DECLARE g float := rat_gcd(r.a, r.b) * sign(r.b);
BEGIN
  RETURN ROW(r.a / g + 0, r.b / g)::rational;         -- + 0 убирает «-0»
END $$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- конструктор из 2-х чисел a и b (результат нормализован) -> rational
CREATE OR REPLACE FUNCTION rat(a float, b float) RETURNS rational AS $$
  SELECT rat_norm(ROW(a, b)::rational)
$$ LANGUAGE sql IMMUTABLE STRICT;

-- конструктор из одного целого числа n -> n/1 -> rational
CREATE OR REPLACE FUNCTION rat(n bigint) RETURNS rational AS $$
  SELECT ROW(n, 1)::rational
$$ LANGUAGE sql IMMUTABLE STRICT;

-- арифметические операции: a1/b1 (+ - * /) a2/b2 -> rational
CREATE OR REPLACE FUNCTION rat_add(x rational, y rational) RETURNS rational AS $$
  SELECT rat(x.a * y.b + y.a * x.b, x.b * y.b)
$$ LANGUAGE sql IMMUTABLE STRICT;
CREATE OPERATOR + (leftarg = rational, rightarg = rational, procedure = rat_add, commutator = +);

CREATE OR REPLACE FUNCTION rat_sub(x rational, y rational) RETURNS rational AS $$
  SELECT rat(x.a * y.b - y.a * x.b, x.b * y.b)
$$ LANGUAGE sql IMMUTABLE STRICT;
CREATE OPERATOR - (leftarg = rational, rightarg = rational, procedure = rat_sub);

CREATE OR REPLACE FUNCTION rat_mul(x rational, y rational) RETURNS rational AS $$
  SELECT rat(x.a * y.a, x.b * y.b)
$$ LANGUAGE sql IMMUTABLE STRICT;
CREATE OPERATOR * (leftarg = rational, rightarg = rational, procedure = rat_mul, commutator = *);

CREATE OR REPLACE FUNCTION rat_div(x rational, y rational) RETURNS rational AS $$
BEGIN
  IF y.a = 0 THEN
    RAISE EXCEPTION 'деление на нулевое рациональное число %/%', y.a, y.b;
  END IF;
  RETURN rat(x.a * y.b, x.b * y.a);
END $$ LANGUAGE plpgsql IMMUTABLE STRICT;
CREATE OPERATOR / (leftarg = rational, rightarg = rational, procedure = rat_div);

-- умножение на целое (коммутативное): r * n = n * r -> rational
CREATE OR REPLACE FUNCTION rat_mul_int(x rational, n bigint) RETURNS rational AS $$
  SELECT rat(x.a * n, x.b)
$$ LANGUAGE sql IMMUTABLE STRICT;
CREATE OR REPLACE FUNCTION rat_mul_int(n bigint, x rational) RETURNS rational AS $$
  SELECT rat_mul_int(x, n)
$$ LANGUAGE sql IMMUTABLE STRICT;
CREATE OPERATOR * (leftarg = rational, rightarg = bigint, procedure = rat_mul_int, commutator = *);
CREATE OPERATOR * (leftarg = bigint, rightarg = rational, procedure = rat_mul_int, commutator = *);

-- смена знака -r -> rational
CREATE OR REPLACE FUNCTION rat_neg(x rational) RETURNS rational AS $$
  SELECT rat(0 - x.a, x.b)
$$ LANGUAGE sql IMMUTABLE STRICT;
CREATE OPERATOR - (rightarg = rational, procedure = rat_neg);

-- значение дроби a/b -> float
CREATE OR REPLACE FUNCTION rat_value(x rational) RETURNS float AS $$
  SELECT x.a / x.b
$$ LANGUAGE sql IMMUTABLE STRICT;

-- текстовая запись 'a/b' (целое - без знаменателя) -> text
CREATE OR REPLACE FUNCTION rat_str(x rational) RETURNS text AS $$
  SELECT CASE WHEN n.b = 1 THEN n.a::text ELSE n.a || '/' || n.b END
    FROM (SELECT (rat_norm(x)).*) AS n
$$ LANGUAGE sql IMMUTABLE STRICT;

-- сравнение по значению (1/2 и 2/4 равны): == и <, >
CREATE OR REPLACE FUNCTION rat_eq(x rational, y rational) RETURNS boolean AS $$
  SELECT x.a * y.b = y.a * x.b
$$ LANGUAGE sql IMMUTABLE STRICT;
CREATE OPERATOR == (leftarg = rational, rightarg = rational, procedure = rat_eq, commutator = ==);

CREATE OR REPLACE FUNCTION rat_lt(x rational, y rational) RETURNS boolean AS $$
  SELECT rat_value(x) < rat_value(y)
$$ LANGUAGE sql IMMUTABLE STRICT;
CREATE OPERATOR < (leftarg = rational, rightarg = rational, procedure = rat_lt, commutator = >);

CREATE OR REPLACE FUNCTION rat_gt(x rational, y rational) RETURNS boolean AS $$
  SELECT rat_value(x) > rat_value(y)
$$ LANGUAGE sql IMMUTABLE STRICT;
CREATE OPERATOR > (leftarg = rational, rightarg = rational, procedure = rat_gt, commutator = <);

\df rat*
-- операторы, определённые для домена rational
SELECT oprname AS "оператор", oprleft::regtype AS "левый", oprright::regtype AS "правый",
       oprresult::regtype AS "результат", oprcode AS "функция"
  FROM pg_operator WHERE 'rational'::regtype IN (oprleft, oprright) ORDER BY oprname, oprleft, oprright;

-- ---------------------------------------------------------------------
-- 5) тип и домен во временной таблице
-- ---------------------------------------------------------------------
CREATE TEMPORARY TABLE fractions (
  code  integer PRIMARY KEY,
  x     rational NOT NULL DEFAULT rat(0),
  y     rational NOT NULL DEFAULT rat(1)
);

INSERT INTO fractions (code) VALUES (1);
INSERT INTO fractions VALUES (2, (1,2), (1,3)),
                             (3, rat(6,8), rat(-10,4)),
                             (4, ROW(7,1), '(2,-6)'),
                             (5, rat(5), (22,7));
INSERT INTO fractions
  SELECT 5 + i, rat(i, i + 1), rat(i * i, 12) FROM generate_series(1,3) AS i;
SELECT code, x, y, rat_str(x) AS "x", rat_str(y) AS "y" FROM fractions ORDER BY code;
UPDATE fractions SET y.b = 5 WHERE code = 1;               -- изменение отдельного атрибута
UPDATE fractions SET x = rat_norm(x), y = rat_norm(y);     -- нормализация хранимых значений
SELECT code, x, y FROM fractions WHERE (y).b > 1 ORDER BY code;

\set ON_ERROR_STOP off
INSERT INTO fractions VALUES (100, (1,0), (1,1));          -- нарушение домена
\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------
-- демонстрация функций и операторов
-- ---------------------------------------------------------------------
SELECT rat(6, 8)                    AS "rat(6,8)",
       rat(-10, -4)                 AS "rat(-10,-4)",
       rat(3, -9)                   AS "rat(3,-9)",
       rat(5)                       AS "rat(5)",
       rat_norm((12,18))            AS "norm(12/18)",
       rat_gcd(84, 36)              AS "НОД(84,36)";

SELECT rat_str((1,2)::rational + (1,3)) AS "1/2 + 1/3",
       rat_str((1,2)::rational - (1,3)) AS "1/2 - 1/3",
       rat_str((2,3)::rational * (9,4)) AS "2/3 * 9/4",
       rat_str((2,3)::rational / (4,9)) AS "2/3 / 4/9",
       rat_str((5,6)::rational * 3)     AS "5/6 * 3",
       rat_str(4 * (3,8)::rational)     AS "4 * 3/8",
       rat_str(-(3,4)::rational)        AS "-(3/4)";

SELECT code, rat_str(x) AS "x", rat_str(y) AS "y",
       rat_str(x + y) AS "x + y",
       rat_str(x - y) AS "x - y",
       rat_str(x * y) AS "x * y",
       CASE WHEN (y).a <> 0 THEN rat_str(x / y) END AS "x / y",
       rat_str(x * 2) AS "x * 2",
       round(rat_value(x + y)::numeric, 6) AS "x + y (float)",
       x < y AS "x < y"
  FROM fractions ORDER BY code;

-- проверки: (x + y) - y == x, (x * y) / y == x, 1/2 == 2/4
SELECT code,
       (x + y) - y == x                                   AS "(x+y)-y == x",
       CASE WHEN (y).a <> 0 THEN (x * y) / y == x END     AS "(x*y)/y == x"
  FROM fractions ORDER BY code;
SELECT (1,2)::rational == (2,4)::rational AS "1/2 == 2/4",
       (1,2)::rational =  (2,4)::rational AS "1/2 = 2/4 (покомпонентно)";

-- сумма всех дробей x таблицы
CREATE OR REPLACE FUNCTION rat_sum_x() RETURNS rational AS $$
DECLARE s rational := rat(0); r record;
BEGIN
  FOR r IN SELECT x FROM fractions LOOP
    s := s + r.x;
  END LOOP;
  RETURN s;
END $$ LANGUAGE plpgsql;
SELECT rat_str(rat_sum_x()) AS "сумма x", round(rat_value(rat_sum_x())::numeric, 6) AS "в float";

-- ожидаемые ошибки
\set ON_ERROR_STOP off
SELECT (1,2)::rational / rat(0);
SELECT rat(1, 0);
\set ON_ERROR_STOP on
