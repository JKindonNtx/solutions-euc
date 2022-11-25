<#
.SYNOPSIS
    Rolling reboot script for Nutanix CVMs.
.DESCRIPTION
    Rolling reboot script for Nutanix CVMs.
.PARAMETER nxIP
    IP address of the Nutanix node you're making a connection to.
.PARAMETER nxUser
    Username for the connection to the Nutanix node
.PARAMETER nxPassword
    Password for the connection to the Nutanix node
 
.EXAMPLE
    PS C:\PSScript > .\NutanixCVM_Rolling_RebootScript.ps1 -nxIP "99.99.99.99.99" -nxUser "admin"
.INPUTS
    None.  You cannot pipe objects to this script.
.OUTPUTS
    No objects are output from this script.  
    This script creates a CSV file.
.NOTES
    NAME: NutanixCVM_Rolling_RebootScript.ps1.
    VERSION: 1.0
    AUTHOR: Kees Baggerman 
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
$CVMs = get-ntnxvm | Where-Object {$_.controllerVm -Match "True"}
write-log -message "Grabbing CVM information"
write-log -message "Currently grabbing information on $($CVMs.count) VMs"
 
# Rebooting the CVMs in the cluster
foreach ($CVM in $CVMs) {                        
                # Booting the CVM
                $job = Set-NTNXVMPowerState -Vmid $($CVM.vmId) -Transition POWERCYCLE
                Wait-Job $job
                Receive-Job $job
                Write-log -message "Rebooting $Name" 
    }
 
# Disconnecting from the Nutanix Cluster
Disconnect-NTNXCluster -Servers *
write-log -message "Closing the connection to the Nutanix cluster $($nxIP)"