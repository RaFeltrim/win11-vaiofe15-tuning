# Benchmarks & Metodologia de Medição

Este diretório armazena os snapshots padronizados gerados por `scripts/audit/collect_baseline.ps1` **antes** (`baseline-system.txt`) e **depois** (`after-system.txt`), além da série temporal contínua de 5 minutos gerada por `scripts/audit/monitor_5min.ps1` (`monitor-5min-post-reboot.txt`).

## Arquivos

- `baseline-system.txt`: coleta inicial antes de qualquer alteração de registro, serviço ou debloat.
- `after-system.txt`: coleta pós-otimização e pós-reinício para comparação direta Antes vs. Depois.
- `monitor-5min-post-reboot.txt`: monitoramento contínuo (60 amostras) pós-reinício medindo estabilidade real sob uso de live no Opera GX.

## Métricas Coletadas

- **Sistema & Bloat:** total de processos, serviços em execução, pacotes AppX, itens de Startup, uso de RAM total, RAM do Opera GX, processos AMD Radeon e Windows Defender.
- **Telemetria iGPU Vega 8 (5 min):** utilização dos motores `3D` e `VideoDecode`, VRAM dedicada (`512 MB` UMA) e compartilhada, mais contagem de erros/TDR do driver AMD no Event Viewer.
- **Rede Wi-Fi (Latência, Jitter & Spikes):** testes ICMP consecutivos para o gateway local (`192.168.3.1`) e Cloudflare (`1.1.1.1`) medindo mínimo, média, P95, máximo, *jitter* médio, spikes e perda de pacotes.
- **Verificação de Registro:** estado real de `EnableUlps`, `OverlayTestMode`, `DisableOverlays`, `TdrDelay`, `PnPCapabilities`, `bLeisurePs`, `MemoryCompression`, `SysMain`, `DiagTrack`, `HiberbootEnabled` e DNS ativo.
