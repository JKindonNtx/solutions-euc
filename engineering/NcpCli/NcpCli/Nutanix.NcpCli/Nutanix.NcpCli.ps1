# Launch Text
write-host @"
  _   _       _              _         _____ _ _ 
 | \ | |     | |            (_)       / ____| (_)
 |  \| |_   _| |_ __ _ _ __  ___  __ | |    | |_ 
 | . ` | | | | __/ _` | '_ \| \ \/ / | |    | | |
 | |\  | |_| | || (_| | | | | |>  <  | |____| | |
 |_| \_|\__,_|\__\__,_|_| |_|_/_/\_\  \_____|_|_|

Welcome to the Nutanix Cloud Platform Cli
For any issues please see: https://github.com/dbretty/NcpCli/issues

Api NameSpaces available:

:------------------------------------------------------------------:
| Nutanix.NcpCli.AIOps            | AI Operations                  |
| Nutanix.NcpCli.Cluster          | Cluster Management             |
| Nutanix.NcpCli.LCM              | Life Cycle Management          |
| Nutanix.NcpCli.Prism            | Prism Central                  |
| Nutanix.NcpCli.VMM              | Virtual Machine Management     |
| Nutanix.NcpCli.Storage          | Storage Management             |
| Nutanix.NcpCli.DataProtection   | Data Protection                |
| Nutanix.NcpCli.Flow             | Flow Microsegmentation         |
:------------------------------------------------------------------:

"@        


# Build API Constants

# API Root
New-Variable -Name ClusterApiRoot -Value "api" -Option ReadOnly

# API Versions
New-Variable -Name ClusterApiVersion -Value "v4.0.b1" -Option ReadOnly

# API NameSpace
New-Variable -Name ClusterNameSpace -Value "clustermgmt" -Option ReadOnly

# API Module
New-Variable -Name ClusterModuleConfig -Value "config" -Option ReadOnly
New-Variable -Name ClusterModuleStats -Value "stats" -Option ReadOnly

# API Resource - NameSpace Cluster
New-Variable -Name ClusterResourceClusters -Value "clusters" -Option ReadOnly
New-Variable -Name ClusterResourceFaultToleranceStatus -Value "fault-tolerance-status" -Option ReadOnly
New-Variable -Name ClusterResourceRackableUnits -Value "rackable-units" -Option ReadOnly
New-Variable -Name ClusterResourceSNMP -Value "snmp" -Option ReadOnly
New-Variable -Name ClusterResourceSYSLOG -Value "rsyslog-servers" -Option ReadOnly
New-Variable -Name ClusterResourceHosts -Value "hosts" -Option ReadOnly
New-Variable -Name ClusterResourceHostNIC -Value "host-nics" -Option ReadOnly
New-Variable -Name ClusterResourceHostVirtualNIC -Value "virtual-nics" -Option ReadOnly
