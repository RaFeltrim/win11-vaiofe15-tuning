# 07 — Windows 11 Pro 25H2 Debloat & Startup

## Repositórios de Referência

- [Raphire/Win11Debloat](https://github.com/Raphire/Win11Debloat) — Referência principal de debloat seguro e reversível para Windows 11 24H2/25H2.
- [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil) — Referência para políticas de telemetria, serviços e manutenção.

## Alterações Aplicadas (`scripts/debloat/run_win11_debloat.ps1`)

1. **Remoção Segura de AppX Bloatware:**
   - Remove apps pré-instalados não essenciais (Bing News/Weather/Finance/Sports/Search, Clipchamp, Solitaire, Feedback Hub, Get Help, Get Started, People, Power Automate Desktop, Quick Assist, Todos, Cortana, Copilot, Widgets/WebExperience, YourPhone).
   - **Preservados intactos:** Microsoft Store, Xbox / Game Bar, OneDrive, Windows Terminal, WebView2, Calculadora e Fotos.
2. **Telemetria, Anúncios e UI:**
   - Desativa `DiagTrack` e `dmwappushservice`.
   - Desativa `AllowTelemetry = 0`, Bing Search no Menu Iniciar, Copilot, Widgets na Barra de Tarefas e sugestões/anúncios (`ContentDeliveryManager`).
3. **Limpeza de Startup (`HKCU\Run`):**
   - Remove entradas redundantes/pesadas: `OneDriveSetup` (estava triplicado), `MicrosoftEdgeAutoLaunch_*`, `Opera GX Browser Assistant`, `EpicGamesLauncher` e `BraveSoftware Update`.
   - Mantém intactos: `OneDrive`, `Steam`, `Discord`, `RiotClient`, `Riot Vanguard`, `Docker Desktop`, `WallpaperEngine` e ferramentas do usuário.

## Uso Interativo Opcional do `Raphire/Win11Debloat`

Se desejar personalizações adicionais de interface (barra de tarefas, menu de contexto clássico, etc.), você pode executar a interface oficial do `Win11Debloat`:

```powershell
& ([scriptblock]::Create((irm "https://debloat.raphi.re/")))
```

## Reversão

- Para restaurar o Startup original: `reg import backups\<timestamp>\hkcu_run.reg`.
- Para reativar telemetria/serviços: `Set-Service DiagTrack -StartupType Automatic; Start-Service DiagTrack`.
- Qualquer pacote AppX removido pode ser reinstalado diretamente pela **Microsoft Store**.
