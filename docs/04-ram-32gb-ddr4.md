# 04 — Memória RAM (32 GB DDR4-3200 Dual Channel)

## Diagnóstico Inicial

- **Configuração:** `2× 16 GB` DDR4-3200 Dual Channel (`SMS4WEC8C2J2446SAG`), total utilizável `31,38 GB` (`512 MB` reservados para UMA da Vega 8).
- **Gargalo encontrado:** `MemoryCompression = True` e serviço `SysMain` (Superfetch) ativos. Com **32 GB de RAM e SSD NVMe**, comprimir páginas de memória na RAM queima ciclos de CPU sem necessidade e adiciona micro-latências.

## Repositórios de Referência

- [amitxv/PC-Tuning](https://github.com/amitxv/PC-Tuning) — Diretrizes de gerenciamento de memória para sistemas com ≥16 GB RAM.
- [NicholasBly/Windows-11-Latency-Optimization](https://github.com/NicholasBly/Windows-11-Latency-Optimization) — Redução de overhead de paginação e serviços de pré-busca.
- [henrypp/memreduct](https://github.com/henrypp/memreduct) — Referência opcional caso deseje limpeza manual de Standby List em sessões muito longas.

## Alterações Aplicadas (`scripts/ram/otimizar_ram_32gb.ps1`)

| Ajuste | Valor | Motivo |
| :--- | :---: | :--- |
| `Disable-MMAgent -MemoryCompression` | `False` | Elimina overhead de compressão de RAM na CPU (seguro com 32 GB) |
| Serviço `SysMain` | `Disabled` | Redundante em SSD NVMe + 32 GB RAM; evita picos de I/O em segundo plano |
| `DisablePagingExecutive` | `1` | Mantém drivers e código do kernel na RAM física em vez de paginar para disco |
| `LargeSystemCache` | `0` | Padrão ideal para desktop/workstation (prioriza apps do usuário) |

## Reversão

```powershell
Enable-MMAgent -MemoryCompression
Set-Service -Name "SysMain" -StartupType Automatic
Start-Service -Name "SysMain"
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Type DWord -Value 0
```
