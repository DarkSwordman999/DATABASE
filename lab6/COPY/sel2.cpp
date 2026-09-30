// sel2.cpp - фильтр: структура таблицы из pg_dump -s (stdin) -> сценарий T-SQL (stdout)
// Использование: pg_dump.exe -s -t """ТОВАР""" sales | sel2.exe > cr_ТОВАР.txt
// Отличия от исходного примера:
//   - DROP TABLE IF EXISTS (первое копирование не завершается ошибкой);
//   - CREATE UNLOGGED TABLE (ПРОДАЖА после ЛР2) приводится к CREATE TABLE;
//   - замены в строке выполняются для всех вхождений, а не только первого.
#include <iostream>
#include <string>

using namespace std;

static void replace_all(string& str, const string& from, const string& to) {
    size_t pos = 0;
    while ((pos = str.find(from, pos)) != string::npos) {
        str.replace(pos, from.length(), to);
        pos += to.length();
    }
}

// перевод типов и идентификаторов PostgreSQL в синтаксис MS SQL Server
static void change(string& s) {
    replace_all(s, "public.", "");
    replace_all(s, " without time zone", "");
    replace_all(s, "bit(1)", "bit");
    replace_all(s, "timestamp", "datetime");
    replace_all(s, " \"", " [");
    replace_all(s, "\" ", "] ");
    replace_all(s, "(\"", "([");
    replace_all(s, "\")", "])");
    replace_all(s, "\";", "];");
    replace_all(s, "\",", "],");
}

int main() {
    string s;
    bool in_table = false;

    cout << ":OUT nul" << endl;
    cout << "USE [SALES];" << endl;
    while (getline(cin, s)) {
        if (!s.empty() && s.back() == '\r') s.pop_back();
        replace_all(s, "CREATE UNLOGGED TABLE", "CREATE TABLE");

        // ограничение первичного ключа: ALTER TABLE ONLY ... + ADD CONSTRAINT ...
        if (s.compare(0, 17, "ALTER TABLE ONLY ") == 0) {
            s = s.substr(16) + " ";
            change(s);
            cout << "ALTER TABLE" << s << endl;
            getline(cin, s);
            change(s);
            cout << s << endl;
            break;
        }

        if (s.compare(0, 12, "CREATE TABLE") == 0) {
            in_table = true;
            string name = s.substr(13, s.length() - 13 - 2);   // между "CREATE TABLE " и " ("
            string drop = "DROP TABLE IF EXISTS " + name + " ;";
            change(drop);
            cout << drop << endl;
        }
        if (in_table) {
            change(s);
            cout << s << endl;
        }
        if (s.compare(0, 2, ");") == 0) in_table = false;
    }
    cout << ":OUT stdout" << endl;
    return 0;
}
