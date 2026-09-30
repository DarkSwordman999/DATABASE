-- =====================================================================
-- ЛР7: представления и функции пользователя в MS SQL Server (база SALES из ЛР6)
-- Создаёт объекты для двух задач:
--   1) премия сотрудников (calculate1.sql): v_выручка_день, f_месяц, f_вес_смены, f_премия
--   2) затраты на хранение товаров (calculate2.sql): v_движение_товара, f_дни, f_хранение
-- Запуск: lab7\s.bat lab7\create_objects.sql      ./h lr7 create
-- =====================================================================
SET NOCOUNT ON;
GO

-- ---------------------------------------------------------------------
-- общие объекты
-- ---------------------------------------------------------------------
-- название месяца по-русски (не зависит от SET LANGUAGE сервера)
CREATE OR ALTER FUNCTION dbo.f_месяц (@m int)
RETURNS nvarchar(10)
AS
BEGIN
  RETURN CHOOSE(@m, N'январь', N'февраль', N'март', N'апрель', N'май', N'июнь',
                    N'июль', N'август', N'сентябрь', N'октябрь', N'ноябрь', N'декабрь');
END;
GO

-- календарь: все дни интервала [@d1, @d2] (до 100 000 дней)
CREATE OR ALTER FUNCTION dbo.f_дни (@d1 date, @d2 date)
RETURNS TABLE
AS RETURN
  WITH ц AS (SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t(n)),
       числа AS (SELECT a.n + 10*b.n + 100*c.n + 1000*d.n + 10000*e.n AS n
                   FROM ц a CROSS JOIN ц b CROSS JOIN ц c CROSS JOIN ц d CROSS JOIN ц e)
  SELECT DATEADD(DAY, n, @d1) AS день
    FROM числа
   WHERE n <= DATEDIFF(DAY, @d1, @d2);
GO

-- ---------------------------------------------------------------------
-- задача 1: премия сотрудников
-- ---------------------------------------------------------------------
-- выручка (цена2) каждого магазина за каждый день продаж
CREATE OR ALTER VIEW dbo.v_выручка_день
AS
  SELECT CAST(ПРОДАЖА.дата AS date)                 AS день,
         ПРОДАЖА.магазин                            AS магазин,
         SUM(ПРОДАЖА.количество * ТОВАР.цена2)      AS выручка
    FROM ПРОДАЖА
         INNER JOIN ТОВАР ON ТОВАР.код = ПРОДАЖА.товар
   GROUP BY CAST(ПРОДАЖА.дата AS date), ПРОДАЖА.магазин;
GO

-- «взвешенное» число сотрудников смены: магазин @shop в день @day;
-- рядовой - вес 1, старший - вес 1 + @M/100
CREATE OR ALTER FUNCTION dbo.f_вес_смены (@day date, @shop int, @M decimal(9,4))
RETURNS decimal(18,6)
AS
BEGIN
  RETURN (SELECT SUM(1 + CAST(старший AS int) * @M / 100)
            FROM РАБОТА
           WHERE магазин = @shop
             AND @day BETWEEN CAST(дата1 AS date) AND CAST(дата2 AS date));
END;
GO

-- премия сотрудников по месяцам за [@D1, @D2]:
-- на премию идёт @P % дневной выручки магазина; она делится между сотрудниками смены
-- этого дня пропорционально весу (старший получает на @M % больше рядового)
CREATE OR ALTER FUNCTION dbo.f_премия (@D1 date, @D2 date, @P decimal(9,4), @M decimal(9,4))
RETURNS TABLE
AS RETURN
  SELECT YEAR(в.день)                    AS год,
         MONTH(в.день)                   AS номер_месяца,
         dbo.f_месяц(MONTH(в.день))      AS месяц,
         с.имя                           AS сотрудник,
         SUM(в.выручка * @P / 100
             * (1 + CAST(р.старший AS int) * @M / 100)
             / dbo.f_вес_смены(в.день, в.магазин, @M)) AS премия
    FROM dbo.v_выручка_день AS в
         INNER JOIN РАБОТА    AS р ON р.магазин = в.магазин
                                  AND в.день BETWEEN CAST(р.дата1 AS date) AND CAST(р.дата2 AS date)
         INNER JOIN СОТРУДНИК AS с ON с.код = р.сотрудник
   WHERE в.день BETWEEN @D1 AND @D2
   GROUP BY YEAR(в.день), MONTH(в.день), с.имя;
GO

-- ---------------------------------------------------------------------
-- задача 2: затраты на хранение товаров
-- ---------------------------------------------------------------------
-- суточное движение товара: D(t) - поставлено, S(t) - продано в день t
CREATE OR ALTER VIEW dbo.v_движение_товара
AS
  SELECT день, товар, SUM(поставлено) AS поставлено, SUM(продано) AS продано
    FROM (SELECT дата AS день, товар, количество AS поставлено, 0 AS продано
            FROM ПОСТАВКА
          UNION ALL
          SELECT CAST(дата AS date), товар, 0, количество
            FROM ПРОДАЖА) AS м
   GROUP BY день, товар;
GO

-- затраты на хранение по формуле (11) Expenses.pdf за каждый день t из [@D1, @D2]:
--   d(t) = сумма D(τ) по τ <= t  -  сумма S(τ) по τ <= t  +  @alpha * S(t)
--   затраты(t) = γ * d(t),  γ = ТОВАР.хранение (за 1 ед. товара в сутки)
-- Накопленные суммы считаются с первого дня движения товара (остаток на начало периода).
CREATE OR ALTER FUNCTION dbo.f_хранение (@D1 date, @D2 date, @alpha decimal(9,4))
RETURNS TABLE
AS RETURN
  WITH начало AS (
         SELECT CASE WHEN MIN(день) < @D1 THEN MIN(день) ELSE @D1 END AS д0
           FROM dbo.v_движение_товара),
       сетка AS (                        -- каждый товар × каждый день от начала до @D2
         SELECT дни.день, т.код AS товар, т.наименование, т.хранение,
                COALESCE(м.поставлено, 0) AS D, COALESCE(м.продано, 0) AS S
           FROM начало
                CROSS APPLY dbo.f_дни(начало.д0, @D2) AS дни
                CROSS JOIN ТОВАР AS т
                LEFT JOIN dbo.v_движение_товара AS м ON м.день = дни.день AND м.товар = т.код),
       остатки AS (
         SELECT день, наименование, хранение, S,
                SUM(D - S) OVER (PARTITION BY товар ORDER BY день ROWS UNBOUNDED PRECEDING) AS d1
           FROM сетка)
  SELECT YEAR(день)                     AS год,
         MONTH(день)                    AS номер_месяца,
         dbo.f_месяц(MONTH(день))       AS месяц,
         наименование                   AS товар,
         SUM(хранение * (d1 + @alpha * S)) AS затраты,
         MIN(d1 + @alpha * S)           AS мин_остаток
    FROM остатки
   WHERE день BETWEEN @D1 AND @D2
   GROUP BY YEAR(день), MONTH(день), наименование;
GO

SELECT name AS [объект], type_desc AS [тип]
  FROM sys.objects
 WHERE name IN (N'f_месяц', N'f_дни', N'v_выручка_день', N'f_вес_смены', N'f_премия',
                N'v_движение_товара', N'f_хранение')
 ORDER BY type_desc, name;
