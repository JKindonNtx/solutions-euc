
# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on January 25, 2019
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
    [Alias('Password')] [string] $nxPassword
)
 
$nxPasswordSec = ConvertTo-SecureString $nxPassword -AsPlainText -Force

# Adding PS cmdlets
$loadedsnapins=(Get-PSSnapin -Registered | Select-Object name).name
if(!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))){
   Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}

if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue))
{
    write-log -message "Nutanix CMDlets are not loaded, aborting the script"
    break
}


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
 
# Connecting to the Nutanix Cluster
$nxServerObj = Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPasswordSec -AcceptInvalidSSLCerts

if ($null -eq (get-ntnxclusterinfo))
{
    write-log -message "Cluster connection isn't available, abborting the script"
    break
}
 
## VM Creation
# Setting Variables
$Name = "KBTestVM99"
$NumVcpus = "2"
$MemoryMB = "2048"
$VMname = $name
$GPUName = "GRID M60-2Q"
$debug = 2

# Creating the VM

write-log -message "Creating $Name with $NumVcpus vCPUs and $MemoryMB MB RAM and a $GPUName profile"

Try
{
new-ntnxvirtualmachine -Name $Name -NumVcpus $NumVcpus -MemoryMB $MemoryMB | out-null
Start-Sleep -s 5
}
Catch 
{
write-log -message "Could not create the VM"
}

## Network Settings
# Get the VmID of the VM
$vminfo = Get-NTNXVM | Where-Object {$_.vmName -eq $Name}
$vmId = ($vminfo.vmid.split(":"))[2]

write-log -message "Grabbing the UUID ($vmID) from $Name"

# Set NIC for VM on default vlan (Get-NTNXNetwork -> NetworkUuid)
Try
{
$nic = New-NTNXObject -Name VMNicSpecDTO
$nic.networkUuid = "669f10d4-0c38-4a87-8660-5affa43956a1"
$vlan = Get-NTNXNetwork

# Adding a Nic
Add-NTNXVMNic -Vmid $vmId -SpecList $nic

write-log -message "Adding a NIC in vlan $($vlan.name) to $Name"
}
Catch
{
write-log -message "Failed to add a NIC in vlan $($vlan.name) to $Name"
}

## Disk Creation
Try
{
# Setting the SCSI disk of 50GB on Containner ID 1025 (get-ntnxcontainer -> ContainerId)
$diskCreateSpec = New-NTNXObject -Name VmDiskSpecCreateDTO
$diskcreatespec.containerid = 1265
$diskcreatespec.sizeMb = 51200

# Creating the Disk
$vmDisk =  New-NTNXObject –Name VMDiskDTO
$vmDisk.vmDiskCreate = $diskCreateSpec

# Adding the Disk to the VM
Add-NTNXVMDisk -Vmid $vmId -Disks $vmDisk

write-log -message "Adding a disk to $Name"
}
Catch
{
write-log -message "Failed to add a disk to $Name"
}




Function Get-Hosts {
    <#
       .Synopsis
       This function will collect the hosts within the specified cluster.
       
       .Description
       This function will collect the hosts within the specified cluster using REST API call based on Invoke-RestMethod
    #>
  Param (
    [string] $debug
  )

  $credPair = "$($nxUser):$($nxPassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  $URL = "https://$($nxIP):9440/api/nutanix/v3/hosts/list"
  $Payload= @{
    kind="host"
    offset=0
    length=999
  } 

  $JSON = $Payload | convertto-json
  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    Start-Sleep 10
    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  }
  write-log -message "We found $($task.entities.count) hosts in this cluster."

  Return $task
} 

Function Get-VMs {
    <#
       .Synopsis
       This function will collect the VMs within the specified cluster.
       
       .Description
       This function will collect the VMs within the specified cluster using REST API call based on Invoke-RestMethod
    #>
  Param (
    [string] $debug
  )

  $credPair = "$($nxUser):$($nxPassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Executing VM List Query"

  $URL = "https://$($nxIP):9440/api/nutanix/v3/vms/list"
  $Payload= @{
    kind="vm"
    offset=0
    length=999
  } 

  $JSON = $Payload | convertto-json
  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    Start-Sleep 10
    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  }
  write-log -message "We found $($task.entities.count) items."

 Return $task
} 

Function Get-DetailVM {
    <#
       .Synopsis
       This function will collect the speficics of the VM we've specified using the Get-VMs function as input.
       
       .Description
       This function will collect the speficics of the VM we've specified using the Get-VMs function as input using REST API call based on Invoke-RestMethod
    #>
  Param (
    [string] $uuid,
    [string] $debug
  )

  
  $credPair = "$($nxUser):$($nxPassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Getting VM Detail for $Name"

  $URL = "https://$($nxIP):9440/api/nutanix/v3/vms/$($uuid)"
  try {
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;
  } catch {
    Start-Sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;

    write-log -message "Going once"
  }  
   Return $task
} 


Function Update-VM {
    <#
       .Synopsis
       This function is used to update the VM according to the specification in the script, the focus here is adding a GPU as other components are added via the native Powershell Commandlets.
       
       .Description
       This function will update the speficics of the VM we've specified using the parameters defined at the start of this script as input using REST API call based on Invoke-RestMethod
    #>
  Param (
    [string] $uuid,
    [object] $VMObject,
    [string] $debug
  )

  
  $credPair = "$($nxUser):$($nxPassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  $json = $VMObject | convertto-json -depth 50

  $URL = "https://$($nxIP):9440/api/nutanix/v3/vms/$($uuid)"
  if ($debug -ge 2){
    $json #| out-file c:\temp\VM.json
  }

  try {
    $task = Invoke-RestMethod -Uri $URL -method "put" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    Start-Sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "put" -body $JSON -ContentType 'application/json' -headers $headers;

    write-log -message "Going once"
  }  
   Return $task
} 

Function Get-DetailHosts {
    <#
       .Synopsis
       This function will collect the speficics of the Host we've specified using the Get-Hosts function as input.
       
       .Description
       This function will collect the speficics of the VM we've specified using the Get-Hosts function as input using REST API call based on Invoke-RestMethod
    #>
  Param (
    [string] $uuid,
    [string] $debug
  )


  
  $credPair = "$($nxUser):$($nxPassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  $URL = "https://$($nxIP):9440/api/nutanix/v3/hosts/$($uuid)"
  try {
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;
  } catch {
    Start-Sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;

    write-log -message "Going once"
  }  
   Return $task
} 



#### GPU Device IDs list #######
#### Select the GPU from $GPU_List

$GPU_List = $null
$hosts = REST-Query-Hosts -ClusterPC_IP $nxIP -nxPassword $nxPassword -clusername $nxUser -debug $debug
Foreach ($Hypervisor in $hosts.entities){
  $detail = REST-Query-DetailHosts -ClusterPC_IP $nxIP -nxPassword $nxPassword -clusername $nxUser -debug $debug -uuid $Hypervisor.metadata.uuid
  [array]$GPU_List += $detail.status.resources.gpu_list
}

# Write $GPU_List, pick a GPU and create an object
#### GPU Device IDs list #######

$GPU = $gpu_list | Where-Object {$_.name -eq $GPUName} | Select-Object -first 1

$VMs = REST-Query-VMs -ClusterPC_IP $nxIP -nxPassword $nxPassword -clusername $nxUser -debug $debug
$MyVM = $VMs.entities | Where-Object {$_.spec.name -match $VMname}
$myvmdetail = REST-Query-DetailVM -ClusterPC_IP $nxIP -nxPassword $nxPassword -clusername $nxUser -debug $debug -uuid $MyVM.metadata.uuid

if (!$myvm.count -and $myvm){
  write-log -message "We found 1 item."
} else {
  write-log -message "We found $($MyVM.count) items."
}

write-log -message "The Full GPU list is available: $($GPU_list.count) items"
write-log -message "Collecting vGPU profiles and Device IDs"

### Modifying set data to the GPU profile 

$GPU_Set = @"
{
 "gpu_list":  [
                  {
                      "vendor":  "$($gpu.Vendor)",
                      "mode":  "$($gpu.mode)",
                      "device_id":  $($gpu.device_id)
                  }
              ]
}
"@

$newVMObject = $MyVMdetail
$newVMObject.psobject.members.remove("Status")
$newVMObject.spec.resources.gpu_list = ($GPU_Set | convertfrom-json).gpu_list


Try
{
REST-Update-VM -ClusterPC_IP $nxIP -nxPassword $nxPassword -clusername $nxUser -debug $debug -uuid $MyVM.metadata.uuid -VMObject $newVMObject | out-null
write-log -message "Assigning $GPUName to $Name"
}
Catch
{
write-log -message "Failed to assing $GPUName to $Name"
}

Disconnect-NTNXCluster *

write-log -message "Disconnecting from the cluster"