<#
.SYNOPSIS
    Creates a complete inventory of a Nutanix environment.
.DESCRIPTION
    Creates a complete inventory of a Nutanix Cluster configuration using CSV and PowerShell.If you want output to HTML (and be able to export to PDF/CSV from there, please do 'Install-Module PSWriteHTML -Force' in an elevated powershell session. Otherwise the default output will be CSV.
 
.PARAMETER nxIP
    IP address of the Nutanix node you're making a connection too.
.PARAMETER nxUser
    Username for the connection to the Nutanix node
.PARAMETER nxPassword
    Password for the connection to the Nutanix node
 
.EXAMPLE
    PS C:\PSScript > .\nutanix_inventory.ps1 -nxIP "99.99.99.99.99" -nxUser "admin"
.INPUTS
    None.  You cannot pipe objects to this script.
.OUTPUTS
    No objects are output from this script.  
    This script creates a CSV file.
.NOTES
    NAME: Nutanix_Inventory_Script_v3.ps110.
    VERSION: 1.0
    AUTHOR: Kees Baggerman with help from Andrew Morgan, Michell Grauwman and Dave Brett
    CREDITS: Using https://evotec.xyz/out-htmlview-html-alternative-to-out-gridview/ for HTML output.
    LASTEDIT: March 2019
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
    [Alias('Password')] [String] $nxPassword
)
 
# Converting the password to a secure string which isn't accepted for our API connectivity
$nxPasswordSec = ConvertTo-SecureString $nxPassword -AsPlainText -Force
 
 
Function write-log {
    <#
       .Synopsis
       Write logs for debugging purposes
       
       .Description
       This function writes logs based on the message including a time stamp for debugging purposes.
    #>
    param (
        $message,
        $sev = "INFO"
    )
    if ($sev -eq "INFO") {
        write-host "$(get-date -format "hh:mm:ss") | INFO | $message"
    }
    elseif ($sev -eq "WARN") {
        write-host "$(get-date -format "hh:mm:ss") | WARN | $message"
    }
    elseif ($sev -eq "ERROR") {
        write-host "$(get-date -format "hh:mm:ss") | ERROR | $message"
    }
    elseif ($sev -eq "CHAPTER") {
        write-host "`n`n### $message`n`n"
    }
} 
 
# Adding PS cmdlets
$loadedsnapins = (Get-PSSnapin -Registered | Select-Object name).name
if (!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))) {
    Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}
 
if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue)) {
    write-log -message "Nutanix CMDlets are not loaded, aborting the script"
    break
}
 
$debug = 2
 
  
# Connecting to the Nutanix Cluster
$nxServerObj = Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPasswordSec -AcceptInvalidSSLCerts -ForcedConnection
write-log -Message "Connecting to cluster $nxIp"
 
if ($null -eq (get-ntnxclusterinfo)) {
    write-log -message "Cluster connection isn't available, abborting the script"
    break
}
else {
    write-log -message "Connected to Nutanix cluster $nxIP"
}
 
# Fetching data and putting into CSV
$vms = @(get-ntnxvm) #| Where-Object {$_.controllerVm -Match "false"}) 
write-log -message "Grabbing VM information"
write-log -message "Currently grabbing information on $($vms.count) VMs"
 
$FullReport = @()
foreach ($vm in $vms) {                        
    $usedspace = 0
    if (!($vm.nutanixvirtualdiskuuids.count -le $null)) {
        write-log -message "Grabbing information on $($vm.vmName)"
        foreach ($UUID in $VM.nutanixVirtualDiskUuids) {
            $usedspace += (Get-NTNXVirtualDiskStat -Id $UUID -Metrics controller_user_bytes).values[0]
            $workingset_read = (Get-NTNXVirtualDiskStat -Id $UUID -Metrics controller.wss_3600s_read_MB).values[0]
            $workingset_write = (Get-NTNXVirtualDiskStat -Id $UUID -Metrics controller.wss_3600s_write_MB).values[0]
            $workingset_union = (Get-NTNXVirtualDiskStat -Id $UUID -Metrics controller.wss_3600s_union_MB).values[0]
        }
    }
    $vmdisks = Get-ntnxvmdisk -Vmid $vm.uuid 
    foreach ($disk in $vmdisks){
    if (($disk.isCdrom -eq $True) -and ($disk.isEmpty -eq $true)){
    $cdrom = 'CD-Rom found, not mounted'
    }
    if (($disk.isCdrom -eq $True) -and ($disk.isEmpty -eq $false)){
    $cdrom = 'CD-Rom found, image mounted'
    }
    else {
    $cdrom = 'N/A'
    }
    }

    if ($usedspace -gt 0) {
        $usedspace = [math]::round($usedspace / 1gb, 0)
    }
    $container = "NA"
    if (!($vm.vdiskFilePaths.count -le 0)) {
        $container = $vm.vdiskFilePaths[0].split('/')[1]
    }
    if ($vm.nutanixGuestTools.enabled -eq 'False') { $NGTstate = 'Installed'}
    else { 
    $NGTstate = 'Not Installed'
    }
    $props = [ordered]@{
        "VM Name"                       = $vm.vmName
        "Container"                     = $container
        "Protection Domain"             = $vm.protectionDomainName
        "Host Placement"                = $vm.hostName
        "Power State"                   = $vm.powerstate
        "Network Name"                  = $myvmdetail.status.resources.nic_list.subnet_reference.name
        "Network adapters"              = $vm.numNetworkAdapters
        "IP Address(es)"                = $vm.ipAddresses -join ","
        "vCPUs"                         = $vm.numVCpus
        "Number of Cores"               = $myvmdetail.spec.resources.num_sockets
        "Number of vCPUs per core"      = $myvmdetail.spec.resources.num_vcpus_per_socket
        "CPU Usage in %"                = [math]::round($vm.stats.hypervisor_cpu_usage_ppm/10000,2)
        "vRAM (GB)"                     = [math]::round($vm.memoryCapacityInBytes / 1GB, 0)
        "Disk Count"                    = $vm.nutanixVirtualDiskUuids.count
        "Provisioned Space (GB)"        = [math]::round($vm.diskCapacityInBytes / 1GB, 0)
        "Used Space (GB)"               = $usedspace
        "GPU Profile"                   = $VMGPU1
        "VM description"                = $vm.description
        "Guest Operating System"        = $vm.guestOperatingSystem
        "CD-Rom"                        = $cdrom
        "VM Time Zone"                  = $myvmdetail.spec.resources.hardware_clock_timezone
        "Nutanix Guest Tools installed" = $NGTState
        "Working Set Read in MB"        = $workingset_read
        "Working Set Write in MB"       = $workingset_write
        "Union Working Set in MB"       = $workingset_union
        "CPU RDY Time"                  = $vm.stats.'hypervisor.cpu_ready_time_ppm'
        "Rate of the VM reads in IOPS"  = $vm.stats.controller_num_read_iops
        "Rate of the VM writes in IOPS" = $vm.stats.controller_num_write_iops
        "Rate of the VM R/W in IOPS"    = $vm.stats.controller_num_iops    
        "Time stamp"                    = Get-Date -Format "dddd MM/dd/yyyy HH:mm K"
 
    } #End properties
    $Reportobject = New-Object PSObject -Property $props
    $fullreport += $Reportobject
}

$nodes = @(get-ntnxhost) #| Where-Object {$_.controllerVm -Match "false"}) 
write-log -message "-------------------------"
write-log -message "Grabbing host information"
write-log -message "Currently grabbing information on $($nodes.count) hosts"

$FullReportHosts = @()
foreach ($node in $nodes) {                        
    write-log -message "Grabbing information on $($node.Name)"

    $disks = get-ntnxdisk | Where-Object {$_.nodeUuid -eq $node.uuid}
    $SSD = $disks | where-object {$_.storagetiername -eq 'SSD'}
    $SSDSize = $SSD.diskSize | Measure-Object -Average
    $HDD = $disks | where-object {$_.storagetiername -eq 'HDD'}
    $HDDSize = $HDD.diskSize | Measure-Object -Average
    write-log -message "Grabbing disk information on $($node.Name)"

    $host_props = [ordered]@{
        "Host Name"                     = $node.Name
        "Host Hypervisor"               = $node.hypervisorFullName
        "Host model"                    = $node.blockModelName
        "CPU Type"                      = $node.cpuModel
        "CPU Sockets"                   = $node.numCpuSockets
        "CPU Cores"                     = $node.numCpuCores
        "RAM"                           = [math]::round($node.memoryCapacityInBytes / 1GB, 0)
        "OpLog Disk Pct"                = $node.OpLogDiskPct
        "OpLog Disk size"               = $node.OplogDiskSize / 1GB
        "Number of VMs"                 = $node.numVMs
        "Host Bios Version"             = $node.biosVersion
        "Bios Model"                    = $node.biosModel
        "BMC Version"                   = $node.bmcVersion
        "Number of Disks"               = $disks.count
        "Number of SSDs"                = $SSD.count
        "Size of the SSDs in TB"        = $SSDSize.Average / 1TB
        "Number of HDDs"                = $HDD.count
        "Size of the HDDs in TB"        = $HDDSize.Average / 1TB

       
    } #End properties
    $Reportobject1 = New-Object PSObject -Property $host_props
    $fullreportHosts += $Reportobject1

}
 
#Import modules

Try {
$loadedmodules=Get-module | Select-Object name
if(!($loadedmodules.Contains("PSSharedGoods"))){
   Import-Module PSWriteHTML 
   write-log -message "Importing Module PSWriteHTML"
   $fullreport | Out-HtmlView
   $fullreportHosts | Out-HtmlView
   write-log -message "Writing the information to HTML"
}
}
Catch {
#else {
     $fullreport | Export-Csv -Path ~\Desktop\NutanixVMInventory.csv -NoTypeInformation -UseCulture -verbose:$false
     $fullreportHosts | Export-Csv -Path ~\Desktop\NutanixVMInventory.csv -NoTypeInformation -UseCulture -verbose:$false
     write-log -message "Writing the information to the CSV"
#     }
 }
 
# Disconnecting from the Nutanix Cluster
Disconnect-NTNXCluster -Servers *
write-log -message "Closing the connection to the Nutanix cluster $($nxIP)"