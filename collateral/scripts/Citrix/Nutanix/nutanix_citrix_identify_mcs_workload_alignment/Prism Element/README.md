# Identify Citrix Provisioned Machines which are co-located with general workload VMs in Nutanix AHV

## Objective

To identify shared workload scenarios where both Citrix provisioned workloads, and general workloads are co-located. Data is output into a tree format.

The script attempts to identify MCS workloads based on a known Identity Disk size of 16 mib.

It also attempts to best guess where Citrix PVS machines may be in play, it does this by:

-  Identifying if the machine is booting from a CD ROM. It can only only do this by checking to see if:
   -  The device boot type is legacy or UEFI. 
      -  If it's UEFI we have no idea what the guest BIOS configuration is. So we simply look for a non empty CD-ROM and make a call that this ***might*** be a PVS machine using boot ISO.
      -  If it's Legacy, we can query the boot order to understand if it's set to CD-ROM. We simply look for a non empty CD-ROM and make a call that this ***might*** be a PVS machine using boot ISO.
- Identifying if the machine is set for Network boot (PXE). Same rules apply as above:
  - If Legacy BIOS, we check for Network boot order and make and make a call that this ***might*** be a PVS machine which boots via PXE.
  - If UEFI, we have no idea, so we can't make an educated call and the machine is not flagged.

PVS detection is very rough.

## Technical requirements for running the script

The script is compatible with Windows PowerShell 5.1 onwards.

This means that the technical requirements for the workstation or server running the script are as follows:

- Any Windows version which can run Windows PowerShell 5.1.
- Access to Nutanix Prism Element with an appropriate credential to query clusters, hosts and virtual machines.

## Parameter Details

The following parameters exist to drive the behaviour of the script:

#### Mandatory and recommended parameters:

- `pe_source`: Mandatory **`String`**. The Prism Element Instance to connect to.

#### Optional Parameters

- `LogPath`: Optional **`String`**. Log path output for all operations. The default is `C:\Logs\PrismElementVDIAlignment.log`
- `LogRollover`: Optional **`Int`**. Number of days before log files are rolled over. Default is 5.
- `UseCustomCredentialFile`: Optional. **`switch`**. Will call the `Get-CustomCredentials` function which keeps outputs and inputs a secure credential file base on Stephane Bourdeaud from Nutanix functions.
- `CredPath`: Optional **`String`**. Used if using the `UseCustomCredentialFile` parameter. Defines the location of the credential file. The default is `"$Env:USERPROFILE\Documents\WindowsPowerShell\CustomCredentials"`.
- `AdvancedInfo`:  Optional **`Switch`**. Will verbose output detection and criteria matchingdetail.
- `ShowDetailedVMAlignment`: Optional **`Array`**. Defines which VM types will be shows in the Host tree output (General, MCS, PVS, All, None). Default is All.

## Examples

```
.\PrismElementVDIAlignment.ps1 -pe_source 1.1.1.1 -UseCustomCredentialFile
```

The script will:

-  Will Query Prism Element at 1.1.1.1 using a custom credential file (if it doesn't exist, it will be prompted for and saved for next time). 
-  Logs all output to C:\Logs\PrismElementVDIAlignment.log
-  Will output all VM details under the VM to host alignment.

```
.\PrismElementVDIAlignment.ps1 -pe_source 1.1.1.1
```

The script will:

-  Will Query Prism Element at 1.1.1.1. 
-  Credentials will be prompted for. 
-  Logs all output to C:\Logs\PrismElementVDIAlignment.log
-  Will output all VM details under the VM to host alignment.

```
.\PrismElementVDIAlignment.ps1 -pe_source 1.1.1.1 -ShowDetailedVMAlignment None
```

The script will:

-  Will Query Prism Element at 1.1.1.1.
-  Credentials will be prompted for. 
-  Logs all output to C:\Logs\PrismElementVDIAlignment.log
-  Will output only a summary view under the vm to host alignment.

```
.\PrismElementVDIAlignment.ps1 -pe_source 1.1.1.1 -ShowDetailedVMAlignment MCS,PVS
```

The script will:

-  Will Query Prism Element at 1.1.1.1.
-  Credentials will be prompted for. 
-  Logs all output to C:\Logs\PrismElementVDIAlignment.log
-  Will output only PVS and MCS workloads under the vm to host alignment.

```
.\PrismElementVDIAlignment.ps1 -pe_source 1.1.1.1 -AdvancedInfo
```

The script will:

-  Will Query Prism Element at 1.1.1.1. 
-  Credentials will be prompted for. 
-  Will verbose output Identity Disk and Provisioning Services identification info to console and log file. 
-  Logs all output to C:\Logs\PrismElementVDIAlignment.log
-  Will output all VM details under the VM to host alignment.