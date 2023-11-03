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
New-Variable -Name ApiRoot -Value "api" -Option ReadOnly

# API Versions
New-Variable -Name AIOpsApiVersion -Value "v4.0.a2" -Option ReadOnly
New-Variable -Name ClusterApiVersion -Value "v4.0.b1" -Option ReadOnly
New-Variable -Name DataProtectionApiVersion -Value "v4.0.a4" -Option ReadOnly
New-Variable -Name FlowApiVersion -Value "v4.0.a1" -Option ReadOnly

# API NameSpace
New-Variable -Name AiOpsNameSpace -Value "aiops" -Option ReadOnly
New-Variable -Name ClusterNameSpace -Value "clustermgmt" -Option ReadOnly
New-Variable -Name DataProtectionNameSpace -Value "dataprotection" -Option ReadOnly
New-Variable -Name FlowNameSpace -Value "microseg" -Option ReadOnly

# API Module
New-Variable -Name ModuleConfig -Value "config" -Option ReadOnly
New-Variable -Name ModuleStats -Value "stats" -Option ReadOnly

# API Resource - AIOps
New-Variable -Name AIOpsResourceSources -Value "sources" -Option ReadOnly
New-Variable -Name AIOpsResourceEntityTypes -Value "entity-types" -Option ReadOnly
New-Variable -Name AIOpsResourceEntities -Value "entities" -Option ReadOnly
New-Variable -Name AIOpsResourceMetadata -Value "entity-descriptors" -Option ReadOnly

# API Resource - Cluster
New-Variable -Name ClusterResourceClusters -Value "clusters" -Option ReadOnly
New-Variable -Name ClusterResourceFaultToleranceStatus -Value "fault-tolerance-status" -Option ReadOnly
New-Variable -Name ClusterResourceRackableUnits -Value "rackable-units" -Option ReadOnly
New-Variable -Name ClusterResourceSNMP -Value "snmp" -Option ReadOnly
New-Variable -Name ClusterResourceSYSLOG -Value "rsyslog-servers" -Option ReadOnly
New-Variable -Name ClusterResourceHosts -Value "hosts" -Option ReadOnly
New-Variable -Name ClusterResourceHostNIC -Value "host-nics" -Option ReadOnly
New-Variable -Name ClusterResourceHostVirtualNIC -Value "virtual-nics" -Option ReadOnly

# API Resource - Data Protection
New-Variable -Name DataProtectionResourceConsistencyGroups -Value "consistency-groups" -Option ReadOnly

# API Resource - Flow
New-Variable -Name FlowResourceAddressGroups -Value "address-groups" -Option ReadOnly
New-Variable -Name FlowResourceNetworkSecurityPolicies -Value "policies" -Option ReadOnly
New-Variable -Name FlowResourceServiceGroups -Value "service-groups" -Option ReadOnly


