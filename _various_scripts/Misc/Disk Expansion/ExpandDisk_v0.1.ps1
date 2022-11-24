# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on March 4, 2019
 
 
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
    # Controller Address
    [Parameter(Mandatory = $true)]
    [Alias('Controller Address')] [String] $CtxController,
    # Disk Size
    [Parameter(Mandatory = $true)]
    [Alias('Disk Size')] [String] $DiskSize
)

# Hardcoding the Machine catelog name
$machinecatalog = "Windows 10 - AHV - Personal"

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
  if ($sev -eq "INFO"){
    write-host "$(get-date -format "hh:mm:ss") | INFO | $message"
  } elseif ($sev -eq "WARN"){
    write-host "$(get-date -format "hh:mm:ss") | WARN | $message"
  } elseif ($sev -eq "ERROR"){
    write-host "$(get-date -format "hh:mm:ss") | ERROR | $message"
  } elseif ($sev -eq "CHAPTER"){
    write-host "`n`n### $message`n`n"
  }
} 
 
# Adding PS cmdlets
$loadedsnapins=(Get-PSSnapin -Registered | Select-Object name).name
if(!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))){
   Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}

$loadedsnapins=(Get-PSSnapin -Registered | Select-Object name).name
if(!($loadedsnapins.Contains("Citrix"))){
   Add-PSSnapin -Name Citrix* 
} 
if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue))
{
    write-log -message "Nutanix CMDlets are not loaded, aborting the script"
    break
}
 
if ($null -eq (Get-PSSnapin -Name Citrix* -ErrorAction SilentlyContinue))
{
    write-log -message "Citrix CMDlets are not loaded, aborting the script"
    break
} 
  
 
# Connecting to the Nutanix Cluster
$nxServerObj = Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPasswordsec -AcceptInvalidSSLCerts -ForcedConnection
 
if ($null -eq (get-ntnxclusterinfo))
{
    write-log -message "Cluster connection isn't available, abborting the script"
    break
}

# Checking if the Machine catalog is persistent
$persistentMCs = Get-BrokerCatalog -adminaddress $CtxController | Where-Object {$_.PersistUserChanges -eq "OnLocal"}
 
#if($persistentMCs.name -match $MachineCatalog) {
 
# Collecting the Persistent Machine Catalog and putting them into a variable
$VMs = get-brokermachine -adminaddress $CtxController -CatalogName $machinecatalog

$DiskSize += 'GB'
$disksizeinbytes = $DiskSize/1KB
 
foreach ($VM in $VMs) {
        $VMName = $VM.MachineName.Split("\")[1]
        write-log -message "VM with the name $VMName found"
        write-log -message "Grabbing the details for $VMName"
        $VMinfo = Get-NTNXVM | Where-Object {$_.vmName -eq $VMName}
        if($vminfo.diskCapacityInBytes -gt $disksizeinbytes)
                {
                $diskingb = $vminfo.diskCapacityInBytes/1GB
                $diskingb1 = [math]::Round($diskingb)
                 write-log -message "The disk found for $VMname is smaller ($diskingb1 GB) than the provided disk size ($DiskSize), executing disk expansion"
                }
        else{
        $diskingb = $vminfo.diskCapacityInBytes/1GB
        write-log -message "The disk found for $VMname is bigger ($diskingb1 GB) than the provided disk size ($DiskSize)"
        }
      }


 
# Disconnect-NTNXCluster *
#write-log -message "Disconnecting from the cluster"