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
$nxpassword = $null


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

#region Loading PS Cmdlets
 
# Adding Nutanix PS cmdlets
$loadedsnapins = (Get-PSSnapin -Registered | Select-Object name).name
if (!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))) {
    Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}
 
if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue)) {
    Add-PSSnapin -Name NutanixCmdletsPSSnapin
    write-log -message "Loading the Nutanix CMDlets"
}

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

# Adding PS cmdlets for Citrix
$loadedsnapins = (Get-PSSnapin -Registered | Select-Object name).name
if (!($loadedsnapins.Contains("Citrix"))) {
    Add-PSSnapin -Name Citrix* 
    write-log -message "Citrix cmdlets are loaded, commencing the script"
}

if ($null -eq (Get-PSSnapin -Name Citrix* -ErrorAction SilentlyContinue)) {
    write-log -message "Citrix cmdlets are not loaded, aborting the script"
    break
}

#endregion Loading PS Cmdlets



# Removing previous VMs with the site prefix
$VMs = get-ntnxvm -SearchString $vmprefix

Foreach ($vm in $VMs) {
    Write-Log -Message "Removing $($vm.vmName) from $nxIP"
    $removeVMJobID = Remove-NTNXVirtualMachine -vmid $VM.vmid
        
    # Make sure the job to remove the VM got submitted
    if ($removeVMJobID) { Write-Log -Message "Successfully removed $($VM.vmName) from $nxIP" }
    else {
        Write-log -sev Error -Message  "Failed to remove $VM.vmName from $nxIP"
        #  Break
    }

}

# Grabbing all available protection domains 
$pds = Get-NTNXProtectionDomain
write-log -message "Getting all Protection Domain Snapshots"

foreach ($pd in $pds) {
    # Collect Snapshot Information
    $snap = Get-NTNXProtectionDomain -Name $pdname | Get-NTNXProtectionDomainSnapshot
    write-log -message "Getting the snapshot in the specified protection domain"

    #Restore snapshot
    Restore-NTNXEntity -PdName $pdname -SnapshotId $snap[0].snapshotId -VmNamePrefix $vmprefix | out-null
    $VMName = $snap.consistencygroups.split('{}')[1]
    Write-log -message "Snapshot $PDName restored as '$vmprefix$vmname'"
    $VMName = $vmprefix+$vmname


    # Creating a snapshot of the VM
                Start-Sleep 10
                Do {
                $VM = Get-NTNXVM | Where-Object {$_.vmName -eq $VMName }
                if ($vm.powerState -eq "On") {
                                    # Shutting down VM
                                    Stop-VM $Name | out-null
                                    Write-log -message "Stopping up $VMName"
                                    Start-Sleep 20
                        }
                
                $snaps = Get-NTNXVMSnapshot -Vmid $VM.uuid

                if($VM.count -eq 1) {
                $snap = new-ntnxobject -Name SnapshotSpecDTO
                $snap.vmuuid = $VM.uuid
                $snap.snapshotname = "Ctx_MC_Snapshot"

                New-NTNXSnapshot -SnapshotSpecs $snap | Out-Null
                write-log -message 'Snapshot made from source VM'
                Start-Sleep 5
                }

                If($snaps.linklist.snapshotuuid.count -eq 1) {
                write-log -message 'This VM has one or more snapshots' 
                break
                }
 
                }
                until (
                $null -ne $VM
                )


}





# Disconnect from Nutanix Cluster
Disconnect-NTNXCluster -Servers $nxIP
Write-log -message "Disconnecting from cluster $nxIP"