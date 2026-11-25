<#
.SYNOPSIS
    Coleta snapshot completo de telemetria, registro, rede, RAM, CPU, iGPU e armazenamento.
.PARAMETER OutputPath
    Caminho do arquivo .txt de saida (ex: benchmarks/baseline-system.txt ou benchmarks/after-system.txt).
.PARAMETER Label
    Rotulo do snapshot (ex: BASELINE ou AFTER).
#>

param(
    [string]$OutputPath = "",
    [string]$Label = "SNAPSHOT"
)

$ErrorActionPreference = "SilentlyContinue"
$rootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $rootDir "benchmarks\snapshot-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
}
$outDir = Split-Path -Parent $OutputPath
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$sb = [System.Text.StringBuilder]::new()
function Add-Line([string]$text) { [void]$sb.AppendLine($text) }

Add-Line "======================================================================"
Add-Line " WIN11 VAIO FE15 TUNING - AUDIT SNAPSHOT ($Label)"
Add-Line " Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
Add-Line "======================================================================"

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like '*AMD*' } | Select-Object -First 1
$disk = Get-PhysicalDisk | Select-Object -First 1
$volC = Get-Volume -DriveLetter C
$wifi = Get-NetAdapter -Name "Wi-Fi"

$totalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeRamGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedRamGB  = [math]::Round($totalRamGB - $freeRamGB, 2)
$ramUsedPct = [math]::Round(($usedRamGB / $totalRamGB) * 100, 1)

Add-Line "`n--- [1] HARDWARE & OS ---"
Add-Line "Modelo       : $($cs.Manufacturer) / $($cs.Model)"
Add-Line "OS           : $($os.Caption) (Version $($os.Version), Build $($os.BuildNumber))"
Add-Line "CPU          : $($cpu.Name.Trim()) ($($cpu.NumberOfCores)C/$($cpu.NumberOfLogicalProcessors)T, Load=$($cpu.LoadPercentage)%)"
Add-Line "iGPU         : $($gpu.Name) | Driver=$($gpu.DriverVersion) | Res=$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)@$($gpu.CurrentRefreshRate)Hz"
Add-Line "RAM          : Total=$totalRamGB GB | Usada=$usedRamGB GB ($ramUsedPct%) | Livre=$freeRamGB GB"
Add-Line "NVMe         : $($disk.FriendlyName) ($($disk.BusType)) | Livre C:=$([math]::Round($volC.SizeRemaining/1GB, 2)) GB / $([math]::Round($volC.Size/1GB, 2)) GB"
Add-Line "Wi-Fi        : $($wifi.InterfaceDescription) | Link=$($wifi.LinkSpeed) | Status=$($wifi.Status)"

Add-Line "`n--- [2] PROCESSOS, SERVICOS & BLOAT ---"
$procCount = (Get-Process).Count
$svcRunning = (Get-Service | Where-Object Status -eq 'Running').Count
$appxCount = (Get-AppxPackage).Count
$startupCount = (Get-CimInstance Win32_StartupCommand).Count
$operaProcs = Get-Process -Name "opera"
$operaMemMB = [math]::Round((($operaProcs | Measure-Object WorkingSet64 -Sum).Sum) / 1MB, 1)
$radeonProcs = Get-Process -Name "RadeonSoftware","AMDRSServ","AMDRSSrcExt","atiesrxx","atieclxx"
$radeonMemMB = [math]::Round((($radeonProcs | Measure-Object WorkingSet64 -Sum).Sum) / 1MB, 1)
$defenderProc = Get-Process -Name "MsMpEng"
$defenderMemMB = if ($defenderProc) { [math]::Round($defenderProc.WorkingSet64 / 1MB, 1) } else { 0 }

Add-Line "Processos Totais      : $procCount"
Add-Line "Servicos em Execucao  : $svcRunning"
Add-Line "Pacotes AppX          : $appxCount"
Add-Line "Itens de Startup      : $startupCount"
Add-Line "Opera GX              : $($operaProcs.Count) processos | $operaMemMB MB RAM"
Add-Line "Processos AMD Radeon  : $($radeonProcs.Count) processos | $radeonMemMB MB RAM"
Add-Line "Windows Defender      : $defenderMemMB MB RAM"

Add-Line "`n--- [3] ESTADO DE REGISTRO E TUNING ---"
$gpuReg = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
$dwmReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\Dwm"
$gfxReg = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
$wifiReg = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001"
$mmReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
$pwrReg = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$mmAgent = Get-MMAgent
$sysMain = Get-Service SysMain
$diagTrack = Get-Service DiagTrack
$dnsV4 = (Get-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -AddressFamily IPv4).ServerAddresses -join ", "
$activePlan = (powercfg /getactivescheme) -join " "

Add-Line "Power Plan                 : $activePlan"
Add-Line "GPU EnableUlps             : $($gpuReg.EnableUlps)"
Add-Line "DWM OverlayTestMode (MPO)  : $($dwmReg.OverlayTestMode)"
Add-Line "Gfx DisableOverlays (25H2) : $($gfxReg.DisableOverlays)"
Add-Line "Gfx TdrDelay               : $($gfxReg.TdrDelay)"
Add-Line "Wi-Fi PnPCapabilities      : $($wifiReg.PnPCapabilities)"
Add-Line "Wi-Fi bLeisurePs           : $($wifiReg.bLeisurePs)"
Add-Line "Wi-Fi DNS IPv4             : $dnsV4"
Add-Line "MMCSS NetworkThrottlingIdx : $($mmReg.NetworkThrottlingIndex)"
Add-Line "MMCSS SystemResponsiveness : $($mmReg.SystemResponsiveness)"
Add-Line "RAM MemoryCompression      : $($mmAgent.MemoryCompression)"
Add-Line "Service SysMain            : $($sysMain.Status) ($($sysMain.StartType))"
Add-Line "Service DiagTrack          : $($diagTrack.Status) ($($diagTrack.StartType))"
Add-Line "NVMe HiberbootEnabled      : $($pwrReg.HiberbootEnabled)"

Add-Line "`n--- [4] BENCHMARK DE LATENCIA & JITTER WI-FI (20 pacotes) ---"
function Test-PingStats([string]$target, [int]$count = 20) {
    $times = @()
    $lost = 0
    $ping = New-Object System.Net.NetworkInformation.Ping
    for ($i = 0; $i -lt $count; $i++) {
        try {
            $reply = $ping.Send($target, 1500)
            if ($reply.Status -eq 'Success') {
                $times += [double]$reply.RoundtripTime
            } else {
                $lost++
            }
        } catch {
            $lost++
        }
        Start-Sleep -Milliseconds 100
    }
    if ($times.Count -gt 0) {
        $min = ($times | Measure-Object -Minimum).Minimum
        $max = ($times | Measure-Object -Maximum).Maximum
        $avg = [math]::Round(($times | Measure-Object -Average).Average, 2)
        $diffs = @()
        for ($j = 1; $j -lt $times.Count; $j++) { $diffs += [math]::Abs($times[$j] - $times[$j-1]) }
        $jitter = if ($diffs.Count -gt 0) { [math]::Round(($diffs | Measure-Object -Average).Average, 2) } else { 0 }
        return "Target=$target | Min=${min}ms | Avg=${avg}ms | Max=${max}ms | Jitter=${jitter}ms | Lost=$lost/$count"
    }
    return "Target=$target | FAILED ($lost/$count lost)"
}
$gw = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Sort-Object RouteMetric | Select-Object -First 1).NextHop
if ($gw) { Add-Line (Test-PingStats -target $gw -count 20) }
Add-Line (Test-PingStats -target "1.1.1.1" -count 20)

Add-Line "`n--- [5] MICRO-BENCHMARK CPU SINGLE-THREAD (Primos ate 120.000) ---"
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$primeCount = 0
for ($n = 2; $n -le 120000; $n++) {
    $isPrime = $true
    $limit = [int][math]::Sqrt($n)
    for ($d = 2; $d -le $limit; $d++) {
        if (($n % $d) -eq 0) { $isPrime = $false; break }
    }
    if ($isPrime) { $primeCount++ }
}
$sw.Stop()
Add-Line "CPU Prime Bench (2..120000): $primeCount primos em $($sw.ElapsedMilliseconds) ms"

Add-Line "`n--- [6] TOP 10 PROCESSOS POR MEMORIA ---"
$topMem = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 Name, Id, @{N='MemMB';E={[math]::Round($_.WorkingSet64/1MB,1)}} | Format-Table -AutoSize | Out-String
Add-Line $topMem.TrimEnd()

$sb.ToString() | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "[OK] Snapshot salvo em: $OutputPath" -ForegroundColor Green
Get-Content $OutputPath
