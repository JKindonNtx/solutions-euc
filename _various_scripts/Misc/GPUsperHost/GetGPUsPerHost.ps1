# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on March, 2019

# Setting parameters for the connection
[CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = "None") ]
 
Param(
    # Nutanix cluster IP address
    [Parameter(Mandatory = $true)]
    [Alias('IP')] [string] $mgmtIP,   
    # Nutanix cluster username
    [Parameter(Mandatory = $true)]
    [Alias('User')] [string] $mgmtUser,
    # Nutanix cluster password
    [Parameter(Mandatory = $true)]
    [Alias('Password')] [String] $mgmtPassword
)

$mgmtPasswordSec = ConvertTo-SecureString $mgmtPassword -AsPlainText -Force                         # Converting the Nutanix Prism password to a secure string to connect to the cluster

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

    # Connecting to the Nutanix Cluster
    $nxServerObj = Connect-NTNXCluster -Server $mgmtIP -UserName $mgmtUser -Password $mgmtPasswordSec -AcceptInvalidSSLCerts | out-null
    write-log -message "Connecting to the Nutanix Cluster $mgmtIP"
 
    if ($null -eq (get-ntnxclusterinfo)) {
        write-log -message "Cluster connection isn't available, abborting the script"
        break
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

$HostConfig = get-ntnxhost
Foreach ($Node in $Hostconfig)
    {
    $GPUs = get-ntnxhost | Where-Object {$_.Name -eq $node.Name}
    if ($GPUs.HostGPUs -ne $null) {
    Write-log -message "Number of GPUs in $($node.Name) is $($Node.HostGPUs.count)"
    Write-log -message "Host $($node.Name) has the $($Node.HostGPUs) configured"
    }
    else {break}
    }