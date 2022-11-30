# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on March, 2019
# With great help of Michell Grauwmans and Dave Brett
 
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
    [Alias('Password')] [System.Security.SecureString] $nxPassword,
     # Nutanix VM Specs
    [Parameter(Mandatory = $true)]
    [Alias('VM Name')] [string] $Name
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
 
# Adding PS cmdlets
$loadedsnapins = (Get-PSSnapin -Registered | Select-Object name).name
if (!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))) {
    Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}
 
if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue)) {
    write-log -message "Nutanix CMDlets are not loaded, aborting the script"
    break
}
 
# Connecting to the Nutanix Cluster
$nxServerObj = Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPassword -AcceptInvalidSSLCerts | out-null
write-log -message "Connecting to the Nutanix Cluster $nxIP"
 
if ($null -eq (get-ntnxclusterinfo)) {
    write-log -message "Cluster connection isn't available, abborting the script"
    break
}


        $vminfo = Get-NTNXVM | Where-Object {$_.vmName -eq $Name}
        $vmId = ($vminfo.vmid.split(":"))[2]

Do {
    $snaps = Get-NTNXVMSnapshot -Vmid $VMInfo.uuid
    If($snaps.linklist.snapshotuuid.count -gt 1) {
    write-log -message 'This VM has more than one snapshot' 
    break
    }
    $snap = new-ntnxobject -Name SnapshotSpecDTO
    $snap.vmuuid = $VMInfo.uuid
    $snap.snapshotname = "Ctx_MC_Snapshot"

    New-NTNXSnapshot -SnapshotSpecs $snap
    write-log -message 'Snapshot made from source VM'
    }
    until (
    Get-NTNXVM | Where-Object {$_.vmName -eq $Name} | Where-Object {$_.powerState -eq 'Off'}
    )


    



# Clear-Host
# $strPassword ="house"
# $strQuit = "Guess again"
# Do {
# $Guess = Read-Host "`n Guess the Password"
# if($Guess -eq $StrPassword)
# {" Correct guess"; $strQuit ="n"}
# else{
# $strQuit = Read-Host " Wrong `n Do you want another guess? (Y/N)"
# }
# } # End of 'Do'
# While ($strQuit -ne "N")
# "`n Ready to do more stuff...