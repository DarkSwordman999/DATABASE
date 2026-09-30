// =====================================================================
// ЛР8, вариант 20 (C#): распределение количества проданных товаров (шт)
// по категории товара (Признак 1) и кварталу (Признак 2)
// за период [01.07.2019, 30.06.2023] по данным базы SALES в MS SQL Server.
//
// Запуск:  Lab08.exe [дата1 дата2 [категория]]      (даты - ДД.ММ.ГГГГ)
//   Lab08.exe                                  - период по умолчанию, все категории
//   Lab08.exe 01.01.2021 31.12.2021            - заданный период, все категории
//   Lab08.exe 01.07.2019 30.06.2023 мебель     - только категория «мебель»
// Сервер задаётся переменной окружения LAB8_SERVER
// (по умолчанию (localdb)\MSSQLLocalDB, Windows-аутентификация).
// =====================================================================
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Globalization;
using System.Text;

class Lab08
{
    const string DefaultServer = @"(localdb)\MSSQLLocalDB";
    static readonly string[] Quarters = { "1-й", "2-й", "3-й", "4-й" };

    // Запрос: Признак 1 - наименование категории, Признак 2 - номер квартала,
    // Величина - сумма количества. Параметры @d1, @d2 - границы периода,
    // @cat - категория (NULL - все категории).
    const string Query =
        "SELECT КАТЕГОРИЯ.наименование, DATEPART(QUARTER, ПРОДАЖА.дата), SUM(ПРОДАЖА.количество) " +
        "FROM ПРОДАЖА " +
        "  INNER JOIN ТОВАР     ON ТОВАР.код = ПРОДАЖА.товар " +
        "  INNER JOIN КАТЕГОРИЯ ON КАТЕГОРИЯ.код = ТОВАР.категория " +
        "WHERE CAST(ПРОДАЖА.дата AS date) BETWEEN @d1 AND @d2 " +
        "  AND (@cat IS NULL OR КАТЕГОРИЯ.наименование = @cat) " +
        "GROUP BY КАТЕГОРИЯ.наименование, DATEPART(QUARTER, ПРОДАЖА.дата) " +
        "ORDER BY КАТЕГОРИЯ.наименование, DATEPART(QUARTER, ПРОДАЖА.дата)";

    static int Main(string[] args)
    {
        Console.OutputEncoding = Encoding.UTF8;

        DateTime d1 = new DateTime(2019, 7, 1), d2 = new DateTime(2023, 6, 30);
        string category = null;
        if (args.Length == 1 || args.Length > 3)
        {
            Console.WriteLine("Использование: Lab08.exe [дата1 дата2 [категория]]");
            return 1;
        }
        if (args.Length >= 2 && !(ParseDate(args[0], out d1) && ParseDate(args[1], out d2)))
        {
            Console.WriteLine("ОШИБКА: даты задаются в формате ДД.ММ.ГГГГ");
            return 1;
        }
        if (args.Length == 3 && args[2].Trim() != "")
            category = args[2].Trim();

        string server = Environment.GetEnvironmentVariable("LAB8_SERVER") ?? DefaultServer;
        string connectionString =
            "Server=" + server + ";Initial Catalog=SALES;Integrated Security=True;Persist Security Info=False";

        Console.WriteLine("ЛР8, вариант 20: количество проданных товаров (шт) по категории товара и кварталу");
        Console.WriteLine("Период: {0:dd.MM.yyyy} - {1:dd.MM.yyyy}", d1, d2);
        Console.WriteLine("Категория товара: {0}", category ?? "все категории");
        Console.WriteLine();

        try
        {
            List<object[]> rows = Load(connectionString, d1, d2, category);
            Print(rows);
        }
        catch (SqlException ex)
        {
            Console.WriteLine("ОШИБКА СУБД: " + ex.Message);
            return 2;
        }
        return 0;
    }

    static bool ParseDate(string s, out DateTime d)
    {
        return DateTime.TryParseExact(s, "dd.MM.yyyy", CultureInfo.InvariantCulture,
                                      DateTimeStyles.None, out d);
    }

    // Выполнение параметризованного запроса (SqlConnection, SqlCommand, SqlDataReader)
    static List<object[]> Load(string connectionString, DateTime d1, DateTime d2, string category)
    {
        var rows = new List<object[]>();
        using (var connection = new SqlConnection(connectionString))
        using (var command = new SqlCommand(Query, connection))
        {
            command.Parameters.AddWithValue("@d1", d1.Date);
            command.Parameters.AddWithValue("@d2", d2.Date);
            command.Parameters.AddWithValue("@cat", (object)category ?? DBNull.Value);
            connection.Open();
            using (SqlDataReader reader = command.ExecuteReader())
            {
                while (reader.Read())
                    rows.Add(new object[] { reader.GetString(0), reader.GetInt32(1), Convert.ToInt64(reader[2]) });
            }
        }
        return rows;
    }

    // Таблица: внутри каждой категории - распределение по кварталам и итог категории
    static void Print(List<object[]> rows)
    {
        const string fmt = "{0,-18}| {1,-8}| {2,14}";
        string line = new string('-', 45);
        Console.WriteLine(fmt, "Категория товара", "Квартал", "Продано, шт");
        Console.WriteLine(line);
        if (rows.Count == 0)
        {
            Console.WriteLine("нет продаж за указанный период");
            return;
        }
        string current = null;
        long subtotal = 0, total = 0;
        foreach (object[] r in rows)
        {
            string cat = (string)r[0];
            if (current != null && cat != current)
            {
                Console.WriteLine(fmt, "", "итого", subtotal);
                Console.WriteLine(line);
                subtotal = 0;
            }
            Console.WriteLine(fmt, cat == current ? "" : cat, Quarters[(int)r[1] - 1], r[2]);
            current = cat;
            subtotal += (long)r[2];
            total += (long)r[2];
        }
        Console.WriteLine(fmt, "", "итого", subtotal);
        Console.WriteLine(line);
        Console.WriteLine(fmt, "Всего", "", total);
    }
}
