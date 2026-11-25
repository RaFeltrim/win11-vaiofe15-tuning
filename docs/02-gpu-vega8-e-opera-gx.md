# 02 — iGPU AMD Radeon Vega 8 (Lucienne) & Fix de Travamentos no Opera GX

## Diagnóstico do Problema (Lives Travando no Opera GX)

Na auditoria inicial do VAIO FE15 (`AMD Radeon Vega 8`, `DEV_164C`, `512 MB` UMA dedicada, driver `31.0.21923.11000`, tela `2560x1440 @ 60Hz`, Windows 11 Pro 25H2 Build `26200`), identificamos a causa clássica de travamentos/freezes de vídeo em navegadores Chromium (Opera GX, Chrome, Edge):

1. **MPO (Multi-Plane Overlay) ativo no Windows 11 25H2:** causa conflito entre o DWM e o pipeline DXVA/ANGLE da iGPU AMD Vega ao decodificar lives em 1080p/1440p, alternar abas ou entrar em tela cheia.
2. **`EnableUlps = 1` (Ultra Low Power State):** transições agressivas de estado de baixa energia da iGPU causam micro-congelamentos em vídeo acelerado por hardware.
3. **Concorrência de GPU no desktop:** `Wallpaper Engine` e múltiplos processos do Opera GX (`23` processos / `~2,9 GB` RAM) disputando a fila 3D/Video Decode de 512 MB UMA.

## Repositórios de Referência

- [RedDot-3ND7355/MPO-GPU-FIX](https://github.com/RedDot-3ND7355/MPO-GPU-FIX) — Correção de MPO para GPUs AMD/NVIDIA no Windows 11.
- [imribiy/amd-gpu-tweaks](https://github.com/imribiy/amd-gpu-tweaks) — Tweaks de registro AMD (`EnableUlps`, `StutterMode`), omitindo qualquer alteração em proteção térmica.
- [GSDragoon/RadeonSoftwareSlimmer](https://github.com/GSDragoon/RadeonSoftwareSlimmer) — Redução de telemetria e serviços auxiliares AMD.

## Alterações Aplicadas (`scripts/gpu/otimizar_vega8_mpo.ps1`)

| Chave / Serviço | Valor Aplicado | Finalidade |
| :--- | :---: | :--- |
| `HKLM\SOFTWARE\Microsoft\Windows\Dwm\OverlayTestMode` | `5` | Desativa MPO no DWM |
| `HKLM\SYSTEM\...\Control\GraphicsDrivers\DisableOverlays` | `1` | Reforço de desativação de MPO para Windows 11 24H2/25H2 |
| `HKLM\SYSTEM\...\Control\GraphicsDrivers\TdrDelay` / `TdrDdiDelay` | `10` | Evita reset prematuro do driver durante picos de decodificação |
| `...\Class\{4d36e968...}\0000\EnableUlps` | `0` | Desativa Ultra Low Power State na Vega 8 |
| `...\Class\{4d36e968...}\0000\StutterMode` | `0` | Reduz micro-stutter no driver AMD |
| Serviço `AMD Crash Defender Service` | `Disabled` | Reduz telemetria/overhead sem afetar o driver |
| `HKCU\...\DirectX\UserGpuPreferences` (`opera.exe`) | `GpuPreference=2;` | Prioridade de alto desempenho gráfico para o Opera GX |

## Descoberta do Monitoramento de 5 Minutos Pós-Reinício (`benchmarks/monitor-5min-post-reboot.txt`)

Durante o monitoramento contínuo de 60 amostras (pós-reboot, com live aberta no Opera GX e **Adrenalin 25.8.1**):
- **Estabilidade de Driver:** **`0` erros/crashes/TDRs** no período; memória dos processos AMD Radeon caiu de `329,4 MB` para **`70,2 MB` (`-78,7%`)**.
- **Gargalo residual identificado em tempo real:** o motor **`3D` da Vega 8** operou em **`94,47%` de média** (`P95 = 98,4%`, `Máx = 98,8%`) e a **VRAM dedicada** bateu **`485,7 MB` de `512 MB`** (`~95%`), transbordando `835–1053 MB` para RAM compartilhada, enquanto **`VideoDecode = 0%`**.
- **Consumidores identificados:** processo GPU do `opera` (`54,1%` de GPU 3D) + instâncias em segundo plano do `chrome` (`~15,3%` de GPU 3D e `>2,5 GB` RAM) + `dwm` (`7,4%`).

## Correção Automatizada do Opera GX (`scripts/gpu/otimizar_opera_gx.ps1`)

Na inspeção do perfil do Opera GX (`Default\Preferences`), confirmamos que o **RGX / Lucid Mode (`"sharpen_videos": true`)** estava ativo — sendo o responsável direto por saturar o motor 3D da Vega 8 em `94,5%` durante lives em `2560x1440`.

O script `scripts/gpu/otimizar_opera_gx.ps1` faz backup automático de `Local State` e `Default\Preferences`, fecha o navegador com segurança, aplica as alterações abaixo e reabre o Opera GX:
1. **`Local State`:** define `browser.enabled_labs_experiments = ["use-angle@1"]` (**Choose ANGLE graphics backend = D3D11**) e `hardware_acceleration_mode.enabled = true`.
2. **`Default\Preferences`:** altera todas as ocorrências de `"sharpen_videos": true` para **`false`** (desativa o filtro 3D RGX / Lucid Mode).
3. Após a reinicialização do navegador, confirme em `opera://gpu` que **Video Decode** aparece como **`Hardware accelerated`** e mantenha o **Wallpaper Engine** configurado para pausar em apps maximizados/tela cheia.

## Reversão

```powershell
Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -ErrorAction SilentlyContinue
Remove-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "DisableOverlays","TdrDelay","TdrDdiDelay" -ErrorAction SilentlyContinue
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "EnableUlps" -Type DWord -Value 1
Set-Service -Name "AMD Crash Defender Service" -StartupType Manual -ErrorAction SilentlyContinue
```
