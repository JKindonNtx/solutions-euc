# Nutanix Cloud Platform 

## Command Line Interface

PowerShell module to automate the management of the Nutanix Cloud Platform using the version 4 api's. Details of the currently implemented api namespaces are shown below.

In order to use this module you will have to have the following prerequisites in place.

| Module | Prism Central Version | AOS Version |
| :--- | :--- | :--- |
| Nutanix.NcpCli.Core | pc2022.6 or later | 6.5 |
| Nutanix.NcpCli.AIOps | pc2022.6 or later | 6.5 |
| Nutanix.NcpCli.Cluster | pc2023.3 or later | 6.7 |
| Nutanix.NcpCli.LCM | pc2022.6 or later | 6.5 |
| Nutanix.NcpCli.Prism | pc2022.6 or later | 6.5 |
| Nutanix.NcpCli.VMM | pc2022.9 or later | 6.6 |
| Nutanix.NcpCli.Storage | pc2022.6 or later | 6.5 |
| Nutanix.NcpCli.DataProtection | pc2023.3 or later | 6.7 |
| Nutanix.NcpCli.Flow | pc2023.3 or later | 6.7 |

## Installing the Module

### PowerShell Support

Nutanix.NcpCli supports Windows PowerShell 6.1 and above.

### Installing The Module

- Download and extract the Solutions Engineering Repo
- Copy the NCPCli directory to your PowerShell modules directory
- Import the module using the command ```import-module Nutanix.NcpCli```


## Recommended Content

- [Nutanix Developer Portal](https://nutanix.dev)
- [v4 Api Reference](https://developers.nutanix.com/)
