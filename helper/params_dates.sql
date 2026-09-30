-- Общая обработка параметров командной строки (период задаётся датами ДД.ММ.ГГГГ)
-- arg1, arg2 - границы периода (даты), arg3 - значение «Признака 1»
-- Перед подключением должны быть заданы date1, date2 (значения по умолчанию)
\if :{?arg1} \else \set arg1 '' \endif
\if :{?arg2} \else \set arg2 '' \endif
\if :{?arg3} \else \set arg3 '' \endif

SET datestyle TO 'ISO, DMY';

SELECT :'arg1' > '' AS is_arg1, :'arg2' > '' AS is_arg2, :'arg3' > '' AS is_arg3 \gset
\if :is_arg1
    \set date1 :arg1
\endif
\if :is_arg2
    \set date2 :arg2
\endif
