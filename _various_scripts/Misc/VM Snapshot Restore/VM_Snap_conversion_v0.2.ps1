# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on September, 2019

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
    [Alias('Password')] [String] $nxPassword,
    # Protection Domain Parameters
    [Parameter(Mandatory = $true)]
    [Alias('PD_Name')] [String] $pdname,
    [Parameter(Mandatory = $true)]
    [Alias('VM Prefix')] [String] $vmprefix
)
 
# Converting the password to a secure string which isn't accepted for our API connectivity
$nxPasswordSec = ConvertTo-SecureString $nxPassword -AsPlainText -Force
$nxpassword = $null​
​
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
 
# Adding Nutanix PS cmdlets
$loadedsnapins = (Get-PSSnapin -Registered | Select-Object name).name
if (!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))) {
    Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}
 
if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue)) {
    Add-PSSnapin -Name NutanixCmdletsPSSnapin
    write-log -message "Loading the Nutanix CMDlets"
}
​
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
​
# Removing previous VMs with the site prefix
$VMs = get-ntnxvm -SearchString $vmprefix
​
Foreach ($vm in $VMs) {
        Write-Log -Message "Removing $($vm.vmName) from $nxIP"
        $removeVMJobID = Remove-NTNXVirtualMachine -vmid $VM.vmid
        
        # Make sure the job to remove the VM got submitted
        if($removeVMJobID){Write-Log -Message "Successfully removed $($VM.vmName) from $nxIP"}
        else{
            Write-log -sev Error -Message  "Failed to remove $VM.vmName from $nxIP"
        }
​
}
​
# Grabbing all available protection domains 
 $pds = Get-NTNXProtectionDomain
 write-log -message "Getting all Protection Domain Snapshots"
​
foreach ($pd in $pds) {
        # Collect Snapshot Information
        $snap = Get-NTNXProtectionDomain -Name $pdname | Get-NTNXProtectionDomainSnapshot
        write-log -message "Getting the snashot in the specified protection domain"
​
         #Restore snapshot
        Restore-NTNXEntity -PdName $pdname -SnapshotId $snap[0].snapshotId -VmNamePrefix $vmprefix | out-null
        $VMName = $snap.consistencygroups.split('{}')[1]
        Write-log -message "Snapshot $PDName restored as $Prefix$vmname"
​
 }
 # Disconnect from Nutanix Cluster
 Disconnect-NTNXCluster -Servers $nxIP
 Write-log -message "Disconnecting from cluster $nxIP"