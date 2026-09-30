-- Общая обработка параметров командной строки (период задаётся годами)
-- arg1, arg2 - границы периода (годы), arg3 - значение «Признака 1»
-- Перед подключением должны быть заданы year1, year2 (значения по умолчанию)
\if :{?arg1} \else \set arg1 '' \endif
\if :{?arg2} \else \set arg2 '' \endif
\if :{?arg3} \else \set arg3 '' \endif

SELECT :'arg1' > '' AS is_arg1, :'arg2' > '' AS is_arg2, :'arg3' > '' AS is_arg3 \gset
\if :is_arg1
    \set year1 :arg1
\endif
\if :is_arg2
    \set year2 :arg2
\endif
