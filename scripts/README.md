# Scripts de Otimização — Ordem Segura de Execução

Todos os scripts devem ser executados em um **PowerShell como Administrador** a partir da raiz do repositório.

## Ordem Recomendada

1. **Backup obrigatório:**
   ```powershell
   .\scripts\backup\create_backups.ps1
   ```
2. **Coleta de Baseline (Antes):**
   ```powershell
   .\scripts\audit\collect_baseline.ps1 -OutputPath .\benchmarks\baseline-system.txt -Label BASELINE
   ```
3. **Aplicação dos módulos de tuning:**
   ```powershell
   .\scripts\gpu\otimizar_vega8_mpo.ps1
   .\scripts\gpu\otimizar_opera_gx.ps1
   .\scripts\cpu\otimizar_ryzen5700u.ps1
   .\scripts\ram\otimizar_ram_32gb.ps1
   .\scripts\network\otimizar_wifi_rtl8821ce.ps1
   .\scripts\storage\otimizar_nvme.ps1
   .\scripts\debloat\run_win11_debloat.ps1
   ```
4. **Reiniciar o notebook** (obrigatório para MPO, ULPS, Realtek `bLeisurePs`/`PnPCapabilities` e `MemoryCompression`).
5. **Coleta Pós-Otimização (Depois):**
   ```powershell
   .\scripts\audit\collect_baseline.ps1 -OutputPath .\benchmarks\after-system.txt -Label AFTER
   ```
