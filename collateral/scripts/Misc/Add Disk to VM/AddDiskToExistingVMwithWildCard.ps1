
# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on January 25, 2019



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
    [Alias('Password')] [System.Security.SecureString] $nxPassword
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

if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue))
{
    write-log -message "Nutanix CMDlets are not loaded, aborting the script"
    break
}

 
# Connecting to the Nutanix Cluster
$nxServerObj = Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPassword -AcceptInvalidSSLCerts

if ($null -eq (get-ntnxclusterinfo))
{
    write-log -message "Cluster connection isn't available, abborting the script"
    break
}

## VM Creation
# Setting Variables
$VMPrefix = Read-Host -Prompt 'Input your VM Prefix including the wildcard (*)'
$ISO = Read-Host -Prompt 'Input the name of the ISO file'



# Searching for the VM defined
write-log -message "Searching for VMs with the prefix $VMPrefix"
$vminfo = Get-NTNXVM | Where-Object {$_.vmName -like $VMPrefix}

# Looping thru all VMs starting with the prefix and adding a disk
Foreach ($vm in $vminfo) {
        Try
        {
        $vmId = ($vm.vmid.split(":"))[2]
        write-log -message "VM found matching the naming: $($vm.vmName) and VM ID $($vmID)"
            ## Disk Creation
            Try
            {
               # Creating the Disk
                $vmDisk =  New-NTNXObject –Name VMDiskDTO
                # Mount ISO Image
                $diskCloneSpec = New-NTNXObject -Name VMDiskSpecCloneDTO
                $ISOImage = (Get-NTNXImage | ?{$_.name -eq $ISO})
                $diskCloneSpec.vmDiskUuid = $ISOImage.vmDiskId
                #setup the new ISO disk from the Cloned Image
                $vmISODisk = New-NTNXObject -Name VMDiskDTO
                #specify that this is a Cdrom
                $vmISODisk.isCdrom = $true
                $vmISODisk.vmDiskClone = $diskCloneSpec


            # Adding the Disk to the VM
            Add-NTNXVMDisk -Vmid $vmId -Disks $vmISODisk | out-null

            write-log -message "Adding a cd-rom drive to $($vm.vmName)"
            }
            Catch
            {
            write-log -message "Failed to add a cd-rom drive to $vm.vmName"
            }
        }
        Catch 
        {
        write-log -message "Could not find a VM with the name $($vm.vmName)"
        }

}

# Disconnect-NTNXCluster *

# write-log -message "Disconnecting from the cluster"