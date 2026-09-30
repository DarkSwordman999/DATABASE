/*
 * ЛР5, вариант 22: функция f1 (k1 = mod(22-1, 15) + 1 = 7)
 * cosd(x), где x - double [градус], результат - double.
 * Угол приводится к [0, 360); для углов, кратных 60 и 90 градусам,
 * возвращаются точные значения (0, +-0.5, +-1) без погрешности вычисления через радианы.
 * В библиотеке v22.dll вместе с f2 (v22_f2.c); PG_MODULE_MAGIC - только здесь.
 */
#include "postgres.h"
#include "fmgr.h"
#include <math.h>

PG_MODULE_MAGIC;

#define PI_DEG (3.14159265358979323846 / 180.0)

PGDLLEXPORT Datum f1_cosd(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(f1_cosd);

Datum
f1_cosd(PG_FUNCTION_ARGS)
{
    float8  x = PG_GETARG_FLOAT8(0);
    float8  a;

    if (isinf(x) || isnan(x))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("f1_cosd: аргумент вне допустимого диапазона")));

    a = fmod(x, 360.0);
    if (a < 0)
        a += 360.0;

    if (a == 0.0)
        PG_RETURN_FLOAT8(1.0);
    if (a == 90.0 || a == 270.0)
        PG_RETURN_FLOAT8(0.0);
    if (a == 180.0)
        PG_RETURN_FLOAT8(-1.0);
    if (a == 60.0 || a == 300.0)
        PG_RETURN_FLOAT8(0.5);
    if (a == 120.0 || a == 240.0)
        PG_RETURN_FLOAT8(-0.5);

    PG_RETURN_FLOAT8(cos(a * PI_DEG));
}
