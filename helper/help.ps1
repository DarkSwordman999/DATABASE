# =====================================================================
#  help.ps1 - запуск задач и лабораторных работ ПАБД (база SALES), варианты 20 и 22
#  PowerShell-версия сценария h (та же логика, без Git Bash и perl).
#  Запуск из PowerShell или cmd в корне проекта: ./help <команда> [параметры]
#  (./help - это help.cmd, он вызывает этот файл с -ExecutionPolicy Bypass)
#  PostgreSQL - через psql, MS SQL Server (ЛР6, ЛР7) и сборка на C (ЛР5) - через .bat
# =====================================================================
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not $env:PGHOST)     { $env:PGHOST = 'localhost' }
if (-not $env:PGPORT)     { $env:PGPORT = '5432' }
if (-not $env:PGUSER)     { $env:PGUSER = 'postgres' }
if (-not $env:PGDATABASE) { $env:PGDATABASE = 'sales' }
$env:PGCLIENTENCODING = 'UTF8'

try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
$StdOut = [Console]::OpenStandardOutput()

# вывод строки в UTF-8 (байты напрямую в stdout, без перекодировки PowerShell)
function Say([string]$text) {
    $b = $Utf8.GetBytes($text + "`r`n")
    $StdOut.Write($b, 0, $b.Length)
}

# аналог helper/fixenc.pl: строка в UTF-8 остаётся как есть; иначе корректные двухбайтовые
# последовательности UTF-8 сохраняются, остальные байты - в кодировке $cp (CP1251 / CP866)
function Fix-Line([byte[]]$b, $cp) {
    try { return $Utf8Strict.GetString($b) } catch {}
    $sb = New-Object System.Text.StringBuilder
    $i = 0
    while ($i -lt $b.Length) {
        $x = $b[$i]
        if ($x -lt 0x80) { [void]$sb.Append([char]$x); $i++ }
        elseif ($x -ge 0xC2 -and $x -le 0xDF -and $i + 1 -lt $b.Length -and
                $b[$i + 1] -ge 0x80 -and $b[$i + 1] -le 0xBF) {
            [void]$sb.Append($Utf8.GetString($b, $i, 2)); $i += 2
        }
        else { [void]$sb.Append($cp.GetString($b, $i, 1)); $i++ }
    }
    $sb.ToString()
}

# выполнить командную строку через cmd.exe (stderr вместе с stdout), передать $InputText
# на стандартный ввод; вывод - построчно: с исправлением кодировки ($Cp) или как есть
function Invoke-Raw {
    param([string]$CmdLine, [string]$InputText, [string]$Cp, [string]$Tee, [switch]$Quiet)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $env:ComSpec
    $psi.Arguments = '/d /s /c "' + $CmdLine + ' 2>&1"'
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardInput = [bool]$InputText
    $p = [System.Diagnostics.Process]::Start($psi)
    if ($InputText) {
        $in = $Utf8.GetBytes($InputText)
        $p.StandardInput.BaseStream.Write($in, 0, $in.Length)
        $p.StandardInput.Close()
    }
    $enc = if ($Cp) { [Text.Encoding]::GetEncoding([int]($Cp -replace '\D')) } else { $null }
    $teeFile = if ($Tee) { [IO.File]::Create((Join-Path $Root $Tee)) } else { $null }
    $emit = {
        param([byte[]]$bytes)
        if ($enc) { $bytes = $Utf8.GetBytes((Fix-Line $bytes $enc)) }
        if (-not $Quiet) { $StdOut.Write($bytes, 0, $bytes.Length); $StdOut.Flush() }
        if ($teeFile) { $teeFile.Write($bytes, 0, $bytes.Length) }
    }
    $src = $p.StandardOutput.BaseStream
    $buf = New-Object byte[] 65536
    $line = New-Object System.IO.MemoryStream
    while (($n = $src.Read($buf, 0, $buf.Length)) -gt 0) {
        $start = 0
        while ($start -lt $n) {
            $nl = [Array]::IndexOf($buf, [byte]10, $start, $n - $start)
            if ($nl -lt 0) { $line.Write($buf, $start, $n - $start); break }
            $line.Write($buf, $start, $nl - $start + 1)
            & $emit $line.ToArray()
            $line.SetLength(0)
            $start = $nl + 1
        }
    }
    if ($line.Length) { & $emit $line.ToArray() }
    $p.WaitForExit()
    if ($teeFile) { $teeFile.Close() }
}

# аргумент для командной строки cmd: всегда в кавычках (пустой аргумент сохраняется)
function Q([string]$a) { '"' + $a + '"' }

# psql-сценарий с параметрами arg1..arg3 (как s.bat): параметры передаются через stdin
# командами \set, т.к. psql под Windows получает argv в CP1251 и кириллица в -v ломается.
# Служебные сообщения psql приходят в CP1251 и приводятся к UTF-8 (Fix-Line).
function Run([string]$file, [string]$a1, [string]$a2, [string]$a3, [switch]$Quiet) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        Say "ОШИБКА: Файл $file не найден"
        exit 1
    }
    $text = ''
    $i = 1
    foreach ($a in @($a1, $a2, $a3)) {
        $text += "\set arg$i '" + ($a -replace "'", "''") + "'`n"
        $i++
    }
    $text += "\i '" + ($file -replace '\\', '/') + "'`n"
    Invoke-Raw 'psql.exe -q -X -P pager=off -P "null=<null>" -f -' $text 'cp1251' -Quiet:$Quiet
}

# psql-сценарий в системной базе postgres (как s1.bat)
function Run-Pg([string]$file) {
    $db = $env:PGDATABASE
    $env:PGDATABASE = 'postgres'
    Invoke-Raw ('psql.exe -q -X -P pager=off -f ' + (Q $file)) $null 'cp1251'
    $env:PGDATABASE = $db
}

# командный файл Windows: путь в формате Windows, параметры как есть
function Bat([string]$file, [string[]]$params, [string]$Cp, [string]$Tee) {
    $line = Q ($file -replace '/', '\')
    foreach ($a in $params) { $line += ' ' + (Q $a) }
    Invoke-Raw $line $null $Cp $Tee
}

function Need-Variant([string]$v) {
    if ($v -ne '20' -and $v -ne '22') {
        Say 'ОШИБКА: Укажите вариант 20 или 22'
        exit 1
    }
}

function Need-Task([string]$t) {
    if ($t -ne '1' -and $t -ne '2') {
        Say 'ОШИБКА: Укажите номер задания 1 или 2'
        exit 1
    }
}

function Show-Text([string]$file) {
    $b = [IO.File]::ReadAllBytes((Join-Path $Root $file))
    $StdOut.Write($b, 0, $b.Length)
}

$Argv = @($args)
$A = $Argv + @('', '', '', '', '', '', '', '') | ForEach-Object { [string]$_ }

if (-not $A[0]) {
    Say @'
=============================================
  ПАБД: БАЗА ДАННЫХ SALES, ВАРИАНТЫ 20 И 22
=============================================

================== ЛР1: БАЗА И ЗАДАНИЯ ==================
  ./help db              - создать БД sales, таблицы и загрузить данные
  ./help counts          - количество строк в таблицах
  ./help v20 1 [дата1 дата2 [категория]]  - в.20: объём поставок по категории и кварталу
  ./help v20 2 [год1 год2 [день недели]]  - в.20: продажи (шт) по дню недели и району
  ./help v22 1 [дата1 дата2 [поставщик]]  - в.22: выручка по поставщику и декаде
  ./help v22 2 [год1 год2 [время года]]   - в.22: затраты клиентов по сезону и полу
  ./help all             - все 4 задания с параметрами по умолчанию
  ./help lr1 lan         - настроить pg_hba.conf и брандмауэр для сети (от администратора)
  ./help lr1 client сценарий [a1 a2 a3] - выполнить сценарий через s_lan.bat (сервер по IP)
  Пример: ./help v20 1 01.01.2021 31.12.2022 мебель

================== ЛР2: ОБЪЁМНАЯ БД, ИНДЕКСЫ, EXPLAIN ==================
  ./help lr2 gen [N]           - ПРОДАЖА: N псевдослучайных записей (по умолч. 2 000 000)
  ./help lr2 restore           - вернуть 1000 записей ПРОДАЖА из ЛР1
  ./help lr2 tbs [каталог]     - вынести ПРОДАЖА в табличное пространство (D:/PG_TBS)
  ./help lr2 time 20|22        - время запроса (*) по CURRENT_TIME, 5 замеров
  ./help lr2 timing 20|22      - время запроса (*) по \timing on, 5 замеров
  ./help lr2 idx 20|22         - индексы ПРОДАЖА и таблицы-справочника
  ./help lr2 idx1 20|22 [btree|hash] - создать индекс ПРОДАЖА по полю-ссылке
  ./help lr2 idx0 20|22        - удалить индекс ПРОДАЖА по полю-ссылке
  ./help lr2 pk1 20|22         - справочник с PRIMARY KEY (create_ref0)
  ./help lr2 pk0 20|22         - справочник без PRIMARY KEY (create_ref1)
  ./help lr2 copy 20|22        - перезагрузить справочник из DATA/SOURCE
  ./help lr2 explain 20|22 [1] - EXPLAIN / EXPLAIN ANALYZE (1 - с WHERE)
  ./help lr2 measure 20|22 [прогонов] - протокол замеров -> results/lr2_vNN_results.txt
  ./help lr2 results 20|22     - показать протокол замеров

================== ЛР3: ПОЛЬЗОВАТЕЛЬСКИЕ ТИПЫ ==================
  ./help lr3 cmplx             - пример преподавателя (complex)
  ./help lr3 20                - в.20: трёхмерный вектор (vector3)
  ./help lr3 22                - в.22: рациональное число (rational)

================== ЛР4: РЕЗЕРВНОЕ КОПИРОВАНИЕ ==================
  ./help lr4 all [20|22]       - пп. 1-10 целиком -> results/lr4_vNN_protocol.txt
  ./help lr4 base              - создать базу BASE из данных ЛР1
  ./help lr4 tasks N [база]    - контрольные задачи -> taskN-01..03
  ./help lr4 dump1|dump2|dump3 - pg_dump в файл / rar / многотомный rar
  (каталог копий: lab4/work или $env:LR4_WORK='D:/LR4_WORK'; ./help lr4 all)

================== ЛР5: ФУНКЦИИ НА C ==================
  ./help lr5 build 20|22       - компиляция и сборка vNN.dll (-> D:\PG_DLL)
  ./help lr5 20|22 [каталог]   - регистрация функций и демонстрация на таблице T

================== ЛР6: КОПИРОВАНИЕ В MS SQL SERVER ==================
  ./help lr6 setup             - проверка сервера (база NEW1, таблица temp1)
  ./help lr6 sel2              - собрать фильтр sel2.exe
  ./help lr6 createdb          - создать базу SALES в MS SQL Server
  ./help lr6 copy              - скопировать все таблицы sales из PostgreSQL
  ./help lr6 disp              - проверить скопированные таблицы
  ./help lr6 v20|v22 1|2 [параметры] - задания варианта в MS SQL Server
  ./help lr6 console           - консоль sqlcmd

================== ЛР7: ПРЕДСТАВЛЕНИЯ И ФУНКЦИИ MS SQL SERVER ==================
  ./help lr7 create            - создать представления и функции
  ./help lr7 1 [D1 D2 P M [N]] - премия сотрудников (N - имя сотрудника)
  ./help lr7 2 [D1 D2 alpha [G]] - затраты на хранение (G - товар)
  Пример: ./help lr7 1 01.01.2021 30.06.2021 8.5 10.5 Иван

================== ЛР8: ПРОГРАММЫ С ДАННЫМИ MS SQL SERVER ==================
  ./help lr8 build             - компиляция программы C# варианта 20
  ./help lr8 20 [D1 D2 [категория]] - в.20 (C#): продажи (шт) по категории и кварталу
  ./help lr8 22 [D1 D2 [поставщик]] - в.22 (Python): затраты клиентов по поставщику и декаде

================== ПРОЧЕЕ ==================
  ./help reports [N ...]       - пересобрать отчёты .docx (reports/docx)
  ./help psql                  - консоль psql (база sales)
  ./help файл.sql [a1 [a2 [a3]]] - выполнить любой psql-сценарий с параметрами
'@
    exit 1
}

if ($A[0] -like '*.sql') {
    Run $A[0] $A[1] $A[2] $A[3]
    exit 0
}

switch ($A[0]) {
    # ------------------------------ ЛР1 ------------------------------
    'db' {
        Run-Pg 'DATA/create_DB'
        Run 'DATA/create_tables' -Quiet
        Run 'DATA/load_data'
    }
    'counts' { Run 'helper/counts.sql' }
    { $_ -in 'v20', 'v22' } {
        Need-Task $A[1]
        Run "tasks/$($A[0])_task$($A[1]).sql" $A[2] $A[3] $A[4]
    }
    'all' {
        foreach ($t in 'v20_task1', 'v20_task2', 'v22_task1', 'v22_task2') {
            Run "tasks/$t.sql"
        }
    }

    'lr1' {
        switch ($A[1]) {
            'lan'    { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File lab1/setup_lan.ps1 }
            'client' {
                if (-not $A[2]) { Say 'Использование: ./help lr1 client сценарий [a1 a2 a3]'; exit 1 }
                Bat 'lab1/s_lan.bat' @(($A[2] -replace '/', '\'), $A[3], $A[4], $A[5])
            }
            default  { Say 'ОШИБКА: ./help lr1 lan|client' }
        }
    }

    # ------------------------------ ЛР2 ------------------------------
    'lr2' {
        $v = $A[2]
        switch ($A[1]) {
            'gen'     { Run 'lab2/add_data.sql' $A[2] }
            'restore' { Run 'lab2/restore_lr1.sql' }
            'tbs'     { Run 'lab2/tablespace.sql' $A[2] }
            'time'    { Need-Variant $v; Run 'lab2/time_current.sql' $v }
            'timing'  { Need-Variant $v; Run 'lab2/time_timing.sql' $v }
            'idx'     { Need-Variant $v; Run 'lab2/idx_names.sql' $v }
            'idx1'    { Need-Variant $v; Run 'lab2/idx_1.sql' $v $A[3] }
            'idx0'    { Need-Variant $v; Run 'lab2/idx_0.sql' $v }
            'pk1'     { Need-Variant $v; Run 'lab2/create_ref0.sql' $v }
            'pk0'     { Need-Variant $v; Run 'lab2/create_ref1.sql' $v }
            'copy'    { Need-Variant $v; Run 'lab2/copy_ref.sql' $v }
            'explain' { Need-Variant $v; Run 'lab2/explain.sql' $v $A[3] }
            'measure' { Need-Variant $v; Run 'lab2/measure.sql' $v $A[3]
                        Show-Text "results/lr2_v$($v)_results.txt" }
            'results' { Need-Variant $v; Show-Text "results/lr2_v$($v)_results.txt" }
            default   { Say 'ОШИБКА: ./help lr2 gen|restore|tbs|time|timing|idx|idx1|idx0|pk1|pk0|copy|explain|measure|results' }
        }
    }

    # ------------------------------ ЛР3 ------------------------------
    'lr3' {
        switch ($A[1]) {
            'cmplx' { Run 'lab3/cmplx.sql' }
            '20'    { Run 'lab3/v20_vector3.sql' }
            '22'    { Run 'lab3/v22_rational.sql' }
            default { Say 'ОШИБКА: ./help lr3 cmplx|20|22' }
        }
    }

    # ------------------------------ ЛР4 ------------------------------
    'lr4' {
        switch ($A[1]) {
            'all' {
                $v = if ($A[2]) { $A[2] } else { '20' }
                Need-Variant $v
                Bat 'lab4/run_all.bat' @($v) 'cp1251' "results/lr4_v$($v)_protocol.txt"
            }
            'base'  { Bat 'lab4/create_base.bat' @() 'cp1251' }
            'tasks' {
                if (-not $A[2]) { Say 'Использование: ./help lr4 tasks N [база]'; exit 1 }
                Bat 'lab4/tasks.bat' @($A[2], $A[3])
            }
            'dump1' { Bat 'lab4/dump-1.bat' }
            'dump2' { Bat 'lab4/dump-2.bat' }
            'dump3' { Bat 'lab4/dump-3.bat' @($A[2]) }
            default { Say 'ОШИБКА: ./help lr4 all|base|tasks|dump1|dump2|dump3' }
        }
    }

    # ------------------------------ ЛР5 ------------------------------
    'lr5' {
        switch ($A[1]) {
            'build' { Need-Variant $A[2]; Bat 'lab5/build.bat' @($A[2], $A[3]) 'cp866' }
            { $_ -in '20', '22' } { Run "lab5/v$($A[1])_test.sql" $A[2] }
            default { Say 'ОШИБКА: ./help lr5 build 20|22  или  ./help lr5 20|22' }
        }
    }

    # ------------------------------ ЛР6 ------------------------------
    'lr6' {
        switch ($A[1]) {
            'setup' {
                foreach ($f in 'create_DB', 'create_temp1', 'insert_temp1', 'select_from_temp1') {
                    Bat 'lab6/s_TCP.bat' @("lab6\SETUP\$f")
                }
            }
            'sel2'     { Bat 'lab6/COPY/make_sel2.bat' }
            'createdb' { Bat 'lab6/s_TCP.bat' @('lab6\COPY\create_DB') }
            'copy'     { Bat 'lab6/COPY/copy_to_MS_SQL.bat' @() 'cp1251' }
            'disp'     { Bat 'lab6/COPY/disp.bat' }
            { $_ -in 'v20', 'v22' } {
                Need-Task $A[2]
                Bat 'lab6/s.bat' @("lab6\tasks\$($A[1])_task$($A[2]).sql", $A[3], $A[4], $A[5])
            }
            'console'  { & .\lab6\s0.bat }
            default    { Say 'ОШИБКА: ./help lr6 setup|sel2|createdb|copy|disp|v20|v22|console' }
        }
    }

    # ------------------------------ ЛР7 ------------------------------
    'lr7' {
        switch ($A[1]) {
            'create' { Bat 'lab7/s.bat' @('lab7\create_objects.sql') }
            '1'      { Bat 'lab7/s.bat' @('lab7\calculate1.sql', $A[2], $A[3], $A[4], $A[5], $A[6]) }
            '2'      { Bat 'lab7/s.bat' @('lab7\calculate2.sql', $A[2], $A[3], $A[4], $A[5]) }
            default  { Say 'ОШИБКА: ./help lr7 create|1|2' }
        }
    }

    # ------------------------------ ЛР8 ------------------------------
    'lr8' {
        switch ($A[1]) {
            'build' { Bat 'lab8/v20/cs.bat' @() 'cp866' }
            '20'    { Bat 'lab8/v20/run.bat' @($Argv | Select-Object -Skip 2) }
            '22'    { Bat 'lab8/v22/run.bat' @($Argv | Select-Object -Skip 2) }
            default { Say 'ОШИБКА: ./help lr8 build|20|22' }
        }
    }

    'reports' {
        Push-Location reports
        & python make_reports.py @($Argv | Select-Object -Skip 1)
        Pop-Location
    }
    'psql'  { & psql.exe -X }
    default { Say "ОШИБКА: Неизвестная команда $($A[0]) (./help - список команд)" }
}
exit 0
