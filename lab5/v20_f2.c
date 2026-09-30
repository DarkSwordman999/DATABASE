/*
 * ЛР5, вариант 20: функция f2 (k2 = mod(20-1 + [20/15], 15) + 1 = 6)
 * Аналог ALLTRIM(s): удаление разделителей (пробел, tab) в начале и в конце строки s.
 * s - varchar, результат - varchar.
 * Пробел и tab - однобайтовые символы, а байты многобайтовых символов UTF-8
 * всегда >= 0x80, поэтому побайтовый просмотр строки корректен.
 */
#include "postgres.h"
#include "fmgr.h"
#include "varatt.h"
#include "utils/builtins.h"

PGDLLEXPORT Datum f2_alltrim(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(f2_alltrim);

static int
is_sep(char c)
{
    return c == ' ' || c == '\t';
}

Datum
f2_alltrim(PG_FUNCTION_ARGS)
{
    VarChar    *arg = PG_GETARG_VARCHAR_PP(0);
    const char *s = VARDATA_ANY(arg);
    int         len = VARSIZE_ANY_EXHDR(arg);
    int         begin = 0;
    int         end = len;              /* позиция за последним символом */

    while (begin < end && is_sep(s[begin]))
        begin++;
    while (end > begin && is_sep(s[end - 1]))
        end--;

    PG_RETURN_VARCHAR_P((VarChar *) cstring_to_text_with_len(s + begin, end - begin));
}
