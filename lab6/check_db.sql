-- =====================================================================
-- Проверка параметров команд ЛР6-ЛР8 (./h, ./help) по базе SALES в MS SQL Server -
-- аналог helper/check_db.sql (PostgreSQL); данные в MS SQL могут отличаться от sales
-- Параметры s.bat: arg1 arg2, arg3 arg4 - пары «тип значение» (до двух), типы - helper/args.txt:
-- cat, cat~, prov, prov#, goods, goods#, client#, surname, emp, emp#, district# (# - код)
-- При ошибке выводит её и допустимые значения; код выхода sqlcmd: 0 - верно, 3 - ошибка
-- Запуск:    lab6\s.bat lab6\check_db.sql emp Иван goods плащ
-- =====================================================================
SET NOCOUNT ON;
DECLARE @p TABLE (n int, t nvarchar(20), v nvarchar(100));
INSERT @p VALUES (1, SUBSTRING(N'$(arg1)', 2, 100), SUBSTRING(N'$(arg2)', 2, 100)),
                 (2, SUBSTRING(N'$(arg3)', 2, 100), SUBSTRING(N'$(arg4)', 2, 100));
IF OBJECT_ID('tempdb..#rc') IS NOT NULL DROP TABLE #rc;
CREATE TABLE #rc (rc int);
INSERT #rc VALUES (0);

DECLARE @i int = 1, @t nvarchar(20), @v nvarchar(100), @what nvarchar(60), @tbl nvarchar(20);
WHILE @i <= 2
BEGIN
    SELECT @t = t, @v = v FROM @p WHERE n = @i;
    IF @t <> N'' AND NOT EXISTS (
                  SELECT 1 FROM КАТЕГОРИЯ WHERE @t = N'cat'       AND наименование = @v
        UNION ALL SELECT 1 FROM КАТЕГОРИЯ WHERE @t = N'cat~'      AND наименование LIKE N'%' + @v + N'%'
        UNION ALL SELECT 1 FROM ПОСТАВЩИК WHERE @t = N'prov'      AND название = @v
        UNION ALL SELECT 1 FROM ПОСТАВЩИК WHERE @t = N'prov#'     AND CAST(код AS nvarchar(20)) = @v
        UNION ALL SELECT 1 FROM ТОВАР     WHERE @t = N'goods'     AND наименование = @v
        UNION ALL SELECT 1 FROM ТОВАР     WHERE @t = N'goods#'    AND CAST(код AS nvarchar(20)) = @v
        UNION ALL SELECT 1 FROM КЛИЕНТ    WHERE @t = N'client#'   AND CAST(код AS nvarchar(20)) = @v
        UNION ALL SELECT 1 FROM КЛИЕНТ    WHERE @t = N'surname'   AND фамилия = @v
        UNION ALL SELECT 1 FROM СОТРУДНИК WHERE @t = N'emp'       AND имя = @v
        UNION ALL SELECT 1 FROM СОТРУДНИК WHERE @t = N'emp#'      AND CAST(код AS nvarchar(20)) = @v
        UNION ALL SELECT 1 FROM РАЙОН     WHERE @t = N'district#' AND CAST(код AS nvarchar(20)) = @v)
    BEGIN
        SELECT @what = CASE @t WHEN N'cat'       THEN N'категории'
                               WHEN N'cat~'      THEN N'категории, содержащей'
                               WHEN N'prov'      THEN N'поставщика'
                               WHEN N'prov#'     THEN N'поставщика с кодом'
                               WHEN N'goods'     THEN N'товара'
                               WHEN N'goods#'    THEN N'товара с кодом'
                               WHEN N'client#'   THEN N'клиента с кодом'
                               WHEN N'surname'   THEN N'клиента с фамилией'
                               WHEN N'emp'       THEN N'сотрудника с именем'
                               WHEN N'emp#'      THEN N'сотрудника с кодом'
                               WHEN N'district#' THEN N'района с кодом'
                               ELSE N'значения неизвестного типа' END,
               @tbl  = CASE WHEN @t LIKE N'cat%'  THEN N'КАТЕГОРИЯ'
                            WHEN @t LIKE N'prov%' THEN N'ПОСТАВЩИК'
                            WHEN @t LIKE N'goods%' THEN N'ТОВАР'
                            WHEN @t IN (N'client#', N'surname') THEN N'КЛИЕНТ'
                            WHEN @t LIKE N'emp%'  THEN N'СОТРУДНИК'
                            WHEN @t = N'district#' THEN N'РАЙОН'
                            ELSE N'?' END;
        PRINT N'ОШИБКА: нет ' + @what + N' «' + @v + N'» в таблице ' + @tbl + N' (MS SQL Server)';
        PRINT N'Допустимые значения:';
        SELECT значение, пояснение
          FROM (          SELECT CAST(наименование AS nvarchar(100)) AS значение, CAST(N'' AS nvarchar(100)) AS пояснение
                            FROM КАТЕГОРИЯ WHERE @t IN (N'cat', N'cat~')
                UNION ALL SELECT название, N''                     FROM ПОСТАВЩИК WHERE @t = N'prov'
                UNION ALL SELECT CAST(код AS nvarchar(20)), название FROM ПОСТАВЩИК WHERE @t = N'prov#'
                UNION ALL SELECT наименование, N''                 FROM ТОВАР     WHERE @t = N'goods'
                UNION ALL SELECT CAST(код AS nvarchar(20)), наименование FROM ТОВАР WHERE @t = N'goods#'
                UNION ALL SELECT CAST(код AS nvarchar(20)), фамилия + N' ' + имя FROM КЛИЕНТ WHERE @t = N'client#'
                UNION ALL SELECT DISTINCT фамилия, N''             FROM КЛИЕНТ    WHERE @t = N'surname'
                UNION ALL SELECT DISTINCT имя, N''                 FROM СОТРУДНИК WHERE @t = N'emp'
                UNION ALL SELECT CAST(код AS nvarchar(20)), имя    FROM СОТРУДНИК WHERE @t = N'emp#'
                UNION ALL SELECT CAST(код AS nvarchar(20)), название FROM РАЙОН   WHERE @t = N'district#'
               ) s
         ORDER BY CASE WHEN значение NOT LIKE N'%[^0-9]%' THEN RIGHT(N'0000000000' + значение, 10)
                       ELSE значение END;
        UPDATE #rc SET rc = 3;
    END;
    SET @i += 1;
END;
GO
:Out NUL
:EXIT(SELECT rc FROM #rc)
