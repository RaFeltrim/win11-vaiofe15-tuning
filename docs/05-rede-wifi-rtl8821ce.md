# 05 — Rede Wi-Fi (Realtek RTL8821CE 802.11ac PCIe)

## Diagnóstico Inicial

- **Adaptador:** `Realtek 8821CE Wireless LAN 802.11ac PCI-E NIC` (driver `2024.10.142.0`, 5 GHz Ch 149, `390 Mbps`, `-57 dBm`).
- **Problemas encontrados no registro:**
  - `PnPCapabilities = 16` (permitia economia de energia do Windows na placa Wi-Fi).
  - `bLeisurePs = 2` (**Leisure Power Save ativo** — famoso no chip RTL8821CE por causar picos de latência e engasgos periódicos em lives/jogos).
  - `802.11d` e `Multi-Channel Concurrent` ativos (aumentam varreduras de canal em segundo plano).
  - DNS apontando para o roteador local (`192.168.3.1`).

## Alterações Aplicadas (`scripts/network/otimizar_wifi_rtl8821ce.ps1`)

| Parâmetro | Antes | Depois | Efeito |
| :--- | :---: | :---: | :--- |
| `PnPCapabilities` | `16` | **`24`** | Impede o Windows de desligar/suspender o Wi-Fi |
| `bLeisurePs` / `LpsEn` / `PowerSaveMode` | `2` / *(vazio)* | **`0`** | Desativa economia agressiva do firmware RTL8821CE |
| `802.11d` & `Multi-Channel Concurrent` | Habilitado | **Desabilitado (`0`)** | Reduz scans periódicos e jitter |
| `TcpAckFrequency` / `TCPNoDelay` | *(padrão)* | **`1` / `1`** | Desativa algoritmo de Nagle (menor latência interativa) |
| DNS IPv4 / IPv6 (`Wi-Fi`) | `192.168.3.1` | **Cloudflare `1.1.1.1` / `1.0.0.1`** | Resolução DNS mais rápida e estável |

## Reversão

```powershell
$wifiKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001"
Set-ItemProperty $wifiKey -Name "PnPCapabilities" -Type DWord -Value 16
Set-ItemProperty $wifiKey -Name "bLeisurePs" -Type String -Value "2"
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ResetServerAddresses
```
