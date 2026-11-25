<#
.SYNOPSIS
    Otimiza a placa Wi-Fi Realtek RTL8821CE 802.11ac PCIe para eliminar picos de latencia e travamentos em lives.
.DESCRIPTION
    - PnPCapabilities = 24 (impede o Windows de desligar o adaptador)
    - bLeisurePs = 0 e LpsEn = 0 (desativa Leisure Power Save do firmware Realtek 8821CE)
    - Desativa 802.11d e Multi-Channel Concurrent (reduz scans periodicos em segundo plano)
    - Desativa algoritmo de Nagle (TcpAckFrequency = 1, TCPNoDelay = 1) na interface Wi-Fi
    - Define DNS Cloudflare (1.1.1.1 / 1.0.0.1 e IPv6) e limpa cache DNS
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"

Write-Host "=== [1/4] Ajustando Registro do Driver Realtek RTL8821CE ===" -ForegroundColor Cyan
$netClassBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
$wifiKey = Get-ChildItem $netClassBase -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -match '^\d{4}$' } |
    Where-Object { (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DriverDesc -like "*8821CE*" } |
    Select-Object -First 1

if ($wifiKey) {
    Write-Host "[INFO] Chave encontrada: $($wifiKey.PSChildName) ($((Get-ItemProperty $wifiKey.PSPath).DriverDesc))" -ForegroundColor Gray
    Set-ItemProperty -Path $wifiKey.PSPath -Name "PnPCapabilities" -Type DWord -Value 24
    Set-ItemProperty -Path $wifiKey.PSPath -Name "bLeisurePs" -Type String -Value "0"
    Set-ItemProperty -Path $wifiKey.PSPath -Name "LpsEn" -Type String -Value "0"
    Set-ItemProperty -Path $wifiKey.PSPath -Name "PowerSaveMode" -Type String -Value "0"
    Write-Host "[OK] PnPCapabilities = 24 | bLeisurePs = 0 | LpsEn = 0 | PowerSaveMode = 0" -ForegroundColor Green
}
else {
    Write-Host "[WARN] Adaptador Realtek 8821CE nao encontrado no registro." -ForegroundColor Yellow
}

Write-Host "`n=== [2/4] Desativando 802.11d e Multi-Channel Concurrent ===" -ForegroundColor Cyan
$advProps = @(
    @{ Name = "802.11d"; Value = "0" },
    @{ Name = "Multi-Channel Concurrent"; Value = "0" }
)
foreach ($prop in $advProps) {
    $existing = Get-NetAdapterAdvancedProperty -Name "Wi-Fi" -DisplayName $prop.Name -ErrorAction SilentlyContinue
    if ($existing) {
        try {
            Set-NetAdapterAdvancedProperty -Name "Wi-Fi" -DisplayName $prop.Name -RegistryValue $prop.Value -NoRestart -ErrorAction Stop
            Write-Host "[OK] $($prop.Name) -> RegistryValue=$($prop.Value)" -ForegroundColor Green
        }
        catch {
            Write-Host "[WARN] Nao foi possivel alterar $($prop.Name): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n=== [3/4] Desativando Algoritmo de Nagle na Interface Wi-Fi ===" -ForegroundColor Cyan
$wifiAdapter = Get-NetAdapter -Name "Wi-Fi" -ErrorAction SilentlyContinue
if ($wifiAdapter) {
    $ifaceGuid = $wifiAdapter.InterfaceGuid
    $tcpIfacePath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$ifaceGuid"
    if (Test-Path $tcpIfacePath) {
        Set-ItemProperty -Path $tcpIfacePath -Name "TcpAckFrequency" -Type DWord -Value 1
        Set-ItemProperty -Path $tcpIfacePath -Name "TCPNoDelay" -Type DWord -Value 1
        Write-Host "[OK] TcpAckFrequency = 1 | TCPNoDelay = 1 em $ifaceGuid" -ForegroundColor Green
    }
}

Write-Host "`n=== [4/4] Configurando DNS Cloudflare (IPv4 + IPv6) ===" -ForegroundColor Cyan
try {
    Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("1.1.1.1", "1.0.0.1", "2606:4700:4700::1111", "2606:4700:4700::1001") -ErrorAction Stop
    Clear-DnsClientCache
    Write-Host "[OK] DNS Cloudflare configurado e cache DNS limpo." -ForegroundColor Green
}
catch {
    Write-Host "[WARN] Falha ao configurar DNS: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n[CONCLUIDO] Otimizacao Wi-Fi Realtek RTL8821CE aplicada. Reinicie o notebook para efetivar bLeisurePs/PnPCapabilities." -ForegroundColor Cyan
