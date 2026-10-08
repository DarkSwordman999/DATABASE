-- =====================================================================
-- ЛР7, задача 1: расчёт месячной премии сотрудников за период [D1, D2]
-- Параметры: D1 D2 (ДД.ММ.ГГГГ), P - % выручки на премию, M - на сколько % старший
--            менеджер получает больше рядового, N - имя сотрудника (необязательно)
-- Запуск:    lab7\s.bat lab7\calculate1.sql 01.01.2021 30.06.2021 8.5 10.5 [Андрей]
--            ./help lr7 1 01.01.2021 30.06.2021 8.5 10.5 [Андрей]
-- Объекты:   dbo.f_премия, dbo.v_выручка_день, dbo.f_вес_смены (create_objects.sql)
-- =====================================================================
SET NOCOUNT ON;
DECLARE @D1 date          = CONVERT(date, COALESCE(NULLIF(SUBSTRING(N'$(arg1)', 2, 100), N''), N'01.01.2021'), 104);
DECLARE @D2 date          = CONVERT(date, COALESCE(NULLIF(SUBSTRING(N'$(arg2)', 2, 100), N''), N'30.06.2021'), 104);
DECLARE @P  decimal(9,4)  = CAST(COALESCE(NULLIF(SUBSTRING(N'$(arg3)', 2, 100), N''), N'8.5')  AS decimal(9,4));
DECLARE @M  decimal(9,4)  = CAST(COALESCE(NULLIF(SUBSTRING(N'$(arg4)', 2, 100), N''), N'10.5') AS decimal(9,4));
DECLARE @N  nvarchar(20)  = NULLIF(SUBSTRING(N'$(arg5)', 2, 100), N'');

PRINT N'=== ЛР7 / Задача 1: премия сотрудников ===';
PRINT N'D1 = ' + CONVERT(nvarchar(10), @D1, 104) + N',  D2 = ' + CONVERT(nvarchar(10), @D2, 104)
    + N',  P = ' + CAST(CAST(@P AS float) AS nvarchar(20)) + N' %,  M = ' + CAST(CAST(@M AS float) AS nvarchar(20)) + N' %'
    + COALESCE(N',  N = ' + @N, N'');

IF @N IS NULL
BEGIN
  SELECT год, месяц, сотрудник, CAST(ROUND(премия, 2) AS decimal(18,2)) AS [премия]
    FROM dbo.f_премия(@D1, @D2, @P, @M)
   ORDER BY год, номер_месяца, сотрудник;

  SELECT CAST(ROUND(SUM(премия), 2) AS decimal(18,2)) AS [общая сумма премии за период]
    FROM dbo.f_премия(@D1, @D2, @P, @M);
END
ELSE
BEGIN
  SELECT год, месяц, CAST(ROUND(премия, 2) AS decimal(18,2)) AS [сумма]
    FROM dbo.f_премия(@D1, @D2, @P, @M)
   WHERE сотрудник = @N
   ORDER BY год, номер_месяца;

  SELECT CAST(ROUND(COALESCE(SUM(премия), 0), 2) AS decimal(18,2)) AS [общая сумма премии сотрудника за период]
    FROM dbo.f_премия(@D1, @D2, @P, @M)
   WHERE сотрудник = @N;
END
