-- =====================================================================
-- ЛР7, задача 2: расчёт затрат на хранение товаров за период [D1, D2]
-- Параметры: D1 D2 (ДД.ММ.ГГГГ), alpha (0..1) - доля суток хранения товара в день продажи
--            (формула (11) Expenses.pdf), G - наименование товара (необязательно)
-- Запуск:    lab7\s.bat lab7\calculate2.sql 01.01.2021 30.06.2021 0.5 [плащ]
--            ./h lr7 2 01.01.2021 30.06.2021 0.5 [плащ]
-- Объекты:   dbo.f_хранение, dbo.v_движение_товара, dbo.f_дни (create_objects.sql)
-- =====================================================================
SET NOCOUNT ON;
DECLARE @D1    date          = CONVERT(date, COALESCE(NULLIF(SUBSTRING(N'$(arg1)', 2, 100), N''), N'01.01.2021'), 104);
DECLARE @D2    date          = CONVERT(date, COALESCE(NULLIF(SUBSTRING(N'$(arg2)', 2, 100), N''), N'30.06.2021'), 104);
DECLARE @alpha decimal(9,4)  = CAST(COALESCE(NULLIF(SUBSTRING(N'$(arg3)', 2, 100), N''), N'0.5') AS decimal(9,4));
DECLARE @G     nvarchar(20)  = NULLIF(SUBSTRING(N'$(arg4)', 2, 100), N'');

PRINT N'=== ЛР7 / Задача 2: затраты на хранение товаров ===';
PRINT N'D1 = ' + CONVERT(nvarchar(10), @D1, 104) + N',  D2 = ' + CONVERT(nvarchar(10), @D2, 104)
    + N',  alpha = ' + CAST(CAST(@alpha AS float) AS nvarchar(20))
    + COALESCE(N',  G = ' + @G, N'');

IF @alpha < 0 OR @alpha > 1
  PRINT N'ПРЕДУПРЕЖДЕНИЕ: по модели 0 <= alpha <= 1';

IF @G IS NULL
BEGIN
  SELECT год, месяц, товар, CAST(ROUND(затраты, 2) AS decimal(18,2)) AS [затраты на хранение]
    FROM dbo.f_хранение(@D1, @D2, @alpha)
   ORDER BY год, номер_месяца, товар;

  SELECT CAST(ROUND(SUM(затраты), 2) AS decimal(18,2)) AS [общая сумма затрат на хранение за период]
    FROM dbo.f_хранение(@D1, @D2, @alpha);
END
ELSE
BEGIN
  SELECT год, месяц, CAST(ROUND(затраты, 2) AS decimal(18,2)) AS [сумма]
    FROM dbo.f_хранение(@D1, @D2, @alpha)
   WHERE товар = @G
   ORDER BY год, номер_месяца;

  SELECT CAST(ROUND(COALESCE(SUM(затраты), 0), 2) AS decimal(18,2)) AS [общая сумма затрат на хранение товара за период]
    FROM dbo.f_хранение(@D1, @D2, @alpha)
   WHERE товар = @G;
END
