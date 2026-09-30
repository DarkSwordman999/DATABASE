/*
 * ЛР5, вариант 20: функция f1 (k1 = mod(20-1, 15) + 1 = 5)
 * floor(x), где x - double, результат - int:
 * наибольшее целое, не превосходящее x.
 * В библиотеке v20.dll вместе с f2 (v20_f2.c); PG_MODULE_MAGIC - только здесь.
 */
#include "postgres.h"
#include "fmgr.h"
#include <math.h>

PG_MODULE_MAGIC;

PGDLLEXPORT Datum f1_floor(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(f1_floor);

Datum
f1_floor(PG_FUNCTION_ARGS)
{
    float8  x = PG_GETARG_FLOAT8(0);
    float8  f = floor(x);

    if (isnan(f) || f < (float8) PG_INT32_MIN || f > (float8) PG_INT32_MAX)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("f1_floor: результат floor(%g) вне диапазона int", x)));

    PG_RETURN_INT32((int32) f);
}
