<#
.SYNOPSIS
    Cria Ponto de Restauracao do Windows e exporta backups .reg de todas as chaves modificadas.
.DESCRIPTION
    Parte do projeto win11-vaiofe15-tuning (VAIO FE15 - Ryzen 7 5700U / Vega 8).
    Salva os arquivos .reg em ./backups/<timestamp>/ (ignorado pelo Git).
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$rootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$backupDir = Join-Path $rootDir "backups\$timestamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Write-Host "=== [1/3] Criando Ponto de Restauracao do Sistema ===" -ForegroundColor Cyan
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    # Permite criar ponto mesmo que outro tenha sido criado nas ultimas 24h
    $srKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
    Set-ItemProperty -Path $srKey -Name "SystemRestorePointCreationFrequency" -Type DWord -Value 0 -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "Pre-Win11-VAIOFE15-Tuning-$timestamp" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-Host "[OK] Ponto de Restauracao criado com sucesso." -ForegroundColor Green
}
catch {
    Write-Host "[WARN] Nao foi possivel criar Ponto de Restauracao automaticamente: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n=== [2/3] Exportando Chaves de Registro ===" -ForegroundColor Cyan
$keysToBackup = @{
    "gpu_class_0000.reg"        = "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
    "dwm.reg"                   = "HKLM\SOFTWARE\Microsoft\Windows\Dwm"
    "graphics_drivers.reg"      = "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    "wifi_class_0001.reg"       = "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001"
    "tcpip_interfaces.reg"      = "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    "multimedia_system.reg"     = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    "session_manager_power.reg" = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
    "hkcu_run.reg"              = "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    "hklm_run.reg"              = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
}

foreach ($item in $keysToBackup.GetEnumerator()) {
    $outFile = Join-Path $backupDir $item.Key
    $regPath = $item.Value
    $res = reg export $regPath $outFile /y 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Exportado: $($item.Key)" -ForegroundColor Green
    }
    else {
        Write-Host "[WARN] Chave ausente ou ignorada ($regPath): $res" -ForegroundColor Yellow
    }
}

Write-Host "`n=== [3/3] Exportando Plano de Energia Ativo ===" -ForegroundColor Cyan
$activeSchemeLine = (powercfg /getactivescheme) -join " "
if ($activeSchemeLine -match '([0-9a-fA-F-]{36})') {
    $guid = $Matches[1]
    $powFile = Join-Path $backupDir "powerplan-$guid.pow"
    powercfg /export $powFile $guid | Out-Null
    Write-Host "[OK] Plano de energia $guid exportado para $powFile" -ForegroundColor Green
}

Write-Host "`n[CONCLUIDO] Backups salvos em: $backupDir" -ForegroundColor Cyan
