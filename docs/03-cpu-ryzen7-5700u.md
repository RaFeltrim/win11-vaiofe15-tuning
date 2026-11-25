# 03 — CPU AMD Ryzen 7 5700U (Lucienne · 8C/16T)

## Perfil do Processador

- **Modelo:** AMD Ryzen 7 5700U (`Lucienne`, Zen 2, `7nm`, 8 núcleos / 16 threads, `1.8 GHz` base / até `4.3 GHz` boost, TDP nominal `15W`).
- **Desafio em Notebook Fino (VAIO FE15):** deixar o boost agressivo sem critério causa picos rápidos para `90–95 °C`, disparando *throttling* térmico/STAPM que derruba o clock bruscamente e gera travamentos em vídeo e multitarefa.

## Repositórios de Referência

- [amitxv/PC-Tuning](https://github.com/amitxv/PC-Tuning) — Ajustes de MMCSS, responsividade de áudio/vídeo e energia do Windows.
- [FlyGoat/RyzenAdj](https://github.com/FlyGoat/RyzenAdj) — Biblioteca CLI de controle de limites STAPM/PPT/Tctl para APUs Ryzen Mobile.
- [JamesCJ60/Universal-x86-Tuning-Utility](https://github.com/JamesCJ60/Universal-x86-Tuning-Utility) — GUI moderna (UXTU) sobre `RyzenAdj`.

## Alterações Aplicadas (`scripts/cpu/otimizar_ryzen5700u.ps1`)

1. **MMCSS (`Multimedia\SystemProfile`):**
   - `NetworkThrottlingIndex = 0xFFFFFFFF` (remove estrangulamento de pacotes de rede durante reprodução multimídia).
   - `SystemResponsiveness = 10` (equilíbrio ideal para streaming/lives + multitarefa sem sufocar áudio/DWM).
   - `Tasks\Games` e `Tasks\Playback`: `GPU Priority = 8`, `Priority = 6`, `Scheduling Category = High`, `SFIO Priority = High`.
2. **Gestão de Energia Segura para Notebook:**
   - Desbloqueia a opção oculta **Modo de aumento de desempenho do processador** (`be337238-0d82-4146-a960-4f3749d470c7`).
   - Define `Efficient Aggressive (4)` na tomada (AC) e `Efficient Enabled (3)` na bateria (DC) — evita picos térmicos desnecessários mantendo boost completo sob carga real.
   - Desativa `PCIe Link State Power Management`, `USB Selective Suspend` e economia de energia do Wi-Fi quando conectado à tomada (AC).

## Notas Opcionais (Não Aplicadas Automaticamente por Segurança)

> [!WARNING]
> **Riot Vanguard vs. `RyzenAdj`/`UXTU` e `VBS/HVCI`:**
> - Ferramentas baseadas em `WinRing0` (`RyzenAdj` / `UXTU`) podem ser bloqueadas pelo **Riot Vanguard** (`vgtray.exe`). Caso não utilize jogos com Vanguard, um perfil seguro testado pela comunidade para o 5700U na tomada é:
>   ```cmd
>   ryzenadj.exe --stapm-limit=25000 --fast-limit=30000 --slow-limit=25000 --tctl-temp=80
>   ```
> - O **VBS/HVCI (Integridade de Memória)** foi mantido **inalterado** para preservar 100% de compatibilidade com segurança e anti-cheats no Windows 11.

## Reversão

```powershell
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Type DWord -Value 10
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Type DWord -Value 20
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR be337238-0d82-4146-a960-4f3749d470c7 2
powercfg /setactive SCHEME_CURRENT
```
