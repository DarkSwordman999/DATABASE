/*
 * ЛР5, вариант 22: функция f2 (k2 = mod(22-1 + [22/15], 15) + 1 = 8)
 * Порядковый номер символа, с которого s1 входит в s (1, 2, ...; 0 - не входит).
 * s, s1 - varchar, результат - int.
 * Номер считается в символах, а не в байтах: для кодировки UTF8 байтовое смещение
 * найденного вхождения переводится в число символов функцией pg_mbstrlen_with_len.
 */
#include "postgres.h"
#include "fmgr.h"
#include "varatt.h"
#include "mb/pg_wchar.h"
#include <string.h>

PGDLLEXPORT Datum f2_pos(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(f2_pos);

Datum
f2_pos(PG_FUNCTION_ARGS)
{
    VarChar    *arg_s = PG_GETARG_VARCHAR_PP(0);
    VarChar    *arg_s1 = PG_GETARG_VARCHAR_PP(1);
    const char *s = VARDATA_ANY(arg_s);
    const char *s1 = VARDATA_ANY(arg_s1);
    int         len = VARSIZE_ANY_EXHDR(arg_s);
    int         len1 = VARSIZE_ANY_EXHDR(arg_s1);
    int         i;

    if (len1 == 0)                      /* пустая подстрока входит с 1-го символа */
        PG_RETURN_INT32(1);

    /* перебор байтовых позиций начала символов строки s */
    for (i = 0; i + len1 <= len; i += pg_mblen(s + i))
    {
        if (memcmp(s + i, s1, len1) == 0)
            PG_RETURN_INT32(pg_mbstrlen_with_len(s, i) + 1);
    }
    PG_RETURN_INT32(0);
}
