<#
.SYNOPSIS
    Configura o Opera GX para usar ANGLE D3D11 (use-angle@1), garante aceleracao de hardware ativa e desativa RGX/Lucid Mode (sharpen_videos = false).
.DESCRIPTION
    Corrige a saturacao do motor 3D da iGPU AMD Radeon Vega 8 (94%+ em 2560x1440) causada pelo filtro RGX (sharpen_videos).
    Faz backup automatico de Local State e Default\Preferences antes de editar.
#>

$ErrorActionPreference = "Continue"

$operaDataDir = Join-Path $env:APPDATA "Opera Software\Opera GX Stable"
$localStatePath = Join-Path $operaDataDir "Local State"
$prefsPath = Join-Path $operaDataDir "Default\Preferences"
$operaExe = Join-Path $env:LOCALAPPDATA "Programs\Opera GX\opera.exe"

if (-not (Test-Path $localStatePath) -or -not (Test-Path $prefsPath)) {
    Write-Host "[WARN] Arquivos do Opera GX nao encontrados em: $operaDataDir" -ForegroundColor Yellow
    exit 0
}

Write-Host "=== [1/4] Backup de Configuracoes do Opera GX ===" -ForegroundColor Cyan
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$rootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$backupDir = Join-Path $rootDir "backups\opera-gx-$timestamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Copy-Item $localStatePath (Join-Path $backupDir "Local State") -Force
Copy-Item $prefsPath (Join-Path $backupDir "Preferences") -Force
Write-Host "[OK] Backup salvo em: $backupDir" -ForegroundColor Green

Write-Host "`n=== [2/4] Fechando Opera GX para Aplicar Configuracoes ===" -ForegroundColor Cyan
$runningOpera = Get-Process -Name "opera" -ErrorAction SilentlyContinue
if ($runningOpera) {
    $runningOpera | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "[OK] Opera GX encerrado com seguranca." -ForegroundColor Green
}

Write-Host "`n=== [3/4] Configurando ANGLE = D3D11 (use-angle@1) e Hardware Acceleration ===" -ForegroundColor Cyan
$lsJson = Get-Content $localStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not ($lsJson.PSObject.Properties.Name -contains "browser")) {
    $lsJson | Add-Member -MemberType NoteProperty -Name "browser" -Value ([PSCustomObject]@{})
}
if (-not ($lsJson.browser.PSObject.Properties.Name -contains "enabled_labs_experiments")) {
    $lsJson.browser | Add-Member -MemberType NoteProperty -Name "enabled_labs_experiments" -Value @()
}
$labs = @($lsJson.browser.enabled_labs_experiments | Where-Object { $_ -notlike "use-angle@*" })
$labs += "use-angle@1"
$lsJson.browser.enabled_labs_experiments = $labs

if (-not ($lsJson.PSObject.Properties.Name -contains "hardware_acceleration_mode")) {
    $lsJson | Add-Member -MemberType NoteProperty -Name "hardware_acceleration_mode" -Value ([PSCustomObject]@{ enabled = $true })
}
else {
    $lsJson.hardware_acceleration_mode.enabled = $true
}

$lsOut = $lsJson | ConvertTo-Json -Depth 100 -Compress
[System.IO.File]::WriteAllText($localStatePath, $lsOut, [System.Text.UTF8Encoding]::new($false))
Write-Host "[OK] Local State atualizado: use-angle@1 (D3D11) + hardware_acceleration_mode.enabled = true" -ForegroundColor Green

Write-Host "`n=== [4/4] Desativando RGX / Lucid Mode (sharpen_videos = false) ===" -ForegroundColor Cyan
$prefRaw = [System.IO.File]::ReadAllText($prefsPath, [System.Text.UTF8Encoding]::new($false))
$beforeMatches = ([regex]::Matches($prefRaw, '"sharpen_videos"\s*:\s*true')).Count
$prefNew = [regex]::Replace($prefRaw, '"sharpen_videos"\s*:\s*true', '"sharpen_videos":false')
[System.IO.File]::WriteAllText($prefsPath, $prefNew, [System.Text.UTF8Encoding]::new($false))
Write-Host "[OK] Preferences atualizado: $beforeMatches ocorrencia(s) de sharpen_videos alteradas de true -> false." -ForegroundColor Green

if (Test-Path $operaExe) {
    Start-Process -FilePath $operaExe
    Write-Host "[OK] Opera GX reiniciado." -ForegroundColor Green
}

Write-Host "`n[CONCLUIDO] Otimizacao do Opera GX (D3D11 + RGX OFF) concluida." -ForegroundColor Cyan
