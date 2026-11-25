<#
.SYNOPSIS
    Otimiza gerenciamento de memoria para 32 GB DDR4-3200 Dual Channel + NVMe.
.DESCRIPTION
    Baseado em amitxv/PC-Tuning e NicholasBly/Windows-11-Latency-Optimization.
    - Desativa MemoryCompression (desnecessaria com 32 GB RAM e consome CPU)
    - Desativa servico SysMain / Superfetch (redundante com NVMe + 32 GB RAM)
    - Ativa DisablePagingExecutive = 1 (mantem drivers/kernel na RAM fisica)
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"

$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0)
Write-Host "[INFO] RAM fisica detectada: $ramGB GB" -ForegroundColor Gray

Write-Host "=== [1/3] Desativando Memory Compression ===" -ForegroundColor Cyan
if ($ramGB -ge 16) {
    Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
    Write-Host "[OK] MemoryCompression desativada (efetivo apos reinicio)." -ForegroundColor Green
}
else {
    Write-Host "[WARN] RAM < 16 GB: mantendo MemoryCompression ativa por seguranca." -ForegroundColor Yellow
}

Write-Host "`n=== [2/3] Desativando SysMain (Superfetch) ===" -ForegroundColor Cyan
$sysMain = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
if ($sysMain) {
    Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "[OK] Servico SysMain parado e desativado." -ForegroundColor Green
}

Write-Host "`n=== [3/3] Mantendo Kernel e Drivers na RAM Fisica ===" -ForegroundColor Cyan
$memPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-ItemProperty -Path $memPath -Name "DisablePagingExecutive" -Type DWord -Value 1
Set-ItemProperty -Path $memPath -Name "LargeSystemCache" -Type DWord -Value 0
Write-Host "[OK] DisablePagingExecutive = 1 | LargeSystemCache = 0" -ForegroundColor Green

Write-Host "`n[CONCLUIDO] Otimizacao de RAM 32 GB aplicada." -ForegroundColor Cyan
