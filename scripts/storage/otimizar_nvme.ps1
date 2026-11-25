<#
.SYNOPSIS
    Otimiza armazenamento NVMe (CL4-8D512): TRIM, ReTrim, desativa Fast Startup e limpa temporarios.
.DESCRIPTION
    - Garante NTFS DisableDeleteNotify = 0 (TRIM ativo)
    - Executa ReTrim no volume C:
    - Desativa Fast Startup (HiberbootEnabled = 0) para evitar estado corrompido de drivers AMD/Realtek
    - Desativa desligamento de disco na tomada (AC = 0)
    - Remove arquivos temporarios nao bloqueados e reporta espaco liberado
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"

Write-Host "=== [1/4] Verificando TRIM e Executando ReTrim em C: ===" -ForegroundColor Cyan
fsutil behavior set DisableDeleteNotify 0 | Out-Null
Optimize-Volume -DriveLetter C -ReTrim -Verbose
Write-Host "[OK] TRIM ativo e ReTrim concluido em C:." -ForegroundColor Green

Write-Host "`n=== [2/4] Desativando Fast Startup (HiberbootEnabled = 0) ===" -ForegroundColor Cyan
$pwrKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
Set-ItemProperty -Path $pwrKey -Name "HiberbootEnabled" -Type DWord -Value 0
Write-Host "[OK] Fast Startup desativado (inicializacao limpa de drivers)." -ForegroundColor Green

Write-Host "`n=== [3/4] Ajustando Timeout de Disco na Tomada (AC) ===" -ForegroundColor Cyan
powercfg /setacvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 0 | Out-Null
powercfg /setactive SCHEME_CURRENT | Out-Null
Write-Host "[OK] Desligamento de disco na tomada definido para 0 (Nunca)." -ForegroundColor Green

Write-Host "`n=== [4/4] Limpando Arquivos Temporarios Seguros ===" -ForegroundColor Cyan
$beforeFree = (Get-Volume -DriveLetter C).SizeRemaining
$tempPaths = @(
    $env:TEMP,
    "C:\Windows\Temp"
)
foreach ($tp in $tempPaths) {
    if (Test-Path $tp) {
        Get-ChildItem -Path $tp -Force -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
        Write-Host "[OK] Limpeza executada em: $tp" -ForegroundColor Green
    }
}
$afterFree = (Get-Volume -DriveLetter C).SizeRemaining
$freedMB = [math]::Round(($afterFree - $beforeFree) / 1MB, 2)
Write-Host "[INFO] Espaco livre antes: $([math]::Round($beforeFree/1GB, 2)) GB | depois: $([math]::Round($afterFree/1GB, 2)) GB (delta: ${freedMB} MB)" -ForegroundColor Gray

Write-Host "`n[CONCLUIDO] Otimizacao de armazenamento NVMe finalizada." -ForegroundColor Cyan
