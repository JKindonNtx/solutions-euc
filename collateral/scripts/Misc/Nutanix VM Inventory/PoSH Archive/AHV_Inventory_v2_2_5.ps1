﻿<#
.SYNOPSIS
    Creates a complete inventory of a Nutanix environment.
.DESCRIPTION
    Creates a complete inventory of a Nutanix Cluster configuration using CSV and PowerShell.

.PARAMETER nxIP
    IP address of the Nutanix node you're making a connection too.
.PARAMETER nxUser
    Username for the connection to the Nutanix node
.PARAMETER nxPassword
    Password for the connection to the Nutanix node

.EXAMPLE
    PS C:\PSScript > .\Nutanix_VM_Inventory_v1.ps1 -nxIP "99.99.99.99.99" -nxUser "admin"
.INPUTS
    None.  You cannot pipe objects to this script.
.OUTPUTS
    No objects are output from this script.  
    This script creates a CSV file.
.NOTES
    NAME: Nutanix_VM_Inventory_v1.ps1
    VERSION: 1.0
    AUTHOR: Kees Baggerman with help from Andrew Morgan
    LASTEDIT: February 2017
#>

# Setting parameters for the connection
[CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = "None") ]

Param(
    # Nutanix cluster IP address
    [Parameter(Mandatory = $true)]
    [Alias('IP')] [string] $nxIP,
     
    # Nutanix cluster username
    [Parameter(Mandatory = $true)]
    [Alias('User')] [string] $nxUser,
    # Nutanix cluster password
    [Parameter(Mandatory = $true)]
    [Alias('Password')] [Security.SecureString] $nxPassword
   
)

# Adding PS cmdlets
$loadedsnapins=(Get-PSSnapin -Registered | select name).name
if(!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))){
   Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}

# Connecting to the Nutanix Cluster
$nxServerObj = Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPassword -AcceptInvalidSSLCerts

# Fetching data and putting into CSV
$vms = @(get-ntnxvm) 

$FullReport=@()
foreach ($vm in $vms){                        
    $usedspace=0
    if(!($vm.nutanixvirtualdiskuuids.count -le 0)){
        foreach($UUID in $VM.nutanixVirtualDiskUuids){
            $usedspace+=(Get-NTNXVirtualDiskStat -Id $UUID -Metrics controller_user_bytes).values[0]
        }
    }
    if ($usedspace -gt 0){
        $usedspace=[math]::round($usedspace /1gb,0)
    }
    $container= "NA"
    if(!($vm.vdiskFilePaths.count -le 0)){
        $container = $vm.vdiskFilePaths[0].split('/')[1]
    }
    $props=[ordered]@{
        "VM Name" = $vm.vmName
        "Container" = $container
        "Protection Domain" = $vm.protectionDomainName
        "Host Placement" = $vm.hostName
        "Power State" = $vm.powerstate
        "Network adapters" = $vm.numNetworkAdapters
        "IP Address(es)" = $vm.ipAddresses -join ","
        "vCPUs" = $vm.numVCpus
        "vRAM (GB)" = [math]::round($vm.memoryCapacityInBytes / 1GB,0)
        "Disk Count"  = $vm.nutanixVirtualDiskUuids.count
        "Provisioned Space (GB)" = [math]::round($vm.diskCapacityInBytes / 1GB,0)
        "Used Space (GB)" = $usedspace
    } #End properties
    $Reportobject= New-Object PSObject -Property $props
    $fullreport+=$Reportobject
}


$fullreport | Export-Csv -Path ~\Desktop\NutanixInventory.csv -NoTypeInformation -UseCulture

# Disconnecting from the Nutanix Cluster
Disconnect-NTNXCluster -Servers *
 
