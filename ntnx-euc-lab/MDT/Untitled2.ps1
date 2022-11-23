
# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on March, 2019


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
    [Alias('Password')] [System.Security.SecureString] $nxPassword
)
 
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


# Adding PS cmdlets for Nutanix
$loadedsnapins = (Get-PSSnapin -Registered | Select-Object name).name
if (!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))) {
    Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}

if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue)) {
    write-log -message "Nutanix CMDlets are not loaded, aborting the script"
    break
}

 
# Connecting to the Nutanix Cluster
Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPassword -AcceptInvalidSSLCerts | Out-Null


if ($null -eq (get-ntnxclusterinfo)) {
    write-log -message "Cluster connection isn't available, abborting the script"
    break
}

Write-Log -Message "Connecting to cluster IP $NXIP"
## VM Creation
# Setting Variables
# Computername will take wildcards as well
$Name = "KBTestVM99"
$VMNetwork = "VDI-LAN"

## Network Settings
# Get the VmID of the VM$
$vminfo = Get-NTNXVM | Where-Object {$_.vmName -match $Name}
foreach ($vm in $vminfo) {
    if ($Null -ne $vminfo) {
        $vmId = ($vminfo.vmid.split(":"))[2]

        # Set NIC for VM on default vlan
        $nicuuid = Get-NTNXNetwork | Where-Object {$_.name -eq $VMNetwork}
        if ($Null -ne $nicuuid) {
            $nic = New-NTNXObject -Name VMNicSpecDTO
            $nic.networkUuid = $nicuuid.uuid
            $nic.isConnected = $True

            # Adding a Nic
            Add-NTNXVMNic -Vmid $vmId -SpecList $nic | Out-Null
            Write-Log -Message "Adding a NIC in the $VMNetwork vlan for $($vm.vmName)"
        }
        else {
            Write-Log -Message "Can't find the vlan with the name $VMNetwork"
        }
    }
    else {
        write-log -message "Can't find VM(s) with the name $Name"
    }
}
Disconnect-NTNXCluster *
write-log -message "Disconnecting from cluster IP $NXIP"