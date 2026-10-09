"""Отчёты защиты ЛР2: reports/zashita/Защита_вариант_20.txt и Защита_вариант_22.txt
Собираются из протоколов прогона results/zas_v20_protocol.txt, results/zas_v22_protocol.txt
(./help lr2 def 20 и ./help lr2 def 22) и results/zas_restore_protocol.txt (./help lr2 def restore);
числа в таблице сравнения и выводах берутся из протоколов.
Запуск из корня проекта: python reports/zashita/make_defense.py
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
D = "big_db_indexes/zashita/"
LINE = "-" * 78
DLINE = "=" * 78

VARIANTS = {
    20: dict(
        query="суммарной выручки от продажи товаров двух поставщиков с заданными именами",
        tables="ПРОДАЖА, ТОВАР, ПОСТАВЩИК",
        indexes=[("1) ПРОДАЖА по полю товар - btree", "def20_продажа_товар"),
                 ("2) ТОВАР по полю код - hash", "def20_товар_код"),
                 ("   ТОВАР по полю поставщик - hash", "def20_товар_поставщик"),
                 ("3) ПОСТАВЩИК по полю название - btree", "def20_поставщик_название")],
        task3="и выполнить запрос один раз - с фиксацией времени любым способом,\n"
              "     и один раз командой EXPLAIN ANALYZE.",
        notes=["В таблице ПОСТАВЩИК поле наименования называется «название» (DATA/create_tables), "
               "индекс построен по нему. Пункт 2) задания «товар по полю код, поставщик (hash)» "
               "выполнен как два hash-индекса таблицы ТОВАР: по полю код и по полю-ссылке поставщик.",
               "В задании 3 запрос выполняется 5 раз (минимальное время выделено) - требование "
               "«один раз с фиксацией времени» выполнено с запасом, чтобы сравнение с заданием 2 "
               "не зависело от разброса отдельного замера."],
        params='"ООО Турман" "ЧП Загорье"',
        example='./help lr2 def 20 1 "ООО Турман" "ЧП Загорье"',
        cond2="без индексов, минимум из 5",
        result="Суммарная выручка поставщиков ООО Турман и ЧП Загорье",
        share="товары двух поставщиков из пяти (4 товара из 10, около 40 % строк ПРОДАЖА)",
    ),
    22: dict(
        query="суммарной выручки от продажи товаров заданной категории",
        tables="ПРОДАЖА, ТОВАР, КАТЕГОРИЯ",
        indexes=[("1) ПРОДАЖА по полю товар - btree", "def22_продажа_товар"),
                 ("2) ТОВАР по полю код - hash", "def22_товар_код"),
                 ("   ТОВАР по полю категория - hash", "def22_товар_категория"),
                 ("3) КАТЕГОРИЯ по полю наименование - hash", "def22_категория_наименование")],
        task3="и выполнить запрос 5 раз с фиксацией времени (минимальное выделено),\n"
              "     и один раз командой EXPLAIN ANALYZE.",
        notes=["В задании 2 перед замерами удаляются все индексы таблиц запроса и создаётся один "
               f"индекс ПРОДАЖА(товар) btree ({D}z2_noidx.sql). Индекс таблицы ПРОДАЖА построен, "
               "как и в варианте 20, по полю-ссылке товар (btree). Пункт 2) задания «товар код, "
               "категории (hash)» выполнен как два hash-индекса таблицы ТОВАР: по полю код и по "
               "полю-ссылке категория."],
        params="мебель",
        example="./help lr2 def 22 1 мебель",
        cond2="с индексом ПРОДАЖА(товар), мин. из 5",
        result="Суммарная выручка от продажи товаров категории «мебель»",
        share="товары одной категории из двух (5 товаров из 10, около 50 % строк ПРОДАЖА)",
    ),
}


def read(path):
    with open(os.path.join(ROOT, path), encoding="utf-8") as f:
        return f.read().rstrip("\n")


def wrap(text, width=90, indent="  ", cont=None):
    """Перенос абзаца по словам: indent - отступ первой строки, cont - остальных."""
    cont = indent if cont is None else cont
    lines, cur = [], indent
    for w in text.split():
        if len(cur) + len(w) + 1 > width and cur.strip():
            lines.append(cur.rstrip())
            cur = cont
        cur += w + " "
    lines.append(cur.rstrip())
    return "\n".join(lines)


def numbers(proto):
    """Числа из протокола: результат запроса, минимумы заданий 2 и 3, EXPLAIN ANALYZE."""
    total = re.search(r"\|\s+(\d+\.\d+)\s*$", proto.split("Результат:")[1].split("\n\n")[0], re.M)
    mins = dict(re.findall(r"^ задание ([23]) \|.*\|\s+([\d.]+)\s*$", proto, re.M))
    execs = re.findall(r"Execution Time: ([\d.]+) ms", proto)
    plans = re.findall(r"Planning Time: ([\d.]+) ms", proto)
    no_idx = proto.count("индексы в плане НЕ используются")
    return dict(total=total.group(1), min2=float(mins["2"]), min3=float(mins["3"]),
                ex2=float(execs[0]), ex3=float(execs[1]), pl3=plans[1], no_idx=no_idx)


def report(v):
    c = VARIANTS[v]
    proto = read(f"results/zas_v{v}_protocol.txt")
    restore = read("results/zas_restore_protocol.txt")
    n = numbers(proto)
    diff = (n["min3"] - n["min2"]) / n["min2"] * 100
    idx_w = max(len(a) for a, _ in c["indexes"]) + 2
    out = [DLINE, "ЗАЩИТА ЛАБОРАТОРНОЙ РАБОТЫ №2",
           "«Оценка временных характеристик выполнения запросов в объёмной базе данных PostgreSQL»",
           f"Вариант {v}", DLINE, "",
           "Задание на защиту",
           f"  1. Составить запрос на вычисление {c['query']}.",
           f"  2. Выполнить запрос 1), когда в таблицах {c['tables']} нет индексов (никаких).",
           "     Зафиксировать время в минутах и в мс выполнения 5 запросов и выделить самое маленькое.",
           "  3. Ввести индексы:"]
    out += [f"       {a:<{idx_w}}({b})" for a, b in c["indexes"]]
    out += [f"     {c['task3']}", ""]
    out += [wrap("Примечание. " + t) + "\n" for t in c["notes"]]
    out += ["Среда выполнения",
            "  Windows 11 Pro, PostgreSQL 18.6, psql 18.6; база sales (схема и данные ЛР1 из DATA,",
            "  ./help db), таблица ПРОДАЖА увеличена до 2 000 000 записей (./help lr2 gen,",
            "  табличное пространство lr2_tbs на диске D:). Запуск - из PowerShell в корне проекта.",
            "", LINE, "Команды ./help (в скобках - выполняемый файл)", LINE,
            f"  ./help lr2 def {v}                 задания 1-3 подряд            ({D}z_all.sql)",
            f"  ./help lr2 def {v} 1 [парам.]      задание 1: сводная таблица    ({D}z1_query.sql, {D}v{v}_query.sql)",
            f"  ./help lr2 def {v} 2 [парам.]      задание 2: 5 замеров          ({D}z2_noidx.sql)",
            f"  ./help lr2 def {v} 3 [парам.]      задание 3: индексы, замеры    ({D}z3_idx.sql)",
            f"  ./help lr2 def {v} idx             индексы таблиц запроса        ({D}show_idx.sql)",
            f"  ./help lr2 def {v} idx_drop|idx_add  удалить / создать индексы задания 3 ({D}idx_drop.sql, idx_add.sql)",
            f"  ./help lr2 def restore            вернуть PRIMARY KEY           ({D}restore.sql)",
            f"  Параметры по умолчанию: {c['params']}; пример: {c['example']}",
            "  Каждая команда печатает строку «>>> Файл: ...» - путь выполняемого сценария.",
            wrap(f"Варианты 20 и 22 независимы: индексы задания 3 называются def20_* и def22_*, "
                 f"и любая команда варианта удаляет индексы другого варианта ({D}config.sql), "
                 f"поэтому вручную индексы удалять не нужно."),
            wrap(f"Вспомогательные файлы: {D}config.sql (настройки варианта, текст запроса :q), "
                 "show_query.sql (вывод текста запроса), drop_all.sql (удаление всех индексов, "
                 "в т.ч. PRIMARY KEY), time_run.sql (один замер), time_table.sql (таблица замеров, "
                 "минимум), plan_check.sql (узлы плана и использование индексов), indexes.sql "
                 "(список индексов)."),
            "  Листинг программы: reports/zashita/Листинг_программы.txt",
            "", LINE, f"Результат прогона ./help lr2 def {v} (протокол results/zas_v{v}_protocol.txt)",
            LINE, proto, "", LINE, "Сравнение и выводы", LINE]
    rows = [(c["cond2"], n["min2"]), ("с индексами, минимум из 5", n["min3"]),
            ("EXPLAIN ANALYZE (с индексами)", n["ex3"])]
    w = max(len(r[0]) for r in rows) + 2
    out.append(f"   {'условие':<{w}}|  время, мс  | время, мин")
    for i, (name, ms) in enumerate(rows):
        tail = f"   (Planning Time {n['pl3']} мс)" if i == 2 else ""
        out.append(f"   {name:<{w}}| {ms:11.3f} | {ms / 60000:.6f}{tail}")
    same = abs(diff) < 10
    out += ["",
            f"1) {c['result']} составила {n['total']} ден. ед.",
            wrap(f"2) Время выполнения {'без индексов' if v == 20 else 'с одним индексом ПРОДАЖА(товар)'} "
                 f"и со всеми индексами варианта "
                 + (f"практически одинаково (разница {diff:+.1f} %, в пределах разброса отдельных "
                    f"замеров)." if same else f"отличается на {diff:+.1f} %.")
                 + " Проверка плана (plan_check.sql) в заданиях 2 и 3 показывает причину: "
                 + ("ни один узел плана не читает таблицы через индекс - созданные индексы "
                    "планировщик не использует." if n["no_idx"] == 2 else
                    "в плане есть узлы, читающие таблицы через индекс.")
                 + f" Условию соответствуют {c['share']}, поэтому читать ПРОДАЖА по индексу "
                 "дороже, чем последовательно: выбран Parallel Seq Scan по ПРОДАЖА и Hash Join с "
                 "маленькой хеш-таблицей отобранных товаров. Справочники занимают одну страницу, "
                 "и для них Seq Scan тоже дешевле индекса.", indent="", cont="   "),
            wrap("3) EXPLAIN ANALYZE показывает время несколько больше, чем обычное выполнение: "
                 "при ANALYZE замеряется время каждого узла плана (накладные расходы на таймеры).",
                 indent="", cont="   "),
            wrap("4) Индексы ускорили бы запрос при избирательном условии (малой доле строк "
                 "ПРОДАЖА), например при отборе одного редкого товара; для данного задания они не "
                 "дают выигрыша, но увеличивают размер базы и время вставки строк в ПРОДАЖА.",
                 indent="", cont="   "),
            "", LINE, "После защиты исходные индексы возвращаются командой ./help lr2 def restore:",
            LINE, restore, ""]
    return "\n".join(out)


if __name__ == "__main__":
    for v in VARIANTS:
        path = os.path.join(ROOT, "reports", "zashita", f"Защита_вариант_{v}.txt")
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(report(v))
        print(path)
