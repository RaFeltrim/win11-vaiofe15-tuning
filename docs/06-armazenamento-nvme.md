# 06 — Armazenamento NVMe (`CL4-8D512` 512 GB)

## Diagnóstico Inicial

- **Disco:** `NVMe CL4-8D512` (`512 GB`, NVMe, Saúde `Healthy`, `C:` NTFS com ~`100,4 GB` livres de `475,9 GB`).
- **Estado:** TRIM (`DisableDeleteNotify = 0`) já ativo, porém **`HiberbootEnabled = 1` (Fast Startup)** estava ligado — no Windows 11, o Fast Startup hiberna o kernel e mantém estados antigos de drivers (especialmente AMD Radeon e Realtek Wi-Fi) entre reinicializações.

## Alterações Aplicadas (`scripts/storage/otimizar_nvme.ps1`)

1. Confirmação de `DisableDeleteNotify = 0` e execução de `Optimize-Volume -DriveLetter C -ReTrim`.
2. Desativação do Fast Startup (`HiberbootEnabled = 0`) para garantir inicialização limpa dos drivers de vídeo e rede.
3. Timeout de desligamento de disco na tomada (`DISKIDLE AC`) definido para `0` (nunca desligar).
4. Limpeza segura de arquivos temporários em `%TEMP%` e `C:\Windows\Temp`.

> [!NOTE]
> **Driver nativo `nvmedisk.sys` (Windows 11 25H2):** scripts experimentais como `1LUC1D4710N/nvme-performance-script` habilitam o driver nativo `nvmedisk.sys` em vez de `StorNVMe.sys`. Por segurança em laptops OEM (risco de incompatibilidade/BSOD dependendo do firmware do SSD `CL4-8D512`), **não aplicamos** essa chave experimental automaticamente.

## Reversão

```powershell
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Type DWord -Value 1
```
