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
    [Alias('Password')] [String] $nxPassword
)
 
# Converting the password to a secure string which isn't accepted for our API connectivity
$nxPasswordSec = ConvertTo-SecureString $nxPassword -AsPlainText -Force
# Test​
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

#_ Get-NTNXProtectionDomain
#_ Get-NTNXProtectionDomainAlert
#_ Get-NTNXProtectionDomainConsistencyGroup
#_ Get-NTNXProtectionDomainCronSchedule
# Get-NTNXProtectionDomainEvent
# Get-NTNXProtectionDomainHealthCheckSummary
# Get-NTNXProtectionDomainPendingAction
# Get-NTNXProtectionDomainPendingReplication
# Per PD 
# Get-NTNXProtectionDomainReplication
# Get-NTNXProtectionDomainSnapshot
# Get-NTNXProtectionDomainStat
# Get-NTNXProtectionDomainStatus
# Get-NTNXProtectionStatus


#
# Grabbing all Protection Domains in the cluster
$AllPDs = Get-NTNXProtectionDomain
write-log -message "Getting all Protection Domains"
#​
foreach ($pd in $AllPDs) {
        # Collect Protection Domain Information
        $pdinfo = Get-NTNXProtectionDomain -Name $pd.name 
        write-log -message "$($pd.name): Getting information on the Protection Domain"
        $pdcron = Get-NTNXProtectionDomainCronSchedule -PdName $pd.name
        write-log -message "$($pdcron.pdname): Getting information on the Protection Domain Schedule for Protection Domain"
        Out-Null -inputObject "$pdAction = Get-NTNXProtectionDomainPendingAction -PdName $pd.name"
        write-log -message "$($pd.name): Getting pending action the Protection Domain"
        }

# Grabbing all Consistency Groups in the cluster
$AllCGs = Get-NTNXProtectionDomainConsistencyGroup
#​
foreach ($cg in $AllCGs) {
        # Collect Consistency Group Information
        $pdinfo = Get-NTNXProtectionDomain -PDName $cg.protectionDomainName 
        write-log -message "$($cg.protectionDomainName): Getting information on the Consistency Group"
        }