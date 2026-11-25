<#
.SYNOPSIS
    Otimiza CPU AMD Ryzen 7 5700U (Lucienne 8C/16T), MMCSS e gestao de energia segura para notebook.
.DESCRIPTION
    Baseado em amitxv/PC-Tuning e boas praticas para Ryzen Mobile 5000U.
    - Ajusta MMCSS (NetworkThrottlingIndex, SystemResponsiveness, prioridade de audio/video/jogos)
    - Desbloqueia visibilidade de Processor Performance Boost Mode no plano de energia
    - Configura Boost Mode = Efficient Aggressive (4) na tomada e Efficient Enabled (3) na bateria
    - Desativa PCIe Link State Power Management e USB Selective Suspend na tomada (AC)
    - NAO altera VBS/HVCI nem carrega WinRing0 (100% seguro com Riot Vanguard)
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"

Write-Host "=== [1/3] Otimizando MMCSS (Responsividade, Video e Audio) ===" -ForegroundColor Cyan
$mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
Set-ItemProperty -Path $mmPath -Name "NetworkThrottlingIndex" -Type DWord -Value 0xffffffff
Set-ItemProperty -Path $mmPath -Name "SystemResponsiveness" -Type DWord -Value 10
Write-Host "[OK] NetworkThrottlingIndex = 0xFFFFFFFF | SystemResponsiveness = 10" -ForegroundColor Green

$gamesTask = Join-Path $mmPath "Tasks\Games"
if (Test-Path $gamesTask) {
    Set-ItemProperty -Path $gamesTask -Name "GPU Priority" -Type DWord -Value 8
    Set-ItemProperty -Path $gamesTask -Name "Priority" -Type DWord -Value 6
    Set-ItemProperty -Path $gamesTask -Name "Scheduling Category" -Type String -Value "High"
    Set-ItemProperty -Path $gamesTask -Name "SFIO Priority" -Type String -Value "High"
    Write-Host "[OK] MMCSS Tasks\Games otimizado (GPU Priority=8, Priority=6, High)" -ForegroundColor Green
}

$playbackTask = Join-Path $mmPath "Tasks\Playback"
if (Test-Path $playbackTask) {
    Set-ItemProperty -Path $playbackTask -Name "GPU Priority" -Type DWord -Value 8
    Set-ItemProperty -Path $playbackTask -Name "Priority" -Type DWord -Value 6
    Set-ItemProperty -Path $playbackTask -Name "Scheduling Category" -Type String -Value "High"
    Set-ItemProperty -Path $playbackTask -Name "SFIO Priority" -Type String -Value "High"
    Write-Host "[OK] MMCSS Tasks\Playback otimizado para lives/streaming sem engasgos" -ForegroundColor Green
}

Write-Host "`n=== [2/3] Ajustando Plano de Energia para Ryzen 7 5700U (Notebook) ===" -ForegroundColor Cyan
# Revela "Modo de aumento de desempenho do processador" no Painel de Controle
$boostAttrKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7"
if (Test-Path $boostAttrKey) {
    Set-ItemProperty -Path $boostAttrKey -Name "Attributes" -Type DWord -Value 2
    Write-Host "[OK] Processor Performance Boost Mode desbloqueado nas Opcoes de Energia." -ForegroundColor Green
}

# Aplica ajustes no plano ativo:
# Boost Mode: 4 = Efficient Aggressive (AC), 3 = Efficient Enabled (DC)
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR be337238-0d82-4146-a960-4f3749d470c7 4 | Out-Null
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR be337238-0d82-4146-a960-4f3749d470c7 3 | Out-Null

# PCIe Link State Power Management: 0 = Off (AC)
powercfg /setacvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ee12f906-d277-404b-b6da-e5fa1a576df5 0 | Out-Null

# USB Selective Suspend: 0 = Disabled (AC)
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 | Out-Null

# Wireless Adapter Settings -> Power Saving Mode: 0 = Maximum Performance (AC)
powercfg /setacvalueindex SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 | Out-Null

powercfg /setactive SCHEME_CURRENT | Out-Null
Write-Host "[OK] Plano de energia atualizado (Boost AC=Efficient Aggressive, PCIe/USB/Wi-Fi AC=Max Performance)." -ForegroundColor Green

Write-Host "`n=== [3/3] Verificacao de Seguranca (VBS/HVCI) ===" -ForegroundColor Cyan
Write-Host "[INFO] VBS/HVCI mantido intacto para preservar compatibilidade com Riot Vanguard." -ForegroundColor Gray
Write-Host "[CONCLUIDO] Otimizacao de CPU Ryzen 7 5700U concluida." -ForegroundColor Cyan
