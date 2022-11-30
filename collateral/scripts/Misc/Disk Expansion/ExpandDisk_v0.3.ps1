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





function Get-FunctionName {
  param (
    [int]$StackNumber = 1
  ) 
    return [string]$(Get-PSCallStack)[$StackNumber].FunctionName
}
Function REST-Get-VMs {
  Param (
    [string] $PEClusterIP,
    [string] $PxClusterPass,
    [string] $PxClusterUser
  )
  $credPair = "$($PxClusterUser):$($PxClusterPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  write-log -message "Executing VM List"
  $URL = "https://$($PEClusterIP):9440/PrismGateway/services/rest/v1/vms"
  try{
    $task = Invoke-RestMethod -Uri $URL -method "GET" -headers $headers -ea:4;
  } catch {$error.clear()
    sleep 10
    $FName = Get-FunctionName;write-log -message "Error Caught on function $FName" -sev "WARN"
    $task = Invoke-RestMethod -Uri $URL -method "GET" -headers $headers
  }
  write-log -message "We found '$($task.entities.count)' items."
  Return $task
} 
Function REST-VM-Change-Disk-Size {
  Param (
    [string] $PEClusterIP,
    [string] $PxClusterPass,
    [string] $PxClusterUser,
    [Object] $VMDetail,
    [INT]    $SizeGB,
    [INT]    $SCSIID
  )
  [array]$vmdisks = $VMDetail.vm_disk_info | where {$_.is_cdrom -eq $false -and $_.disk_address.device_bus -eq "SCSI"}
  write-log -message "Building Credential object"
  $credPair = "$($PxClusterUser):$($PxClusterPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  ## We expect the VM Detail object here
  write-log -message "Setting '$($SizeGB)' GB Disk to VM '$($VMDetail.uuid)'"
  $URL = "https://$($PCClusterIP):9440/PrismGateway/services/rest/v2.0/vms/$($VMDetail.uuid)/disks/update"
  [decimal] $Newsize = ((($sizeGB * 1024) * 1024 ) * 1024 )
  [array]$vmdisk = $vmdisks | where {$_.disk_address.device_index -eq $SCSIID}
  if ($vmdisk.count -gt 1){
    write-log -message "We have more than 1 disk..." -sev "ERROR"
  }
  [decimal] $Oldsize = $vmdisk.size
  if ($Oldsize -ge $Newsize){
    Write-log -message "This Function can only increase, old size is '$Oldsize' bites"
    Write-log -message "Requested size is '$Newsize' bites" -sev "warn"
  } else {
    Write-log -message "Setting new disk size on VM '$($vmdetail.name)'"
    Write-log -message "Changing old size '$($Oldsize)' Bites"
    Write-log -message "Into new size '$($Newsize)' Bites"
    [string] $flash = $vmdisk.flash_mode_enabled
    $flash = $flash.tolower()
    $json = @"
      {
        "vm_disks": [{
          "disk_address": {
            "vmdisk_uuid": "$($vmdisk.disk_address.vmdisk_uuid)",
            "device_index": $SCSIID,
            "device_bus": "scsi"
          },
          "flash_mode_enabled": $flash,
          "is_cdrom": false,
          "is_empty": false,
          "vm_disk_create": {
            "storage_container_uuid": "$($vmdisk.storage_container_uuid)",
            "size": $($Newsize)
          }
        }]
      }
"@ 
    try{
      $task = Invoke-RestMethod -Uri $URL -method "PUT" -body $json -ContentType 'application/json' -headers $headers -ea:4;
      write-log -message "Disk has been Updated" 
    } catch {$error.clear()
      sleep 10
      $FName = Get-FunctionName;write-log -message "Error Caught on function $FName" -sev "WARN"
      try {
        $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers
      } catch {
        write-log -message "Error Caught on function $FName" -sev "ERROR"
      }
    }
  } 
  Return $task
} 
Function REST-Get-VM-Detail {
  Param (
    [string] $PEClusterIP,
    [string] $PxClusterPass,
    [string] $PxClusterUser,
    [string] $UUID
  )
  write-log -message "Building Credential object"
  $credPair = "$($PxClusterUser):$($PxClusterPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  write-log -message "Executing VM Detail Query using VM on '$uuid'"
  $URL = "https://$($PEClusterIP):9440/PrismGateway/services/rest/v2.0/vms/$($uuid)?include_vm_disk_config=true&include_vm_nic_config=true&includeVMDiskSizes=true&includeAddressAssignments=true"
  write-log -message "Using URL $URL"
  try{
    $task = Invoke-RestMethod -Uri $URL -method "GET" -headers $headers -ea:4;
  } catch {$error.clear()
    sleep 10
    $FName = Get-FunctionName;write-log -message "Error Caught on function $FName" -sev "WARN"
    $task = Invoke-RestMethod -Uri $URL -method "GET" -headers $headers
  }
  write-log -message "We found a VM called '$($task.name)'"
  Return $task
} 
Function Wrap-VM-ExtendDisk {
  param (
   [String] $NXIP,
   [string] $VMName,
   [String] $nxUser,
   [string] $nxPassword,
   [INT]    $NewSizeGB
  ) 
  write-log -message "Grabbing VM Details for '$($VMName)'"
  $VMs = REST-Get-VMs `
    -PEClusterIP $NXIP `
    -PxClusterUser $nxUser `
    -PxClusterPass $nxPassword
  $NTXVM = $VMs.entities | where {$_.VMname -eq $VMname}
  If (!$NTXVM) {
    write-log -message "We cannot find '$($VMName)'" -sev "error"
  }
  write-log -message "Gathering More Details"
  $VMDetail = REST-Get-VM-Detail `
    -PEClusterIP $NXIP `
    -PxClusterUser $nxUser `
    -PxClusterPass $nxPassword `
    -UUID $NTXVM.uuid
  write-log -message "Targeting Disk Larger than 1GB"
  [array]$TargetDisk = $VMDetail.vm_disk_info | where {($_.size / 1GB) -gt 1}
  if ($TargetDisk.count -ge 2){
    write-log -message "We have more than 1 disk to choose from, this VM is not suitable" -sev "ERROR"
  } else {
    write-log -message "Great, our target disk has scsiID '$($targetdisk.disk_address.device_index)'"
  }
  $task = REST-VM-Change-Disk-Size `
    -PEClusterIP $nxIP `
    -PxClusterUser $nxUser `
    -PxClusterPass $nxPassword `
    -VMDetail $VMDetail `
    -SizeGB $NewSizeGB `
    -SCSIID $targetdisk.disk_address.device_index
  do {
    sleep 5
    $tasklist = REST-Px-ProgressMonitor `
      -PxClusterIP $nxIP `
      -PxClusterUser $nxUser `
      -PxClusterPass $nxPassword
    $taskstatus = $tasklist.entities | where {$_.id -eq $task.task_Uuid}
  } until ($taskstatus.percentageCompleted -eq 100)
  write-log -message "Disk Add has status '$($taskstatus.status)'"
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
$persistentMCs = Get-BrokerCatalog -adminaddress $CtxController | where {$_.PersistUserChanges -eq "OnLocal"}
 
#if($persistentMCs.name -match $MachineCatalog) {
 
# Collecting the Persistent Machine Catalog and putting them into a variable
$VMs = get-brokermachine -adminaddress $CtxController -CatalogName $machinecatalog

$DiskSize += 'GB'
$disksizeinbytes = $DiskSize/1KB
 
foreach ($VM in $VMs) {
        $VMName = $VM.MachineName.Split("\")[1]
        write-log -message "VM with the name $VMName found"
        write-log -message "Grabbing the details for $VMName"
        $VMinfo = Get-NTNXVM | Where {$_.vmName -eq $VMName}
        if($vminfo.diskCapacityInBytes -gt $disksizeinbytes)
                {
                $diskingb = $vminfo.diskCapacityInBytes/1GB
                $diskingb1 = [math]::Round($diskingb)
                 write-log -message "The disk found for $VMname is smaller ($diskingb1 GB) than the provided disk size ($DiskSize), executing disk expansion"
                 Wrap-VM-ExtendDisk `
                -NXIP $nxip `
                -nxPassword $nxPassword `
                -nxUser $nxUser `
                -NewSizeGB $DiskSizeGB `
                -VMName $VMName 
              }
                }
        else{
        $diskingb = $vminfo.diskCapacityInBytes/1GB
        write-log -message "The disk found for $VMname is bigger ($diskingb1 GB) than the provided disk size ($DiskSize)"
        }
      


 
# Disconnect-NTNXCluster *
#write-log -message "Disconnecting from the cluster"