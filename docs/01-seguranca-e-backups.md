# 01 — Segurança, Backups e Reversão

Antes de aplicar qualquer otimização no **VAIO FE15 (`VJFE59F11X-B1011H`)**, todas as chaves de registro, o plano de energia ativo e o estado do sistema são salvos localmente.

## Como o Backup Automático Funciona

Execute em um PowerShell como **Administrador**:

```powershell
.\scripts\backup\create_backups.ps1
```

O script cria:
1. Um **Ponto de Restauração do Windows** (`Pre-Win11-VAIOFE15-Tuning-<timestamp>`).
2. Exportações `.reg` em `backups/<timestamp>/` (pasta ignorada pelo `.gitignore` para não expor dados locais no Git):
   - `gpu_class_0000.reg` (driver AMD Radeon Vega 8)
   - `dwm.reg` e `graphics_drivers.reg` (MPO e TDR)
   - `wifi_class_0001.reg` e `tcpip_interfaces.reg` (Realtek RTL8821CE e Nagle)
   - `multimedia_system.reg` (MMCSS)
   - `session_manager_power.reg` (Fast Startup)
   - `hkcu_run.reg` e `hklm_run.reg` (Startup)
3. Exportação do plano de energia ativo (`powerplan-*.pow`).

## Regras de Segurança Adotadas

- **Proteções térmicas intactas:** Nunca desativamos `PP_ThermalAutoThrottlingEnable` nem alteramos sensores térmicos da APU Ryzen 7 5700U.
- **Sem *hot-restart* de driver de vídeo:** Após alterar chaves de GPU (`EnableUlps`, `OverlayTestMode`, `DisableOverlays`), **reinicie o Windows normalmente** em vez de reiniciar o driver via `pnputil`.
- **Compatibilidade com Riot Vanguard:** `VBS/HVCI`, `TPM 2.0` e `Secure Boot` são mantidos intactos, e drivers `WinRing0` (`RyzenAdj`/`UXTU`) não são carregados automaticamente para evitar conflitos com anti-cheat.

## Reversão Completa

- **Via Registro:** dê duplo clique ou execute `reg import backups\<timestamp>\<arquivo>.reg` como Administrador e reinicie.
- **Via Plano de Energia:** `powercfg /import backups\<timestamp>\powerplan-*.pow`.
- **Via Restauração do Sistema:** execute `rstrui.exe` e selecione o ponto `Pre-Win11-VAIOFE15-Tuning-*`.
