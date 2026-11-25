# Changelog

Todas as alterações relevantes do projeto `win11-vaiofe15-tuning` são registradas aqui.

## [1.0.0] - 2026-11-25

### Adicionado
- Auditoria completa e scripts reversíveis de otimização para **VAIO FE15 (`VJFE59F11X-B1011H`)** com **Windows 11 Pro 25H2 (Build 26200)**, **AMD Ryzen 7 5700U (Lucienne)**, **AMD Radeon Vega 8**, **32 GB DDR4-3200**, **Realtek RTL8821CE** e **NVMe CL4-8D512**.
- `scripts/backup/create_backups.ps1`: criação automática de Ponto de Restauração + exportação `.reg` e `.pow`.
- `scripts/audit/collect_baseline.ps1`: coletor padronizado de métricas (antes vs. depois).
- `scripts/audit/monitor_5min.ps1`: monitor contínuo de 5 minutos (iGPU 3D/VideoDecode, VRAM dedicada/compartilhada, RAM, Opera GX, Wi-Fi ping/jitter/spikes e eventos TDR).
- `benchmarks/monitor-5min-post-reboot.txt`: relatório real pós-reinício (60 amostras) com diagnóstico do gargalo residual de GPU 3D (`94,5%` / `485,7 MB` UMA).
- `scripts/gpu/otimizar_vega8_mpo.ps1`: correção de MPO (`OverlayTestMode=5` + `DisableOverlays=1`), `EnableUlps=0`, `StutterMode=0`, `TdrDelay=10` e `GpuPreference=2` para eliminar travamentos em lives no Opera GX.
- `scripts/gpu/otimizar_opera_gx.ps1`: configura ANGLE `D3D11` (`use-angle@1`), garante aceleração de hardware ativa e desativa RGX/Lucid Mode (`sharpen_videos=false`) com backup automático.
- `scripts/cpu/otimizar_ryzen5700u.ps1`: MMCSS (`Games` e `Playback`), desbloqueio de `Processor Performance Boost Mode` (`Efficient Aggressive` AC / `Efficient Enabled` DC) mantendo `VBS/HVCI` intacto para Riot Vanguard.
- `scripts/ram/otimizar_ram_32gb.ps1`: desativação de `MemoryCompression`, `SysMain` e `DisablePagingExecutive=1`.
- `scripts/network/otimizar_wifi_rtl8821ce.ps1`: `PnPCapabilities=24`, `bLeisurePs=0`, `LpsEn=0`, desativação de `802.11d`, `Multi-Channel Concurrent`, algoritmo de Nagle e DNS Cloudflare.
- `scripts/storage/otimizar_nvme.ps1`: `ReTrim` em `C:` (`97,87 GB` otimizados), `HiberbootEnabled=0` e limpeza segura de temporários (`1.147,84 MB` liberados).
- `scripts/debloat/run_win11_debloat.ps1`: remoção segura de 15 pacotes AppX de bloatware, desativação de `DiagTrack`/anúncios/Bing/Copilot e limpeza de Startup preservando Store, Xbox, OneDrive e Vanguard.
- Documentação completa em `docs/01..07`, `benchmarks/baseline-system.txt`, `benchmarks/after-system.txt` e workflow de CI (`.github/workflows/ci.yml`).
