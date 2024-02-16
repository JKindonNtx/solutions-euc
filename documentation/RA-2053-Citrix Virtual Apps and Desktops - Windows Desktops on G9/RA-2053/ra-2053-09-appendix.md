# Appendix

## Hardware Configuration

Storage and compute:

- Nutanix NX-3155-G9
- Per-node specs:
  - CPU: 2 x Xeon Gold 6442Y @ 2.6 Ghz
  - Memory: 1.5 TB
  - Disk: 4 x 1.92 TB NVMe

Network:

- Arista 7050Q: L3 spine
- Arista 7050S: L2 leaf

## Software Configuration

Nutanix

- AOS 6.5.4.5
- CVM: 12 vCPU, 32 GB of memory

Citrix Virtual Apps and Desktops

- 7.2203 CU4

## Citrix Policy Customization

The Citrix Policies we applied:

| Parameter | Value |
| --- | --- |
| Audio quality | Medium |
| Auto connect client drives | Disabled |
| Auto-create client printers | Do not auto-create client printers |
| Automatic installation of in-box printer drivers | Disabled |
| Client fixed drives | Prohibited |
| Client network drives | Prohibited |
| Client optical drives | Prohibited |
| Client removable drives | Prohibited |
| Desktop wallpaper | Prohibited |
| HDX Adaptive Transport | Off |
| Menu animation | Prohibited |
| Multimedia conferencing | Prohibited |
| Optimization for Windows Media multimedia redirection over WAN | Prohibited |
| Use video codec for compression | Do not use video codec |
| View window contents while dragging | Prohibited |
| Windows Media fallback prevention | Play all content |

## EUX Setting Customization

The Login Enterprise EUX settings we used:

Actions:

| Action | App | Argument | Label |
| --- | --- | --- | --- | 
| diskmydocs | diskspeed | folder=\"{myDocs}\" blockSize=4k bufferSize=4K writeMask=0x5555 cachePct=97 latencyPct=99 threads=1 duration=250 | MyDocuments |
| cpuspeed | cpuspeed | d=250 t=4 | CPU |
| highcompression | compressionspeed | folder=\"{appData}\" cachePct=95 writePct=100 duration=250 threads=1 -high | Compression |
| fastcompression | compressionspeed | folder=\"{appData}\" cachePct=95 writePct=100 duration=250 threads=1 | CachedHighCompression |
| appspeed | appspeed | folder=\"{appData}\" duration=10000 launchtimestamp={launchTimestamp} | App |


Tuning:

| Parameter | Value |
| --- | --- |
  PerformancePenalty | 3.0 |
| BucketSizeInMinutes  | 5 |
| NumSamplesForBaseline | 5 |
| CapacityRollingAverageSize | 3 |
| MaxBaselineForCapacity | 4000 |
| CapacityTrigger | <80% |
| SteadyStateCooldownWindow | 5 |
| BaselineScoreWindowSize | 5 |

| Action | Weight | NominalValue | CapacityTrigger |
| --- | --- | --- | --- | 
| DiskMyDocs | 0 | 8500 | <25% | 
| DiskMyDocsLatency | 0 | 1200 | <5% | 
| CpuSpeed | 0 | 50000 | <55% | 
| HighCompression | 1 | 2000 | <5% | 
| FastCompression | 1 | 2000 | <5% | 
| AppSpeed | 6 | 2700 | <80% | 
| AppSpeedUserInput | 1 | 500 | <35% | 

## References

1.  [End-User Computing Performance Benchmarking](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2161-EUC-Performance-Benchmarking:BP-2161-EUC-Performance-Benchmarking)
2.  [Login Enterprise](https://www.loginvsi.com/)
3.  [Login Enterprise EUX Score](https://support.loginvsi.com/hc/en-us/articles/4408717958162-Login-Enterprise-EUX-Score-#h_01GS8W30049HVB851TX60TDKS3)
4.  [Login Enterprise Workload Templates](https://support.loginvsi.com/hc/en-us/sections/360001765419-Workload-Templates)
5.  [Citrix Virtual Apps and Desktops 2203 Long Term Service Release (LTSR) Documentation](https://docs.citrix.com/en-us/citrix-virtual-apps-desktops/2203-ltsr/)

