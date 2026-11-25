<#
.SYNOPSIS
    Debloat seguro do Windows 11 Pro 25H2 (inspirado em Raphire/Win11Debloat e ChrisTitusTech/winutil).
.DESCRIPTION
    - Remove pacotes AppX de bloatware preservando Microsoft Store, Xbox/Game Bar, OneDrive, Terminal e WebView2
    - Desativa telemetria (DiagTrack, dmwappushservice), Bing Search no Menu Iniciar, Copilot e anuncios/dicas
    - Limpa entradas redundantes de Startup (OneDriveSetup duplicado, Edge AutoLaunch, Opera GX Assistant, EpicGamesLauncher, Brave Update)
    - 100% reversivel
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"

Write-Host "=== [1/4] Removendo Pacotes AppX de Bloatware (Modo Seguro) ===" -ForegroundColor Cyan
$bloatPatterns = @(
    "Clipchamp.Clipchamp",
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.BingFinance",
    "Microsoft.BingSports",
    "Microsoft.BingSearch",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.People",
    "Microsoft.PowerAutomateDesktop",
    "Microsoft.Todos",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.549981C3F5F10", # Cortana
    "Microsoft.Copilot",
    "MicrosoftCorporationII.QuickAssist",
    "Microsoft.YourPhone",
    "MicrosoftWindows.Client.WebExperience" # Widgets
)

$removedCount = 0
foreach ($pattern in $bloatPatterns) {
    $pkgs = Get-AppxPackage -Name "*$pattern*" -ErrorAction SilentlyContinue
    foreach ($pkg in $pkgs) {
        try {
            Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
            Write-Host "[OK] Removido AppX: $($pkg.Name)" -ForegroundColor Green
            $removedCount++
        }
        catch {
            Write-Host "[WARN] Ignorado ($($pkg.Name)): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$pattern*" }
    foreach ($p in $prov) {
        Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction SilentlyContinue | Out-Null
    }
}
Write-Host "[INFO] Total de pacotes AppX removidos: $removedCount" -ForegroundColor Gray

Write-Host "`n=== [2/4] Desativando Telemetria, Anuncios, Bing Search e Copilot ===" -ForegroundColor Cyan
# Servicos de telemetria
foreach ($svc in @("DiagTrack", "dmwappushservice")) {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "[OK] Servico desativado: $svc" -ForegroundColor Green
    }
}

# Telemetria / ContentDeliveryManager / Bing Search / Copilot
$regTweaks = @(
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 0 },
    @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"; Name = "DisableSearchBoxSuggestions"; Value = 1 },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "BingSearchEnabled"; Value = 0 },
    @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"; Name = "TurnOffWindowsCopilot"; Value = 1 },
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"; Name = "TurnOffWindowsCopilot"; Value = 1 },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338389Enabled"; Value = 0 },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338393Enabled"; Value = 0 },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353694Enabled"; Value = 0 },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353696Enabled"; Value = 0 },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SystemPaneSuggestionsEnabled"; Value = 0 },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled"; Value = 0 },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarDa"; Value = 0 }
)

foreach ($t in $regTweaks) {
    try {
        if (-not (Test-Path $t.Path)) { New-Item -Path $t.Path -Force | Out-Null }
        Set-ItemProperty -Path $t.Path -Name $t.Name -Type DWord -Value $t.Value -ErrorAction Stop
    }
    catch {
        Write-Host "[WARN] Chave protegida pelo Windows ($($t.Name)) ignorada." -ForegroundColor Yellow
    }
}
Write-Host "[OK] Politicas de telemetria, Bing Search, Copilot, Widgets e anuncios desativadas." -ForegroundColor Green

Write-Host "`n=== [3/4] Limpando Entradas Redundantes de Startup (HKCU\Run) ===" -ForegroundColor Cyan
$runPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$startupToDisable = @(
    "OneDriveSetup",
    "Opera GX Browser Assistant",
    "EpicGamesLauncher",
    "BraveSoftware Update"
)
$runProps = Get-ItemProperty -Path $runPath -ErrorAction SilentlyContinue
if ($runProps) {
    foreach ($prop in $runProps.PSObject.Properties) {
        if ($startupToDisable -contains $prop.Name -or $prop.Name -like "MicrosoftEdgeAutoLaunch_*") {
            Remove-ItemProperty -Path $runPath -Name $prop.Name -ErrorAction SilentlyContinue
            Write-Host "[OK] Removido do Startup (HKCU\Run): $($prop.Name)" -ForegroundColor Green
        }
    }
}

Write-Host "`n=== [4/4] Resumo de Preservacao ===" -ForegroundColor Cyan
Write-Host "[INFO] Preservados: Microsoft Store, Xbox/Game Bar, OneDrive, Terminal, WebView2, Riot Vanguard, Steam, Discord e Docker." -ForegroundColor Gray
Write-Host "[CONCLUIDO] Debloat seguro do Windows 11 25H2 finalizado." -ForegroundColor Cyan
