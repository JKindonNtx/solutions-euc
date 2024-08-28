# Appendix

## Custom Machine Categories with Nutanix Playbooks

We used a custom playbook to automatically tag the MCS deployed VMs with the correct VDA category. Link at the bottom of this section.

## Network

- Arista 7050Q: L3 spine
- Arista 7050S: L2 leaf

## Citrix Policy Customization

We applied the Citrix policies in the following table.

_Table: Custom Citrix Policies_

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

We used the Login Enterprise EUX settings in the following table.

_Table: EUX Actions Settings_

| Action | App | Argument | Label |
| --- | --- | --- | --- | 
| diskmydocs | diskspeed | `folder=\"{myDocs}\" blockSize=4k bufferSize=4K writeMask=0x5555 cachePct=97 latencyPct=99 threads=1 duration=250` | MyDocuments |
| cpuspeed | cpuspeed | `d=250 t=4` | CPU |
| highcompression | compressionspeed | `folder=\"{appData}\" cachePct=95 writePct=100 duration=250 threads=1 -high` | Compression |
| fastcompression | compressionspeed | `folder=\"{appData}\" cachePct=95 writePct=100 duration=250 threads=1` | CachedHigh&ZeroWidthSpace;Compression |
| appspeed | appspeed | `folder=\"{appData}\" duration=10000 launchtimestamp=`&ZeroWidthSpace;`{launchTimestamp}` | App |

_Table: EUX Tuning Settings_

| Parameter | Value |
| --- | :---: |
| PerformancePenalty | 3.0 |
| BucketSizeInMinutes  | 5 |
| NumSamplesForBaseline | 5 |
| CapacityRollingAverageSize | 3 |
| MaxBaselineForCapacity | 4,000 |
| CapacityTrigger | < 80% |
| SteadyStateCooldownWindow | 5 |
| BaselineScoreWindowSize | 5 |

_Table: EUX Measurement Tuning Settings_

| Action | Weight | NominalValue | CapacityTrigger |
| --- | :---: | :---: | :---: | 
| DiskMyDocs | 0 | 8,500 | < 25% | 
| DiskMyDocsLatency | 0 | 1,200 | < 5% | 
| CpuSpeed | 0 | 50,000 | < 55% | 
| HighCompression | 1 | 2,000 | < 5% | 
| FastCompression | 1 | 2,000 | < 5% | 
| AppSpeed | 6 | 2,700 | < 80% | 
| AppSpeedUserInput | 1 | 500 | < 35% | 

## References

1.  [End-User Computing Performance Benchmarking](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2161-EUC-Performance-Benchmarking:BP-2161-EUC-Performance-Benchmarking)
2.  [Login Enterprise](https://www.loginvsi.com/)
3.  [Login Enterprise EUX Score](https://support.loginvsi.com/hc/en-us/articles/4408717958162-Login-Enterprise-EUX-Score-#h_01GS8W30049HVB851TX60TDKS3)
4.  [Login Enterprise Workload Templates](https://support.loginvsi.com/hc/en-us/sections/360001765419-Workload-Templates)
5.  [Citrix DaaS Documentation](https://docs.citrix.com/en-us/citrix-daas/overview)
6.  [Microsoft SQL Server on Nutanix](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2015-Microsoft-SQL-Server:BP-2015-Microsoft-SQL-Server)
7.  [Auto Categorize New VMs](https://www.nutanix.dev/playbooks/auto-categorize-new-vms/)
