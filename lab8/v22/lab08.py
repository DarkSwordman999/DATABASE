"""ЛР8, вариант 22 (Python): распределение суммы затрат клиентов (количество × цена2)
по поставщику (Признак 1) и декаде месяца (Признак 2)
за период [01.10.2021, 31.01.2024] по данным базы SALES в MS SQL Server.

Запуск:  python lab08.py [дата1 дата2 [поставщик]]      (даты - ДД.ММ.ГГГГ)
    python lab08.py                                    - период по умолчанию, все поставщики
    python lab08.py 01.01.2022 31.12.2022              - заданный период, все поставщики
    python lab08.py 01.10.2021 31.01.2024 "ООО Турман" - только один поставщик
Сервер задаётся переменной окружения LAB8_SERVER
(по умолчанию (localdb)\\MSSQLLocalDB, Windows-аутентификация).
Доступ к СУБД - модуль pyodbc через драйвер «ODBC Driver 17 for SQL Server».
"""
import os
import sys
from datetime import date, datetime
from decimal import Decimal

import pyodbc

DEFAULT_SERVER = r"(localdb)\MSSQLLocalDB"
DRIVER = "ODBC Driver 17 for SQL Server"
DECADES = {1: "1-я (1-10)", 2: "2-я (11-20)", 3: "3-я (21-31)"}

# Признак 1 - название поставщика, Признак 2 - номер декады месяца,
# Величина - сумма затрат клиентов. Параметры: границы периода и поставщик (NULL - все).
QUERY = """
SELECT ПОСТАВЩИК.название,
       CASE WHEN DAY(ПРОДАЖА.дата) <= 10 THEN 1
            WHEN DAY(ПРОДАЖА.дата) <= 20 THEN 2
            ELSE 3 END                          AS декада,
       SUM(ПРОДАЖА.количество * ТОВАР.цена2)    AS затраты
FROM ПРОДАЖА
     INNER JOIN ТОВАР     ON ТОВАР.код = ПРОДАЖА.товар
     INNER JOIN ПОСТАВЩИК ON ПОСТАВЩИК.код = ТОВАР.поставщик
WHERE CAST(ПРОДАЖА.дата AS date) BETWEEN ? AND ?
  AND (? IS NULL OR ПОСТАВЩИК.название = ?)
GROUP BY ПОСТАВЩИК.название,
         CASE WHEN DAY(ПРОДАЖА.дата) <= 10 THEN 1
              WHEN DAY(ПРОДАЖА.дата) <= 20 THEN 2
              ELSE 3 END
ORDER BY ПОСТАВЩИК.название, декада
"""


def parse_args(argv):
    """Границы периода и значение Признака 1 из параметров командной строки."""
    d1, d2, provider = date(2021, 10, 1), date(2024, 1, 31), None
    if len(argv) == 1 or len(argv) > 3:
        raise ValueError("Использование: python lab08.py [дата1 дата2 [поставщик]]")
    if len(argv) >= 2:
        try:
            d1 = datetime.strptime(argv[0], "%d.%m.%Y").date()
            d2 = datetime.strptime(argv[1], "%d.%m.%Y").date()
        except ValueError:
            raise ValueError("ОШИБКА: даты задаются в формате ДД.ММ.ГГГГ")
    if len(argv) == 3 and argv[2].strip():
        provider = argv[2].strip()
    return d1, d2, provider


def load(d1, d2, provider):
    """Выполнение параметризованного запроса к MS SQL Server."""
    server = os.environ.get("LAB8_SERVER", DEFAULT_SERVER)
    conn_str = (f"DRIVER={{{DRIVER}}};SERVER={server};DATABASE=SALES;"
                "Trusted_Connection=yes")
    with pyodbc.connect(conn_str) as conn:
        cursor = conn.cursor()
        cursor.execute(QUERY, d1, d2, provider, provider)
        return [(row[0], row[1], Decimal(row[2])) for row in cursor.fetchall()]


def money(x):
    """Вещественное значение с точностью до тысячных."""
    return f"{x:.3f}"


def print_table(rows):
    """Таблица: внутри каждого поставщика - распределение по декадам и итог поставщика."""
    fmt = "{:<16}| {:<14}| {:>17}"
    line = "-" * 52
    print(fmt.format("Поставщик", "Декада месяца", "Затраты, ден. ед."))
    print(line)
    if not rows:
        print("нет продаж за указанный период")
        return
    total = Decimal(0)
    current, subtotal = None, Decimal(0)
    for provider, decade, value in rows:
        if current is not None and provider != current:
            print(fmt.format("", "итого", money(subtotal)))
            print(line)
            subtotal = Decimal(0)
        print(fmt.format("" if provider == current else provider, DECADES[decade], money(value)))
        current = provider
        subtotal += value
        total += value
    print(fmt.format("", "итого", money(subtotal)))
    print(line)
    print(fmt.format("Всего", "", money(total)))


def main(argv):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    try:
        d1, d2, provider = parse_args(argv)
    except ValueError as err:
        print(err)
        return 1
    print("ЛР8, вариант 22: сумма затрат клиентов (ден. ед.) по поставщику и декаде месяца")
    print(f"Период: {d1:%d.%m.%Y} - {d2:%d.%m.%Y}")
    print(f"Поставщик: {provider or 'все поставщики'}")
    print()
    try:
        rows = load(d1, d2, provider)
    except pyodbc.Error as err:
        print("ОШИБКА СУБД:", err)
        return 2
    print_table(rows)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
