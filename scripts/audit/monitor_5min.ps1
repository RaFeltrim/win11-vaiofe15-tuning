<#
.SYNOPSIS
    Monitora telemetria completa do VAIO FE15 por 5 minutos (CPU, iGPU 3D/Video Decode, RAM, Wi-Fi ping/jitter, Disco e Opera GX).
.PARAMETER DurationSeconds
    Duracao total da coleta em segundos (padrao: 300 = 5 minutos).
.PARAMETER IntervalSeconds
    Intervalo entre amostras em segundos (padrao: 5).
.PARAMETER OutputPath
    Caminho do relatorio .txt salvo em benchmarks/.
#>

param(
    [int]$DurationSeconds = 300,
    [int]$IntervalSeconds = 5,
    [string]$OutputPath = ""
)

$ErrorActionPreference = "SilentlyContinue"
$rootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $rootDir "benchmarks\monitor-5min-post-reboot.txt"
}
$outDir = Split-Path -Parent $OutputPath
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

$samplesCount = [int][math]::Ceiling($DurationSeconds / $IntervalSeconds)
$gw = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Sort-Object RouteMetric | Select-Object -First 1).NextHop
$ping = New-Object System.Net.NetworkInformation.Ping

$records = New-Object System.Collections.Generic.List[object]
$startTime = Get-Date

Write-Host "=== Iniciando monitoramento continuo de $DurationSeconds segundos ($samplesCount amostras, intervalo ${IntervalSeconds}s) ===" -ForegroundColor Cyan

for ($i = 1; $i -le $samplesCount; $i++) {
    $t0 = Get-Date

    # CPU & Disk & GPU counters
    $cpuPct = 0.0
    $diskPct = 0.0
    $gpu3dPct = 0.0
    $gpuVidPct = 0.0
    $gpuDedMB = 0.0
    $gpuShrMB = 0.0

    try {
        $cpuCim = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -ErrorAction SilentlyContinue
        if ($cpuCim) { $cpuPct = [math]::Round([double]$cpuCim.PercentProcessorTime, 1) }
        $diskCim = Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Filter "Name='_Total'" -ErrorAction SilentlyContinue
        if ($diskCim) { $diskPct = [math]::Round([double]$diskCim.PercentDiskTime, 1) }
    } catch {}

    try {
        $gpuEng = (Get-Counter "\GPU Engine(*)\Utilization Percentage" -ErrorAction SilentlyContinue).CounterSamples
        $sum3d = 0.0
        $sumVid = 0.0
        foreach ($g in $gpuEng) {
            if ($g.InstanceName -like "*engtype_3D*") { $sum3d += $g.CookedValue }
            elseif ($g.InstanceName -like "*engtype_VideoDecode*" -or $g.InstanceName -like "*engtype_VideoProcessing*") { $sumVid += $g.CookedValue }
        }
        $gpu3dPct = [math]::Round([math]::Min($sum3d, 100.0), 1)
        $gpuVidPct = [math]::Round([math]::Min($sumVid, 100.0), 1)
    } catch {}

    try {
        $gpuMem = (Get-Counter "\GPU Adapter Memory(*)\Dedicated Usage","\GPU Adapter Memory(*)\Shared Usage" -ErrorAction SilentlyContinue).CounterSamples
        $dedBytes = ($gpuMem | Where-Object { $_.Path -like "*dedicated usage*" } | Measure-Object CookedValue -Sum).Sum
        $shrBytes = ($gpuMem | Where-Object { $_.Path -like "*shared usage*" } | Measure-Object CookedValue -Sum).Sum
        $gpuDedMB = [math]::Round($dedBytes / 1MB, 1)
        $gpuShrMB = [math]::Round($shrBytes / 1MB, 1)
    } catch {}

    # RAM & Opera GX
    $os = Get-CimInstance Win32_OperatingSystem
    $ramUsedGB = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
    $operaProcs = Get-Process -Name "opera" -ErrorAction SilentlyContinue
    $operaMemMB = [math]::Round((($operaProcs | Measure-Object WorkingSet64 -Sum).Sum) / 1MB, 1)

    # Ping router & 1.1.1.1
    $pingGw = -1
    $pingNet = -1
    if ($gw) {
        try {
            $r1 = $ping.Send($gw, 1500)
            if ($r1.Status -eq 'Success') { $pingGw = [int]$r1.RoundtripTime }
        } catch {}
    }
    try {
        $r2 = $ping.Send("1.1.1.1", 1500)
        if ($r2.Status -eq 'Success') { $pingNet = [int]$r2.RoundtripTime }
    } catch {}

    $rec = [PSCustomObject]@{
        Sample     = $i
        Time       = (Get-Date -Format "HH:mm:ss")
        CpuPct     = $cpuPct
        Gpu3dPct   = $gpu3dPct
        GpuVidPct  = $gpuVidPct
        GpuDedMB   = $gpuDedMB
        GpuShrMB   = $gpuShrMB
        RamUsedGB  = $ramUsedGB
        OperaMB    = $operaMemMB
        DiskPct    = $diskPct
        PingGwMs   = $pingGw
        PingNetMs  = $pingNet
    }
    $records.Add($rec)

    if (($i % 12) -eq 0 -or $i -eq 1 -or $i -eq $samplesCount) {
        Write-Host ("[{0:D2}/{1:D2} {2}] CPU={3}% | GPU3D={4}% | GPUVid={5}% | VRAM={6}MB+{7}MB | RAM={8}GB | Opera={9}MB | PingGW={10}ms | Ping1.1.1.1={11}ms" -f `
            $i, $samplesCount, $rec.Time, $rec.CpuPct, $rec.Gpu3dPct, $rec.GpuVidPct, $rec.GpuDedMB, $rec.GpuShrMB, $rec.RamUsedGB, $rec.OperaMB, $rec.PingGwMs, $rec.PingNetMs) -ForegroundColor Gray
    }

    if ($i -lt $samplesCount) {
        $elapsed = ((Get-Date) - $t0).TotalMilliseconds
        $sleepMs = [int]([math]::Max(200, ($IntervalSeconds * 1000) - $elapsed))
        Start-Sleep -Milliseconds $sleepMs
    }
}

$endTime = Get-Date

function Get-Stats([double[]]$vals) {
    $valid = $vals | Where-Object { $_ -ge 0 }
    if (-not $valid -or $valid.Count -eq 0) { return "N/A" }
    $sorted = $valid | Sort-Object
    $min = [math]::Round(($valid | Measure-Object -Minimum).Minimum, 2)
    $avg = [math]::Round(($valid | Measure-Object -Average).Average, 2)
    $max = [math]::Round(($valid | Measure-Object -Maximum).Maximum, 2)
    $p95Idx = [int][math]::Floor(($sorted.Count - 1) * 0.95)
    $p95 = [math]::Round($sorted[$p95Idx], 2)
    return "Min=$min | Avg=$avg | P95=$p95 | Max=$max"
}

$gwValid = @($records | Where-Object { $_.PingGwMs -ge 0 } | ForEach-Object { [double]$_.PingGwMs })
$netValid = @($records | Where-Object { $_.PingNetMs -ge 0 } | ForEach-Object { [double]$_.PingNetMs })
$gwLost = ($records | Where-Object { $_.PingGwMs -lt 0 }).Count
$netLost = ($records | Where-Object { $_.PingNetMs -lt 0 }).Count
$gwSpikes = ($gwValid | Where-Object { $_ -ge 20 }).Count
$netSpikes = ($netValid | Where-Object { $_ -ge 50 }).Count

$gwDiffs = @(); for ($j = 1; $j -lt $gwValid.Count; $j++) { $gwDiffs += [math]::Abs($gwValid[$j] - $gwValid[$j-1]) }
$netDiffs = @(); for ($j = 1; $j -lt $netValid.Count; $j++) { $netDiffs += [math]::Abs($netValid[$j] - $netValid[$j-1]) }
$gwJitter = if ($gwDiffs.Count -gt 0) { [math]::Round(($gwDiffs | Measure-Object -Average).Average, 2) } else { 0 }
$netJitter = if ($netDiffs.Count -gt 0) { [math]::Round(($netDiffs | Measure-Object -Average).Average, 2) } else { 0 }

# Check GPU driver errors during monitoring window
$gpuErrors = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='amdwddmg','amdkmdag','Display'; StartTime=$startTime} -ErrorAction SilentlyContinue

$sb = [System.Text.StringBuilder]::new()
function Add-L([string]$s) { [void]$sb.AppendLine($s) }

Add-L "======================================================================"
Add-L " WIN11 VAIO FE15 TUNING - MONITORAMENTO CONTINUO (5 MINUTOS)"
Add-L " Inicio: $($startTime.ToString('yyyy-MM-dd HH:mm:ss')) | Fim: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Add-L " Amostras: $($records.Count) (intervalo ~${IntervalSeconds}s)"
Add-L "======================================================================"
Add-L ""
Add-L "--- RESUMO ESTATISTICO ---"
Add-L "CPU Utilizacao (%)          : $(Get-Stats ($records.CpuPct))"
Add-L "iGPU Vega 8 - 3D (%)        : $(Get-Stats ($records.Gpu3dPct))"
Add-L "iGPU Vega 8 - VideoDec (%)  : $(Get-Stats ($records.GpuVidPct))"
Add-L "iGPU VRAM Dedicada (MB)     : $(Get-Stats ($records.GpuDedMB))"
Add-L "iGPU VRAM Compartilhada (MB): $(Get-Stats ($records.GpuShrMB))"
Add-L "RAM Usada Total (GB)        : $(Get-Stats ($records.RamUsedGB))"
Add-L "Opera GX RAM (MB)           : $(Get-Stats ($records.OperaMB))"
Add-L "NVMe Disk Busy (%)          : $(Get-Stats ($records.DiskPct))"
Add-L "Wi-Fi Ping GW ($gw) (ms) : $(Get-Stats $gwValid) | Jitter=${gwJitter}ms | Spikes(>=20ms)=$gwSpikes | Lost=$gwLost"
Add-L "Wi-Fi Ping 1.1.1.1 (ms)     : $(Get-Stats $netValid) | Jitter=${netJitter}ms | Spikes(>=50ms)=$netSpikes | Lost=$netLost"
Add-L "Erros Driver GPU no Periodo : $(if ($gpuErrors) { $gpuErrors.Count } else { 0 })"
Add-L ""
Add-L "--- SERIE TEMPORAL COMPLETA ---"
Add-L (($records | Format-Table -AutoSize | Out-String).TrimEnd())

$sb.ToString() | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "`n[OK] Relatorio de 5 minutos salvo em: $OutputPath" -ForegroundColor Green
Get-Content $OutputPath | Select-Object -First 28
