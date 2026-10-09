# ЛР1: настройка сервера PostgreSQL для работы в локальной сети (запускать от имени администратора)
#   powershell -ExecutionPolicy Bypass -File lan_server\setup_lan.ps1 [-Net 192.168.0.0/24]
# 1) добавляет в pg_hba.conf правило доступа из локальной сети с аутентификацией scram-sha-256;
# 2) создаёт правило брандмауэра Windows PostgreSQL-inPort (входящие TCP 5432);
# 3) перечитывает конфигурацию сервера.
# Для входа по сети у пользователя postgres должен быть задан пароль:  ALTER USER postgres PASSWORD '...';
param(
    [string]$Net = "192.168.0.0/24",
    [string]$Data = "C:\Program Files\PostgreSQL\18\data",
    [string]$Bin = "C:\Program Files\PostgreSQL\18\bin"
)
$hba = Join-Path $Data "pg_hba.conf"
$rule = "host    all             all             $Net          scram-sha-256"
if (-not (Select-String -Path $hba -SimpleMatch $Net -Quiet)) {
    Copy-Item $hba "$hba.bak" -Force
    Add-Content -Path $hba -Value "`r`n# ЛР1: доступ из локальной сети`r`n$rule" -Encoding ASCII
    Write-Host "pg_hba.conf: добавлено правило: $rule (копия - pg_hba.conf.bak)"
} else {
    Write-Host "pg_hba.conf: правило для $Net уже есть"
}
if (-not (Get-NetFirewallRule -DisplayName "PostgreSQL-inPort" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "PostgreSQL-inPort" -Direction Inbound -Protocol TCP `
        -LocalPort 5432 -Action Allow -Profile Private,Public | Out-Null
    Write-Host "Брандмауэр: создано правило PostgreSQL-inPort (TCP 5432, входящие)"
} else {
    Write-Host "Брандмауэр: правило PostgreSQL-inPort уже есть"
}
& "$Bin\pg_ctl.exe" reload -D $Data
