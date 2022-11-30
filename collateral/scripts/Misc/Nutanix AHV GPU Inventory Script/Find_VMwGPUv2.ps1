# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on March 13, 2019
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
$nxPasswordSec = ConvertTo-SecureString $nxPassword -AsPlainText -Force
# Adding PS cmdlets
$loadedsnapins = (Get-PSSnapin -Registered | Select-Object name).name
if (!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))) {
    Add-PSSnapin Nutanix* 
}
if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue)) {
    write-log -message "Nutanix CMDlets are not loaded, aborting the script"
    break
}

# Connecting to the Nutanix Cluster
$nxServerObj = Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPasswordSec -AcceptInvalidSSLCerts
if ($null -eq (get-ntnxclusterinfo)) {
    write-log -message "Cluster connection isn't available, abborting the script"
    break
}

$debug = 2


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
    $Payload = @{
        kind   = "host"
        offset = 0
        length = 999
    } 
    $JSON = $Payload | convertto-json
    try {
        $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
    }
    catch {
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
    $Payload = @{
        kind   = "vm"
        offset = 0
        length = 999
    } 
    $JSON = $Payload | convertto-json
    try {
        $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
    }
    catch {
        Start-Sleep 10
        write-log -message "Going once"
        $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
    }
    write-log -message "We found $($task.entities.count) VMs."
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
    $URL = "https://$($nxIP):9440/api/nutanix/v3/vms/$($uuid)"
    try {
        $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;
    }
    catch {
        Start-Sleep 10
        write-log -message "Going once"
    }  
    Return $task
} 
Function Get-DetailHosts {
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
    }
    catch {
        Start-Sleep 10
        $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;

        write-log -message "Going once"
    }  
    Return $task
} 


# Selecting all the GPUs and their devices IDs in the cluster
$GPU_List = $null
$hosts = Get-Hosts -ClusterPC_IP $nxIP -nxPassword $nxPassword -clusername $nxUser -debug $debug
Foreach ($Hypervisor in $hosts.entities) {
    $detail = Get-DetailHosts -ClusterPC_IP $nxIP -nxPassword $nxPassword -clusername $nxUser -debug $debug -uuid $Hypervisor.metadata.uuid
    [array]$GPU_List += $detail.status.resources.gpu_list
}


write-log -message "Collecting vGPU profiles and Device IDs"
# Grabbing the VMs with a GPU and reporting back 

$VMs = Get-NTNXVM | Where-Object {$_.gpusInUse -Match "true"} 

Foreach ($vm in $VMs) {
    $myvmdetail = Get-DetailVM -ClusterPC_IP $nxIP -nxPassword $nxPassword -clusername $nxUser -debug $debug -uuid $vm.uuid
    $newVMObject = $MyVMdetail
    $devid = $newVMObject.spec.resources.gpu_list
    $GPUUsed = $GPU_List | Where-Object {$_.device_id -eq $devid.device_id} 
    $VMGPU = $GPUUsed | select-object {$_.name} -unique
    $VMGPU1 = $VMGPU.'$_.name'
    write-log -message "Found $($VM.vmName) with $VMGPU1"
}

Disconnect-NTNXCluster *
write-log -message "Disconnecting from the cluster"