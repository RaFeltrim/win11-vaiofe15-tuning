<#
.SYNOPSIS
    Otimiza a iGPU AMD Radeon Vega 8 (Lucienne) e corrige travamentos de video/lives no Opera GX no Windows 11 25H2.
.DESCRIPTION
    Baseado em RedDot-3ND7355/MPO-GPU-FIX, imribiy/amd-gpu-tweaks e GSDragoon/RadeonSoftwareSlimmer.
    - Desativa MPO (OverlayTestMode = 5 + DisableOverlays = 1 para Win11 25H2)
    - Desativa ULPS (EnableUlps = 0)
    - Ajusta TdrDelay = 10 para evitar resets prematuros do driver em decodificacao de video
    - Desativa servico de telemetria AMD Crash Defender (mantem protecoes termicas intactas)
    NOTA: Reinicie o Windows apos executar. NUNCA faca hot-restart de driver de video.
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"

Write-Host "=== [1/4] Desativando MPO (Multi-Plane Overlay) - Fix Opera GX / Chromium ===" -ForegroundColor Cyan
$dwmPath = "HKLM:\SOFTWARE\Microsoft\Windows\Dwm"
if (-not (Test-Path $dwmPath)) { New-Item -Path $dwmPath -Force | Out-Null }
Set-ItemProperty -Path $dwmPath -Name "OverlayTestMode" -Type DWord -Value 5
Write-Host "[OK] Dwm\OverlayTestMode = 5" -ForegroundColor Green

$gfxPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
Set-ItemProperty -Path $gfxPath -Name "DisableOverlays" -Type DWord -Value 1
Set-ItemProperty -Path $gfxPath -Name "TdrDelay" -Type DWord -Value 10
Set-ItemProperty -Path $gfxPath -Name "TdrDdiDelay" -Type DWord -Value 10
Write-Host "[OK] GraphicsDrivers\DisableOverlays = 1, TdrDelay = 10, TdrDdiDelay = 10" -ForegroundColor Green

Write-Host "`n=== [2/4] Localizando Chave da iGPU AMD Radeon Vega 8 ===" -ForegroundColor Cyan
$gpuClassBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
$amdKey = Get-ChildItem $gpuClassBase -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -match '^\d{4}$' } |
    Where-Object { (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DriverDesc -like "*AMD Radeon*" } |
    Select-Object -First 1

if ($amdKey) {
    Write-Host "[INFO] Chave encontrada: $($amdKey.PSChildName) ($((Get-ItemProperty $amdKey.PSPath).DriverDesc))" -ForegroundColor Gray
    Set-ItemProperty -Path $amdKey.PSPath -Name "EnableUlps" -Type DWord -Value 0
    Set-ItemProperty -Path $amdKey.PSPath -Name "EnableUlps_NA" -Type String -Value "0"
    Set-ItemProperty -Path $amdKey.PSPath -Name "StutterMode" -Type DWord -Value 0
    Write-Host "[OK] EnableUlps = 0, EnableUlps_NA = 0, StutterMode = 0" -ForegroundColor Green
}
else {
    Write-Host "[WARN] Chave AMD Radeon nao encontrada automaticamente." -ForegroundColor Yellow
}

Write-Host "`n=== [3/4] Reduzindo Telemetria AMD (Preservando Protecoes Termicas) ===" -ForegroundColor Cyan
$amdTelemetryServices = @("AMD Crash Defender Service")
foreach ($svcName in $amdTelemetryServices) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc) {
        Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "[OK] Servico desativado: $svcName" -ForegroundColor Green
    }
}

Write-Host "`n=== [4/4] Configurando Preferencia de Alto Desempenho GPU para Opera GX ===" -ForegroundColor Cyan
$operaExe = "$env:LOCALAPPDATA\Programs\Opera GX\opera.exe"
if (Test-Path $operaExe) {
    $gpuPrefPath = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
    if (-not (Test-Path $gpuPrefPath)) { New-Item -Path $gpuPrefPath -Force | Out-Null }
    Set-ItemProperty -Path $gpuPrefPath -Name $operaExe -Type String -Value "GpuPreference=2;"
    Write-Host "[OK] DirectX GpuPreference=2 aplicada para Opera GX ($operaExe)" -ForegroundColor Green
}

Write-Host "`n[CONCLUIDO] Tweaks de iGPU Vega 8 e MPO aplicados. Reinicie o notebook para efetivar." -ForegroundColor Cyan
