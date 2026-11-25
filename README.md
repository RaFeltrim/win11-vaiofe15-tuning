<div align="center">

# ⚡ Windows 11 Tuning — VAIO FE15 (Ryzen 7 5700U & Vega 8)

### *Otimização de Performance, Latência, Rede, Vídeo (Opera GX) e Debloat · Notebook AMD Lucienne · 2026*

[![Windows 11 Pro](https://img.shields.io/badge/Windows%2011-Pro%2025H2-0078D6?style=for-the-badge&logo=windows)](https://www.microsoft.com/)
[![AMD Ryzen 7 5700U](https://img.shields.io/badge/CPU-Ryzen%207%205700U%208C%2F16T-ED1C24?style=for-the-badge&logo=amd)](https://www.amd.com/)
[![AMD Radeon Vega 8](https://img.shields.io/badge/iGPU-Radeon%20Vega%208%20Lucienne-ED1C24?style=for-the-badge&logo=amd)](https://www.amd.com/)
[![CI Validation](https://img.shields.io/badge/CI-PowerShell%20Lint-2ea44f?style=for-the-badge&logo=githubactions)](./.github/workflows/ci.yml)
[![License MIT](https://img.shields.io/badge/License-MIT-8A2BE2?style=for-the-badge)](./LICENSE)
[![Autor Rafael Feltrim](https://img.shields.io/badge/Autor-Rafael%20Feltrim-0A66C2?style=for-the-badge)](https://github.com/RaFeltrim)

<p align="center">
  <strong>Repositório completo de auditoria, scripts PowerShell 100% reversíveis, benchmarks reais (antes vs. depois + monitoramento contínuo de 5 minutos) e documentação técnica para extração máxima de fluidez, estabilidade de rede e correção de travamentos em lives no Opera GX no notebook VAIO FE15 (Windows 11 Pro Build 26200).</strong>
</p>

[Hardware Alvo](#-hardware-e-ambiente) •
[Estrutura](#-estrutura-do-repositório) •
[Resultados Medidos](#-resultados-reais-antes-vs-depois) •
[Monitoramento 5 Min](#-monitoramento-contínuo-pós-reinício-5-minutos) •
[Repositórios Base](#-repositórios-de-referência) •
[Como Usar](#-como-usar-com-segurança) •
[Reversão](#-reversão)

</div>

---

## 📌 Hardware e Ambiente

| Componente | Especificação Verificada |
| :--- | :--- |
| **Notebook** | Positivo Bahia - VAIO FE15 (`VJFE59F11X-B1011H`, BIOS `V1.21.X`) |
| **Sistema Operacional** | Microsoft Windows 11 Pro (`10.0.26200`, Build `26200` — 25H2) |
| **Processador (CPU)** | AMD Ryzen 7 5700U (`8C/16T`, Lucienne Zen 2, `1.80 GHz` base / até `4.30 GHz` boost, 15W TDP) |
| **Vídeo Integrado (iGPU)** | AMD Radeon Vega 8 (`DEV_164C`, `512 MB` UMA dedicada, Driver `31.0.21923.11000` / Adrenalin `25.8.1`, `2560x1440 @ 60Hz`) |
| **Memória RAM** | `32 GB` (`2× 16 GB` DDR4-3200 Dual Channel, `SMS4WEC8C2J2446SAG`, `31,39 GB` utilizáveis) |
| **Rede Wi-Fi** | `Realtek 8821CE Wireless LAN 802.11ac PCI-E NIC` (Driver `2024.10.142.0`, 5 GHz) |
| **Armazenamento** | SSD `NVMe CL4-8D512` (`512 GB`, NVMe, `C:` NTFS) |

---

## 🗂️ Estrutura do Repositório

```text
win11-vaiofe15-tuning/
│
├── 📁 .github/
│   ├── PULL_REQUEST_TEMPLATE.md            # Checklist padrão para PRs
│   └── 📁 workflows/
│       └── ci.yml                          # Validação de sintaxe PowerShell e integridade de docs
│
├── 📁 docs/                                # Documentação técnica por componente
│   ├── 01-seguranca-e-backups.md           # Ponto de restauração, backups .reg/.pow e regras de segurança
│   ├── 02-gpu-vega8-e-opera-gx.md          # MPO fix (Win11 25H2), ULPS, TdrDelay, análise 5min e guia Opera GX
│   ├── 03-cpu-ryzen7-5700u.md              # MMCSS, Boost Mode seguro, notas RyzenAdj/UXTU e Vanguard
│   ├── 04-ram-32gb-ddr4.md                 # MemoryCompression OFF, SysMain OFF e DisablePagingExecutive
│   ├── 05-rede-wifi-rtl8821ce.md           # PnPCapabilities=24, bLeisurePs=0, 802.11d, Nagle e DNS
│   ├── 06-armazenamento-nvme.md            # ReTrim C:, Fast Startup OFF, timeout AC e limpeza
│   └── 07-windows11-debloat.md             # Debloat seguro (Raphire/Win11Debloat), telemetria e Startup
│
├── 📁 benchmarks/                          # Snapshots padronizados e telemetria contínua
│   ├── README.md                           # Metodologia de medição
│   ├── baseline-system.txt                 # Estado inicial completo (Antes)
│   ├── after-system.txt                    # Estado pós-otimização e pós-reinício (Depois)
│   └── monitor-5min-post-reboot.txt        # Série temporal contínua de 5 min (60 amostras)
│
├── 📁 scripts/                             # Scripts PowerShell modulares e reversíveis
│   ├── README.md                           # Ordem segura de execução
│   ├── 📁 audit/
│   │   ├── collect_baseline.ps1            # Coletor padronizado de telemetria, ping/jitter e CPU bench
│   │   └── monitor_5min.ps1                # Monitor contínuo (iGPU 3D/VideoDec, VRAM, RAM, Wi-Fi, TDR)
│   ├── 📁 backup/
│   │   └── create_backups.ps1              # Ponto de restauração + export .reg e .pow
│   ├── 📁 gpu/
│   │   ├── otimizar_vega8_mpo.ps1          # MPO fix, ULPS=0, StutterMode=0, TdrDelay=10 e Opera GX
│   │   └── otimizar_opera_gx.ps1           # ANGLE D3D11 (use-angle@1), HW Accel e RGX/Lucid Mode OFF
│   ├── 📁 cpu/
│   │   └── otimizar_ryzen5700u.ps1         # MMCSS (Games/Playback) e energia segura Ryzen Mobile
│   ├── 📁 ram/
│   │   └── otimizar_ram_32gb.ps1           # Disable MemoryCompression, SysMain e PagingExecutive
│   ├── 📁 network/
│   │   └── otimizar_wifi_rtl8821ce.ps1     # Realtek RTL8821CE power-save fix, Nagle e DNS Cloudflare
│   ├── 📁 storage/
│   │   └── otimizar_nvme.ps1               # TRIM, ReTrim, Hiberboot=0 e limpeza de temporários
│   └── 📁 debloat/
│       └── run_win11_debloat.ps1           # Remoção segura de bloatware AppX, telemetria e Startup
│
├── .gitattributes                          # Normalização de fim de linha
├── .gitignore                              # Exclusão de backups locais (.reg, .pow, .log)
├── CHANGELOG.md                            # Histórico de versões
├── LICENSE                                 # Licença MIT
└── README.md                               # Visão geral e tabela de resultados
```

---

## 📊 Resultados Reais (Antes vs. Depois)

| Métrica | Antes (`baseline-system.txt`) | Depois (`after-system.txt` pós-reboot) | Variação / Status |
| :--- | :---: | :---: | :---: |
| **RAM Processos AMD Radeon** | `329,4 MB` (`5` proc.) | **`70,2 MB`** (`4` proc.) | **`-78,7%`** |
| **Serviços em Execução** | `121` | **`116`** | **`-5` serviços** |
| **Pacotes AppX Instalados** | `168` | **`153`** | **`-15` bloatwares removidos** |
| **Itens de Startup** | `23` | **`16`** | **`-7` entradas removidas** |
| **Espaço Livre NVMe (`C:`)** | `100,14 GB` | **`102,29 GB`** | **`+2,15 GB`** (`97,87 GB` ReTrim) |
| **MPO (`OverlayTestMode` / `DisableOverlays`)** | Ativo *(vazio)* | **`5` / `1`** | **Desativado (efetivo pós-reboot)** |
| **iGPU `EnableUlps`** | `1` (Ativo) | **`0` (Desativado)** | **Sem micro-stutter ULPS** |
| **Wi-Fi `PnPCapabilities` / `bLeisurePs`** | `16` / `2` | **`24` / `0`** | **Sem sleep agressivo RTL8821CE** |
| **RAM `MemoryCompression` / `SysMain`** | `True` / `Running` | **`False` / `Disabled`** | **Menos overhead de CPU/I/O** |
| **Fast Startup (`HiberbootEnabled`)** | `1` (Ativo) | **`0` (Desativado)** | **Boot limpo de drivers** |
| **DNS Wi-Fi IPv4** | `192.168.3.1` | **`1.1.1.1, 1.0.0.1`** | **Cloudflare DNS** |

---

## 📈 Monitoramento Contínuo Pós-Reinício (5 Minutos)

Coleta de **60 amostras** ([monitor-5min-post-reboot.txt](./benchmarks/monitor-5min-post-reboot.txt)) com o sistema em uso real (live aberta no Opera GX, Adrenalin `25.8.1`, MSI Afterburner `66 °C` pós-boot):

| Métrica (60 amostras) | Mín | Média | P95 | Máx | Observação |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Wi-Fi Ping Roteador (`192.168.3.1`)** | `2 ms` | `4,17 ms` | **`5 ms`** | `38 ms` | **Jitter `1,81 ms` · `0%` perda** |
| **Wi-Fi Ping Internet (`1.1.1.1`)** | `10 ms` | **`18,77 ms`** | `27 ms` | **`43 ms`** | **Jitter `5,68 ms` (`-32,9%` vs. baseline `8,47 ms`) · `0` spikes ≥50 ms · `0%` perda** |
| **Erros / TDR Driver GPU AMD** | — | — | — | **`0`** | **Estabilidade total sem quedas de driver** |
| **iGPU Vega 8 — Motor 3D (%)** | `80,8%` | **`94,47%`** | `98,4%` | `98,8%` | ⚠️ **Gargalo residual descoberto** (`opera` 54% + `chrome` em 2º plano 15% + `dwm` 7%) |
| **iGPU Vega 8 — VideoDecode (%)** | `0%` | `0%` | `0%` | `0%` | ⚠️ Vídeo sendo processado via shader `3D` (conferir `opera://gpu` e desligar **RGX**) |
| **iGPU VRAM Dedicada / Compartilhada** | `376,7 MB` | `434,8 MB` | `466,7 MB` | **`485,7 MB`** | Saturação de `95%` dos `512 MB` UMA (`835–1053 MB` em RAM compartilhada) |
| **RAM Total / Opera GX** | `15,15 GB` | `15,49 GB` | `15,89 GB` | `16,24 GB` | Opera GX estável em `~3,0 GB` (`~16 GB` livres) |

> **Diagnóstico Acionável do Gargalo Residual na iGPU:** a rede Wi-Fi e a estabilidade do driver AMD foram 100% normalizadas (`0` perdas, `0` spikes ≥50ms, `0` TDRs). O único ponto ainda pressionando a Vega 8 em `94,5%` durante lives é o uso do motor **3D** em vez de **VideoDecode** + concorrência de instâncias do **Chrome** em segundo plano. Siga o checklist em [02-gpu-vega8-e-opera-gx.md](./docs/02-gpu-vega8-e-opera-gx.md) (desligar **RGX/Lucid Mode**, forçar `ANGLE = D3D11` em `opera://flags` e fechar abas pesadas do Chrome durante lives).

---

## 🔗 Repositórios de Referência

- [RedDot-3ND7355/MPO-GPU-FIX](https://github.com/RedDot-3ND7355/MPO-GPU-FIX) — Correção de MPO para travamentos de vídeo/Chromium em GPUs AMD no Windows 11.
- [imribiy/amd-gpu-tweaks](https://github.com/imribiy/amd-gpu-tweaks) & [GSDragoon/RadeonSoftwareSlimmer](https://github.com/GSDragoon/RadeonSoftwareSlimmer) — Tweaks de registro AMD (`EnableUlps`, `StutterMode`) e redução de telemetria preservando proteção térmica.
- [FlyGoat/RyzenAdj](https://github.com/FlyGoat/RyzenAdj) & [JamesCJ60/Universal-x86-Tuning-Utility](https://github.com/JamesCJ60/Universal-x86-Tuning-Utility) — Referência técnica para gestão de TDP/Tctl em APUs Ryzen 5000U *(documentado como opcional por incompatibilidade do `WinRing0` com Riot Vanguard)*.
- [amitxv/PC-Tuning](https://github.com/amitxv/PC-Tuning) & [NicholasBly/Windows-11-Latency-Optimization](https://github.com/NicholasBly/Windows-11-Latency-Optimization) — MMCSS, gerenciamento de memória para 32 GB RAM e redução de latência.
- [Raphire/Win11Debloat](https://github.com/Raphire/Win11Debloat) & [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil) — Debloat seguro compatível com Windows 11 25H2 preservando Microsoft Store, Xbox/Game Bar e OneDrive.

---

## 🚀 Como Usar com Segurança

1. Leia [01-seguranca-e-backups.md](./docs/01-seguranca-e-backups.md) e execute `.\scripts\backup\create_backups.ps1` como Administrador.
2. Siga a ordem em [scripts/README.md](./scripts/README.md).
3. **Reinicie o notebook** ao final (nunca faça *hot-restart* de driver de vídeo) e execute `.\scripts\audit\collect_baseline.ps1` e `.\scripts\audit\monitor_5min.ps1` para validar os ganhos.

---

## 🔄 Reversão

Todos os documentos em `docs/` trazem os comandos individuais de reversão, além dos backups `.reg`, `.pow` e do Ponto de Restauração criados automaticamente em `backups/`.

---

## 👤 Autor

**Rafael Feltrim** — [@RaFeltrim](https://github.com/RaFeltrim)
