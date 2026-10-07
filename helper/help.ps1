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
function Run([string]$file, [string]$a1, [string]$a2, [string]$a3, [string]$a4, [string]$a5,
             [switch]$Quiet) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        Say "ОШИБКА: Файл $file не найден"
        exit 1
    }
    if (-not $Quiet) { Say ">>> Файл: $file" }
    $text = ''
    $i = 1
    foreach ($a in @($a1, $a2, $a3, $a4, $a5)) {
        $text += "\set arg$i '" + ($a -replace "'", "''") + "'`n"
        $i++
    }
    $text += "\i '" + ($file -replace '\\', '/') + "'`n"
    Invoke-Raw 'psql.exe -q -X -P pager=off -P "null=<null>" -f -' $text 'cp1251' -Quiet:$Quiet
}

# psql-сценарий в системной базе postgres (как s1.bat)
function Run-Pg([string]$file) {
    Say ">>> Файл: $file (база postgres)"
    $db = $env:PGDATABASE
    $env:PGDATABASE = 'postgres'
    Invoke-Raw ('psql.exe -q -X -P pager=off -f ' + (Q $file)) $null 'cp1251'
    $env:PGDATABASE = $db
}

# командный файл Windows: полный путь в формате Windows (с относительным путём в кавычках
# cmd неверно вычисляет %~dp0 после cd внутри .bat), параметры как есть
function Bat([string]$file, [string[]]$params, [string]$Cp, [string]$Tee) {
    Say ">>> Файл: $file"
    $line = Q (Join-Path $Root ($file -replace '/', '\'))
    foreach ($a in $params) { $line += ' ' + (Q $a) }
    Invoke-Raw $line $null $Cp $Tee
}

# адрес сервера [пользователь@]хост[:порт] -> переменные окружения ${prefix}HOST, PORT, USER
function Set-Addr([string]$prefix, [string]$addr) {
    if ($addr -match '^(.+?)@(.+)$') { Set-Item "env:$($prefix)USER" $Matches[1]; $addr = $Matches[2] }
    if ($addr -match '^(.+):(\d+)$') { Set-Item "env:$($prefix)PORT" $Matches[2]; $addr = $Matches[1] }
    Set-Item "env:$($prefix)HOST" $addr
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

# команды-аналоги TAXI-db: таблица helper/menu.txt (код|файл|параметры|обязательных|описание)
$MenuFile = 'helper/menu.txt'
function Read-Menu {
    [IO.File]::ReadAllLines((Join-Path $Root $MenuFile), $Utf8) |
        Where-Object { $_ -and -not $_.StartsWith('#') }
}

function Show-Menu {
    foreach ($l in Read-Menu) {
        if ($l.StartsWith('== ')) {
            Say ''
            Say ('================== БАЗА SALES: ' + $l.Substring(3) + ' ==================')
            continue
        }
        $f = $l.Split('|')
        $cmd = "./help $($f[0])"
        if ($f[2]) { $cmd += " $($f[2])" }
        Say ('  {0,-36} - {1}  [{2}]' -f $cmd, $f[4], $f[1])
        if ($f.Count -gt 5 -and $f[5]) { Say ('  {0,-36}   пример: ./help {1} {2}' -f '', $f[0], $f[5]) }
    }
}

$Argv = @($args)
$A = $Argv + @('', '', '', '', '', '', '', '') | ForEach-Object { [string]$_ }

if (-not $A[0]) {
    Say @'
=============================================
  ПАБД: БАЗА ДАННЫХ SALES, ВАРИАНТЫ 20 И 22
=============================================
  В [] - файл, который выполняет команда; при запуске он выводится строкой ">>> Файл: ...".
  Обработчик каждой команды - helper/help.ps1 (switch, ветвь с именем команды).

================== ЛР1: БАЗА И ЗАДАНИЯ ==================
  ./help db              - создать БД sales, таблицы и загрузить данные  [DATA/create_DB, DATA/create_tables, DATA/load_data]
  ./help counts          - количество строк в таблицах  [helper/counts.sql]
  ./help v20 1 [дата1 дата2 [категория]]  - в.20: объём поставок по категории и кварталу  [tasks/v20_task1.sql]
  ./help v20 2 [год1 год2 [день недели]]  - в.20: продажи (шт) по дню недели и району  [tasks/v20_task2.sql]
  ./help v22 1 [дата1 дата2 [поставщик]]  - в.22: выручка по поставщику и декаде  [tasks/v22_task1.sql]
  ./help v22 2 [год1 год2 [время года]]   - в.22: затраты клиентов по сезону и полу  [tasks/v22_task2.sql]
  ./help all             - все 4 задания с параметрами по умолчанию  [tasks/*.sql]
  ./help lr1 lan         - настроить pg_hba.conf и брандмауэр для сети (от администратора)  [lab1/setup_lan.ps1]
  ./help lr1 client [адрес] сценарий [a1 a2 a3] - сценарий через s_lan.bat на сервере в сети (по умолч. postgres@192.168.0.102:5432)  [lab1/s_lan.bat]
                                         пример: ./help lr1 client 192.168.0.102 tasks/v20_task1.sql 01.01.2021 31.12.2022 мебель
                                                 ./help lr1 client postgres@192.168.0.102:5432 tasks/v22_task1.sql 01.07.2019 30.06.2023 "ООО Турман"
  ./help srv [адрес] [check]   - сервер в сети PMII (по умолч. stud@192.168.1.50:5432): подключение и таблицы  [lab1/check_server.sql]
                                         пример: ./help srv 192.168.1.50 check
  ./help srv [адрес] v20|v22 1|2 [параметры] - задание варианта на сервере в сети  [tasks/vNN_taskN.sql]
                                         пример: ./help srv 192.168.1.50 v20 1 01.01.2021 31.12.2022 мебель
                                                 ./help srv stud@192.168.1.50:5432 v22 2 2018 2022 зима
  ./help srv [адрес] all       - проверка и все 4 задания на сервере; ./help srv [адрес] psql - консоль
  (адрес - [пользователь@]хост[:порт]; пароль - $env:SRV_PASS или pgpass.conf)
  Пример: ./help v20 1 01.01.2021 31.12.2022 мебель

================== ЛР2: ОБЪЁМНАЯ БД, ИНДЕКСЫ, EXPLAIN ==================
  ./help lr2 gen [N]           - ПРОДАЖА: N псевдослучайных записей (по умолч. 2 000 000)  [lab2/add_data.sql]
                                         пример: ./help lr2 gen 2000000
  ./help lr2 restore           - вернуть 1000 записей ПРОДАЖА из ЛР1  [lab2/restore_lr1.sql]
  ./help lr2 tbs [каталог]     - вынести ПРОДАЖА в табличное пространство (D:/PG_TBS)  [lab2/tablespace.sql]
                                         пример: ./help lr2 tbs D:/PG_TBS
  ./help lr2 time 20|22 [замеров]   - время запроса (*) по CURRENT_TIME (по умолч. 5 замеров)  [lab2/time_current.sql]
                                         пример: ./help lr2 time 20 5      ./help lr2 time 22 10
  ./help lr2 timing 20|22 [замеров] - время запроса (*) по \timing on (по умолч. 5 замеров)  [lab2/time_timing.sql]
                                         пример: ./help lr2 timing 20 5    ./help lr2 timing 22 10
  ./help lr2 idx 20|22         - индексы ПРОДАЖА и таблицы-справочника  [lab2/idx_names.sql]
                                         пример: ./help lr2 idx 20
  ./help lr2 idx1 20|22 [btree|hash] - создать индекс ПРОДАЖА по полю-ссылке  [lab2/idx_1.sql]
                                         пример: ./help lr2 idx1 22 hash
  ./help lr2 idx0 20|22        - удалить индекс ПРОДАЖА по полю-ссылке  [lab2/idx_0.sql]
                                         пример: ./help lr2 idx0 22
  ./help lr2 pk1 20|22         - справочник с PRIMARY KEY  [lab2/create_ref0.sql]
                                         пример: ./help lr2 pk1 20
  ./help lr2 pk0 20|22         - справочник без PRIMARY KEY  [lab2/create_ref1.sql]
                                         пример: ./help lr2 pk0 20
  ./help lr2 copy 20|22        - перезагрузить справочник из DATA/SOURCE  [lab2/copy_ref.sql]
                                         пример: ./help lr2 copy 22
  ./help lr2 explain 20|22 [1] - EXPLAIN / EXPLAIN ANALYZE (1 - с WHERE)  [lab2/explain.sql]
                                         пример: ./help lr2 explain 20 1
  ./help lr2 measure 20|22 [прогонов] - протокол замеров -> results/lr2_vNN_results.txt  [lab2/measure.sql]
                                         пример: ./help lr2 measure 22 3
  ./help lr2 results 20|22     - показать протокол замеров  [results/lr2_vNN_results.txt]
                                         пример: ./help lr2 results 20
  (запрос (*) и настройки варианта: lab2/vNN_query.sql, lab2/vNN_config.sql, lab2/config.sql)

================== ЗАЩИТА ЛР2: ИНДЕКСЫ И ВРЕМЯ ЗАПРОСА ==================
  ./help zas 20 [all] ["поставщик1" "поставщик2"] - в.20: задания 1-3 подряд  [zashita/z_all.sql]
                                         пример: ./help zas 20 all "ООО Турман" "ЧП Загорье"
  ./help zas 22 [all] [категория]  - в.22: задания 1-3 подряд  [zashita/z_all.sql]
                                         пример: ./help zas 22 all мебель
  ./help zas 20|22 1 [параметры]   - 1) запрос варианта и результат  [zashita/z1_query.sql, zashita/vNN_query.sql]
                                         пример: ./help zas 20 1 "ООО Турман" "ЧП Загорье"
  ./help zas 20|22 2 [параметры]   - 2) в.20 без индексов, в.22 с индексом ПРОДАЖА(товар) btree: 5 замеров, мс и мин, минимум  [zashita/z2_noidx.sql]
                                         пример: ./help zas 22 2 мебель
  ./help zas 20|22 3 [параметры]   - 3) индексы варианта, замер(ы) и EXPLAIN ANALYZE  [zashita/z3_idx.sql]
                                         пример: ./help zas 22 3 мебель
  ./help zas 20|22 idx             - индексы таблиц запроса варианта  [zashita/show_idx.sql]
                                         пример: ./help zas 22 idx
  ./help zas restore               - удалить индексы защиты, вернуть PRIMARY KEY  [zashita/restore.sql]
  (нужна объёмная ПРОДАЖА: ./help lr2 gen; в.20 по умолч. "ООО Турман" "ЧП Загорье", в.22 - мебель)

================== ЛР3: ПОЛЬЗОВАТЕЛЬСКИЕ ТИПЫ ==================
  ./help lr3 cmplx             - пример преподавателя (complex)  [lab3/cmplx.sql]
  ./help lr3 20                - в.20: трёхмерный вектор (vector3)  [lab3/v20_vector3.sql]
  ./help lr3 22                - в.22: рациональное число (rational)  [lab3/v22_rational.sql]

================== ЛР4: РЕЗЕРВНОЕ КОПИРОВАНИЕ ==================
  ./help lr4 all [20|22 [каталог]] - пп. 1-10 целиком -> results/lr4_vNN_protocol.txt  [lab4/run_all.bat]
                                         пример: ./help lr4 all 20      ./help lr4 all 22 D:/LR4_WORK
  ./help lr4 base [база]       - создать базу (по умолч. base) из данных ЛР1  [lab4/create_base.bat]
                                         пример: ./help lr4 base base
  ./help lr4 tasks N [база] [20|22] - контрольные задачи варианта -> taskN-01..03  [lab4/tasks.bat]
                                         пример: ./help lr4 tasks 0 base 20      ./help lr4 tasks 0 base 22
  ./help lr4 dump1|dump2 [база] - pg_dump в файл / rar  [lab4/dump-1.bat, dump-2.bat]
                                         пример: ./help lr4 dump1 base      ./help lr4 dump2 base
  ./help lr4 dump3 [том [база]] - pg_dump в многотомный rar (размер тома, по умолч. 8k)  [lab4/dump-3.bat]
                                         пример: ./help lr4 dump3 10k base
  (каталог копий по умолч. lab4/work; база по умолч. base, настройки - lab4/config.bat)

================== ЛР5: ФУНКЦИИ НА C ==================
  ./help lr5 build 20|22       - компиляция и сборка vNN.dll (-> D:\PG_DLL)  [lab5/build.bat]
  ./help lr5 20|22 [каталог]   - регистрация функций и демонстрация на таблице T  [lab5/vNN_test.sql]

================== ЛР6: КОПИРОВАНИЕ В MS SQL SERVER ==================
  ./help lr6 setup             - проверка сервера (база NEW1, таблица temp1)  [lab6/s_TCP.bat + lab6/SETUP/*]
  ./help lr6 sel2              - собрать фильтр sel2.exe  [lab6/COPY/make_sel2.bat]
  ./help lr6 createdb          - создать базу SALES в MS SQL Server  [lab6/COPY/create_DB]
  ./help lr6 copy              - скопировать все таблицы sales из PostgreSQL  [lab6/COPY/copy_to_MS_SQL.bat]
  ./help lr6 disp              - проверить скопированные таблицы  [lab6/COPY/disp.bat]
  ./help lr6 v20|v22 1|2 [параметры] - задания варианта в MS SQL Server  [lab6/tasks/vNN_taskN.sql]
  ./help lr6 console           - консоль sqlcmd  [lab6/s0.bat]

================== ЛР7: ПРЕДСТАВЛЕНИЯ И ФУНКЦИИ MS SQL SERVER ==================
  ./help lr7 create            - создать представления и функции  [lab7/create_objects.sql]
  ./help lr7 1 [D1 D2 P M [N]] - премия сотрудников (N - имя сотрудника)  [lab7/calculate1.sql]
  ./help lr7 2 [D1 D2 alpha [G]] - затраты на хранение (G - товар)  [lab7/calculate2.sql]
  Пример: ./help lr7 1 01.01.2021 30.06.2021 8.5 10.5 Иван

================== ЛР8: ПРОГРАММЫ С ДАННЫМИ MS SQL SERVER ==================
  ./help lr8 build             - компиляция программы C# варианта 20  [lab8/v20/cs.bat]
  ./help lr8 20 [D1 D2 [категория]] - в.20 (C#): продажи (шт) по категории и кварталу  [lab8/v20/run.bat]
  ./help lr8 22 [D1 D2 [поставщик]] - в.22 (Python): затраты клиентов по поставщику и декаде  [lab8/v22/run.bat]
'@
    Show-Menu
    Say @'

================== ЗАПУСК SQL-ФАЙЛОВ ==================
  ./help файл.sql [a1 .. a5]   - выполнить любой psql-сценарий с параметрами arg1..arg5
  ./help psql                  - консоль psql (база sales)
  ./help reports [N ...]       - пересобрать отчёты .docx  [reports/make_reports.py]
'@
    exit 1
}

if ($A[0] -like '*.sql') {
    Run $A[0] $A[1] $A[2] $A[3] $A[4] $A[5]
    exit 0
}

# команды-аналоги TAXI-db (./help 01 ... ./help 204): файл и параметры - из helper/menu.txt
$hit = Read-Menu | Where-Object { -not $_.StartsWith('== ') -and $_.Split('|')[0] -eq $A[0] } |
       Select-Object -First 1
if ($hit) {
    $f = $hit.Split('|')
    $given = @($A[1..5] | Where-Object { $_ }).Count
    if ($given -lt [int]$f[3]) {
        Say "Использование: ./help $($f[0]) $($f[2])   ($($f[4]))"
        if ($f.Count -gt 5 -and $f[5]) { Say "Пример:        ./help $($f[0]) $($f[5])" }
        exit 1
    }
    Say ">>> ./help $($f[0]) - $($f[4])"
    Run $f[1] $A[1] $A[2] $A[3] $A[4] $A[5]
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
                # необязательный адрес сервера перед сценарием: [пользователь@]хост[:порт]
                if ($A[3] -and -not (Test-Path -LiteralPath $A[2] -PathType Leaf) -and
                    (Test-Path -LiteralPath $A[3] -PathType Leaf)) {
                    Set-Addr 'LAN_' $A[2]
                    $A = @($A[0], $A[1]) + $A[3..($A.Count - 1)]
                }
                if (-not $A[2]) { Say 'Использование: ./help lr1 client [пользователь@]хост[:порт] сценарий [a1 a2 a3]'; exit 1 }
                Bat 'lab1/s_lan.bat' @(($A[2] -replace '/', '\'), $A[3], $A[4], $A[5])
            }
            default  { Say 'ОШИБКА: ./help lr1 lan|client' }
        }
    }

    # сервер преподавателя в сети PMII: те же сценарии ЛР1, подключение по IP
    'srv' {
        $env:PGHOST     = if ($env:SRV_HOST) { $env:SRV_HOST } else { '192.168.1.50' }
        $env:PGPORT     = if ($env:SRV_PORT) { $env:SRV_PORT } else { '5432' }
        $env:PGUSER     = if ($env:SRV_USER) { $env:SRV_USER } else { 'stud' }
        $env:PGPASSWORD = if ($env:SRV_PASS) { $env:SRV_PASS } else { '12345' }
        $env:PGDATABASE = 'sales'
        $env:PGCONNECT_TIMEOUT = '10'
        # необязательный адрес сервера: [пользователь@]хост[:порт] (содержит . @ или :)
        if ($A[1] -match '[.@:]') {
            Set-Addr 'PG' $A[1]
            $A = @($A[0]) + $A[2..($A.Count - 1)]
        }
        Say "Сервер: $($env:PGHOST):$($env:PGPORT), база $($env:PGDATABASE), пользователь $($env:PGUSER)"
        switch ($A[1]) {
            { $_ -in '', 'check' } { Run 'lab1/check_server.sql' }
            { $_ -in 'v20', 'v22' } {
                Need-Task $A[2]
                Run "tasks/$($A[1])_task$($A[2]).sql" $A[3] $A[4] $A[5]
            }
            'all' {
                Run 'lab1/check_server.sql'
                foreach ($t in 'v20_task1', 'v20_task2', 'v22_task1', 'v22_task2') {
                    Run "tasks/$t.sql"
                }
            }
            'psql'  { & psql.exe }
            default { Say 'ОШИБКА: ./help srv [check|all|psql|v20 N|v22 N [параметры]]' }
        }
    }

    # ------------------------------ ЛР2 ------------------------------
    'lr2' {
        $v = $A[2]
        switch ($A[1]) {
            'gen'     { Run 'lab2/add_data.sql' $A[2] }
            'restore' { Run 'lab2/restore_lr1.sql' }
            'tbs'     { Run 'lab2/tablespace.sql' $A[2] }
            'time'    { Need-Variant $v; Run 'lab2/time_current.sql' $v $A[3] }
            'timing'  { Need-Variant $v; Run 'lab2/time_timing.sql' $v $A[3] }
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
                if ($A[3]) { $env:LR4_WORK = $A[3] -replace '/', '\' }
                Bat 'lab4/run_all.bat' @($v) 'cp1251' "results/lr4_v$($v)_protocol.txt"
            }
            'base'  {
                if ($A[2]) { $env:LR4_BASE = $A[2] }
                Bat 'lab4/create_base.bat' @() 'cp1251'
            }
            'tasks' {
                if (-not $A[2]) { Say 'Использование: ./help lr4 tasks N [база] [20|22]'; exit 1 }
                # необязательные параметры в любом порядке: 20|22 - вариант, иначе - база
                $db = ''
                foreach ($p in $A[3], $A[4]) {
                    if ($p -in '20', '22') { $env:LR4_VARIANT = $p }
                    elseif ($p) { $db = $p }
                }
                Bat 'lab4/tasks.bat' @($A[2], $db)
            }
            { $_ -in 'dump1', 'dump2' } {
                if ($A[2]) { $env:LR4_BASE = $A[2] }
                Bat "lab4/dump-$($A[1].Substring(4)).bat"
            }
            'dump3' {
                if ($A[3]) { $env:LR4_BASE = $A[3] }
                Bat 'lab4/dump-3.bat' @($A[2])
            }
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

    # защита ЛР2: запрос варианта без индексов и с индексами (zashita/*.sql)
    'zas' {
        if ($A[1] -eq 'restore') { Run 'zashita/restore.sql' }
        else {
            Need-Variant $A[1]
            $step = if ($A[2]) { $A[2] } else { 'all' }
            $file = @{ 'all' = 'zashita/z_all.sql'; '1' = 'zashita/z1_query.sql'
                       '2' = 'zashita/z2_noidx.sql'; '3' = 'zashita/z3_idx.sql' }[$step]
            if ($step -eq 'idx') { Run 'zashita/show_idx.sql' $A[1] }
            elseif (-not $file) {
                Say 'ОШИБКА: ./help zas 20|22 [all|1|2|3|idx] [параметры]  или  ./help zas restore'
                exit 1
            }
            else { Run $file $A[1] $A[3] $A[4] }
        }
    }
    default { Say "ОШИБКА: Неизвестная команда $($A[0]) (./help - список команд)" }
}
exit 0
