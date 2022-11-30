# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on March, 2019

# Idea: Adding VMware Support

 
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
    [Alias('Password')] [String] $mgmtPassword,
     # Nutanix VM Specs
    [Parameter(Mandatory = $true)]
    [Alias('VM Name')] [string] $Name,
    [Parameter(Mandatory = $true)]
    [Alias('Number of vCPUs')] [string] $NumVcpus,
    [Parameter(Mandatory = $true)]
    [Alias('vRAM')] [string] $MemoryMB,
    [Parameter(Mandatory = $false)]
    [Alias('ISO')] [string] $ISOName,
    [Parameter(Mandatory = $true)]
    [Alias('VLAN')] [string] $VMNetwork,
    [Parameter(Mandatory = $true)]
    [Alias('TaskSequence')] [string] $TaskSequenceID,
    [Parameter(Mandatory = $true)]
    [Alias('Container')] [string] $Containername,
    [Parameter(Mandatory = $true)]
    [Alias('HypervisorType')] [string] $hypervisor
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
 
# Adding Nutanix PS cmdlets
$loadedsnapins = (Get-PSSnapin -Registered | Select-Object name).name
if (!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))) {
    Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}
 
if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue)) {
    Add-PSSnapin -Name NutanixCmdletsPSSnapin
    write-log -message "Loading the Nutanix CMDlets"
}
 
# Importing MDT DB modules
remove-module 'MDTDB' -ErrorAction SilentlyContinue
$loadedmodules = (Get-module | Select-Object name).name
if (!($loadedmodules.Contains("MDTDB"))) {
    import-module .\MDTDB.psm1 -force
    write-log -message "Loading the MDT Powershell module"
}
else {
    write-log -message "MDT CMDlets are not loaded, aborting the script"
    Break
}

# Connecting to the MDT DB with current user logon
    Try {
    Connect-MDTDatabase -sqlServer CONTMSQL001 -database MDTLoginvsi | Out-Null
    write-log -message "Connecting to the MDT Database"
    }
    Catch {
     write-log -message "Couldn't connect to the MDT Database"
    }

#region Creating a VM on AHV
if ($hypervisor -eq 'AHV') {
Try {

    # Connecting to the Nutanix Cluster
    $nxServerObj = Connect-NTNXCluster -Server $mgmtIP -UserName $mgmtUser -Password $mgmtPasswordSec -AcceptInvalidSSLCerts | out-null
    write-log -message "Connecting to the Nutanix Cluster $mgmtIP"
 
    if ($null -eq (get-ntnxclusterinfo)) {
        write-log -message "Cluster connection isn't available, abborting the script"
        break
    }

    # Creating the VM
    new-ntnxvirtualmachine -Name $Name -NumVcpus $NumVcpus -MemoryMB $MemoryMB | Out-Null
    write-log -message "Creating a VM with the name $name"
    Start-Sleep 10

        ## Network Settings
        # Get the VmID of the VM
        $vminfo = Get-NTNXVM | Where-Object {$_.vmName -eq $Name}
        $vmId = ($vminfo.vmid.split(":"))[2]
 
        # Set NIC for VM on default vlan (Get-NTNXNetwork -> NetworkUuid)
        $nicuuid = Get-NTNXNetwork | Where-Object {$_.name -eq $VMNetwork}
        if ($Null -ne $nicuuid) {
            $nic = New-NTNXObject -Name VMNicSpecDTO
            $nic.networkUuid = $nicuuid.uuid
            $nic.isConnected = $True
            
        # Adding a Nic
        Add-NTNXVMNic -Vmid $vmId -SpecList $nic | Out-Null
        write-log -message "Adding a NIC to $Name"
 
        ## Disk Creation
        # Setting the SCSI disk of 50GB on the container specified 
          if ($Null -ne $ContainerName) {
             $Container = $ContainerName
            }
        $Containerid = Get-NTNXContainer | Where-Object {$_.name -eq $container}
        if ($Null -ne $Containerid) {
                $diskCreateSpec = New-NTNXObject -Name VmDiskSpecCreateDTO
                $diskcreatespec.containerid = ($Containerid.id.split(":"))[2]
                $diskcreatespec.sizeMb = 51200
 
                # Creating the Disk
                $vmDisk = New-NTNXObject –Name VMDiskDTO
                $vmDisk.vmDiskCreate = $diskCreateSpec
 
                # Adding the Disk to the VM
                Add-NTNXVMDisk -Vmid $vmId -Disks $vmDisk | Out-Null
                write-log -message "Adding a disk to $Name"
            }
            if ($Null -ne $ISOName) {
             $ISO = $ISOName
            }
            if ($Null -ne $ISO) {
                Try
                {
                # Mount ISO Image
                $diskCloneSpec = New-NTNXObject -Name VMDiskSpecCloneDTO
                $ISOImage = (Get-NTNXImage | Where-Object {$_.name -eq $ISO})
                $diskCloneSpec.vmDiskUuid = $ISOImage.vmDiskId
                #setup the new ISO disk from the Cloned Image
                $vmISODisk = New-NTNXObject -Name VMDiskDTO
                #specify that this is a Cdrom
                $vmISODisk.isCdrom = $true
                $vmISODisk.vmDiskClone = $diskCloneSpec

                # Adding the Disk to the VM
                Add-NTNXVMDisk -Vmid $vmId -Disks $vmISODisk | out-null
                write-log -message "ISO mounted to $Name"
                }
                Catch
                {
                write-log -message "No ISO was mounted to $Name"
                }
               
                # Booting the VM
                Set-NTNXVMPowerOn -Vmid $VMid | out-null
                Write-log -message "Starting $Name" 

                # Grabbing the MAC Address
                $VMNIC = Get-NTNXVMNIC -Vmid $VMid
                Write-log -message "Getting the VM Mac Address" 
               
                # Adding the VM to the MDT database
                # $TaskSequence = $TaskSequenceID
                New-MDTComputer -assettag $Name -macAddress $VMNIC.MacAddress.ToUpper() -settings @{SkipWizard="YES"; TaskSequenceID="$TaskSequenceID"; OSDComputerName="$Name"; SkipComputerName="YES"; SkipTaskSequence="YES" }
                Write-log -message "Adding $Name to the MDT Database" 

                # Preparing MDT phase, monitoring the DB to make sure the VM deployment is finished
                Start-Sleep 180
                Write-log -message "Waiting for the VM to PXE boot to the MDT share and start the task sequence"
                # Import-Module C:\Temp\MicrosoftDeploymentToolkit.psd1
                Add-PSSnapin "Microsoft.BDD.PSSNAPIN" | Out-Null
                Write-log -message "Loading MDT Powershell cmdlets"

           
                $deploymentShare = "\\CONTMAUT001\MDTLoginVSI$"

             
                If (!(Test-Path MDT:)) { New-PSDrive -Name MDT -Root $deploymentShare -PSProvider Microsoft.BDD.PSSNAPIN\MDTPROVIDER | Out-Null } 


                Get-MDTMonitorData -Path MDT: | Where-Object { $_.Name -eq $Name } | Out-Null
                Write-log -message "Getting MDT Monitoring Data"

                # Write-Host "Waiting for task sequence to complete."
                write-log -message 'Waiting for task sequence to complete'
                # If ((Test-Path variable:InProgress) -eq $True) { Remove-Variable -Name InProgress }
                Do {
                    $InProgress = Get-MDTMonitorData -Path MDT: | Where-Object { $_.Name -eq $Name }
                    If ( $InProgress.PercentComplete -lt 100 ) {
                        If ( $InProgress.StepName.Length -eq 0 ) { $StatusText = "Waiting for update" }
                        Start-Sleep -Seconds 5
                    }
                    Else {
                        Write-Progress -Activity "Task sequence complete" -PercentComplete 100
                    }
                }
                Until ($InProgress.CurrentStep -eq $InProgress.TotalSteps)
                write-log -message 'Task Sequence completed'

                $nxServerObj = Connect-NTNXCluster -Server $mgmtIP -UserName $mgmtUser -Password $mgmtPasswordsec -AcceptInvalidSSLCerts | Out-Null 
                write-log -message "Reconnecting to the Nutanix Cluster $mgmtIP"

                # Creating a snapshot of the VM when the task sequence is done
                Start-Sleep 60
                Do {
                $VM = Get-NTNXVM | Where-Object {$_.vmName -eq $Name} | Where-Object {$_.powerState -eq 'Off'}
                $snaps = Get-NTNXVMSnapshot -Vmid $VMInfo.uuid

                if($VM.count -eq 1) {
                $snap = new-ntnxobject -Name SnapshotSpecDTO
                $snap.vmuuid = $VMInfo.uuid
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
        }
        Disconnect-NTNXCluster *
        write-log -message "Disconnecting from the cluster"
        $hypervisor = 'AHV'
        if ($hypervisor -ne 'AHV' -or 'ESXi'){
        write-log -message "No supported hypervisor provided ($hypervisor)"
    }
}
Catch {
    write-log -message "Can't create the VM"
    $hypervisor = 'AHV'
}
}

    
#endregion Creating a VM on AHV

#region Creating a VM on ESXi
if ($hypervisor -eq 'ESXi') {
# Importing the PowerCLI modules
$loadedmodules = (Get-module | Select-Object name).name
if (!($loadedmodules.Contains("VMware"))) {
    import-module VMware.PowerCLI | out-null
    write-log -message "Loading the VMware PowerCLI Powershell module"
}
else {
    write-log -message "VMware PowerCLI Powershell cmdlets are not loaded, aborting the script"
    Break
}


# Setting up the VMware Connection
Try {
Connect-VIServer -Server $mgmtIP -User $mgmtUser -Password $mgmtPassword | Out-Null
Write-log -message "Connected to vCenter on $mgmtIP"
}
Catch {
write-log -message "Unable to connect to vCenter on $mgmtIP"
}
                # Checking if the datastore exists

                $DataStores = Get-DataStore | where-object {$_.Name -eq $ContainerName}
                if($null -eq $Datastores){
                                Write-log -message "The datastore doesn't exists, aborting the script"
                                break
                                }

                # Creating the VM
                Try {
                New-VM -Name $Name -Datastore $datastores.Name -DiskGB 50 -DiskStorageFormat Thin -MemoryGB $([math]::Ceiling(($MemoryMB+'MB')/1GB)) -GuestId windows9_64Guest -NumCpu $NumVcpus -VMHost NTNXKB-A.contoso.local | out-null
                write-log -message "Created $Name with $NumVcpus CPUs and $([math]::Ceiling(($MemoryMB+'MB')/1GB)) vRAM"
                }
                Catch {
                write-log -message "Can't create $Name, aborting script"
                Break
                }
                Try{
                $nic = Get-NetworkAdapter -VM $Name
                $VMNetwork = 'VM Network'
                Remove-NetworkAdapter -NetworkAdapter $nic -confirm:$false
                Get-VM $name | New-NetworkAdapter  -NetworkName $VMNetwork -WakeOnLan -StartConnected -Type Vmxnet3 | Out-Null
                write-log -message "Adding a NIC to $Name in the vlan $VMNetwork"
                }
                Catch {
                write-log -message "Adding a NIC to $name in the vlan $VMNetwork failed"
                break
                }

                # Mounting the CDROM Drive
                Try{
                new-cddrive -VM $Name -IsoPath "[$Containername] ISO\$ISOName" -StartConnected:$true -Confirm:$False | Out-Null
                Write-log -message "Mounting $ISOName to $Name"
                
                }
                Catch {
                write-log -message "Can't mount CDROM drive"
                break
                }

                # Changing boot order of the VM
                $VMName = get-vm "$Name" | get-view
                $HDD1Key = ($VMName.Config.Hardware.Device | ?{$_.DeviceInfo.Label -eq "Hard Disk 1"}).Key
                $bootHDD1 = New-Object -TypeName VMware.Vim.VirtualMachineBootOptionsBootableDiskDevice -Property @{"DeviceKey" = $HDD1Key}
                $BootCD = New-Object -Type VMware.Vim.VirtualMachineBootOptionsBootableCdromDevice
 
                $spec = New-Object VMware.Vim.VirtualMachineConfigSpec -Property @{
 
                "BootOptions" = New-Object VMware.Vim.VirtualMachineBootOptions -Property @{
 
                BootOrder = $BootCD, $BootHDD1
                }
                }
                $VMName.ReconfigVM_Task($spec)
                Write-log -message "Changed boot order for $Name to CD-ROM" 
                

                # Adding the VM to the MDT database
                $VMNic =  Get-VM $name | get-networkadapter
                New-MDTComputer -assettag $Name -macAddress $VMNIC.MacAddress.ToUpper() -settings @{SkipWizard="YES"; TaskSequenceID="$TaskSequenceID"; OSDComputerName="$Name"; SkipComputerName="YES"; SkipTaskSequence="YES" }
                Write-log -message "Adding $Name to the MDT Database" 

                # Starting the VM
                Start-Sleep 10
                Start-VM $Name | out-null
                Write-log -message "Starting up $name"

                # Preparing MDT phase, monitoring the DB to make sure the VM deployment is finished
                Start-Sleep 180
                Write-log -message "Waiting for the VM to PXE boot to the MDT share and start the task sequence"
                # Import-Module C:\Temp\MicrosoftDeploymentToolkit.psd1
                Add-PSSnapin "Microsoft.BDD.PSSNAPIN" | Out-Null
                Write-log -message "Loading MDT Powershell cmdlets"

           
                $deploymentShare = "\\CONTMAUT001\MDTLoginVSI$"

             
                If (!(Test-Path MDT:)) { New-PSDrive -Name MDT -Root $deploymentShare -PSProvider Microsoft.BDD.PSSNAPIN\MDTPROVIDER | Out-Null } 


                Get-MDTMonitorData -Path MDT: | Where-Object { $_.Name -eq $Name } | Out-Null
                Write-log -message "Getting MDT Monitoring Data"

                # Write-Host "Waiting for task sequence to complete."
                write-log -message 'Waiting for task sequence to complete'
                # If ((Test-Path variable:InProgress) -eq $True) { Remove-Variable -Name InProgress }
                Do {
                    $InProgress = Get-MDTMonitorData -Path MDT: | Where-Object { $_.Name -eq $Name }
                    If ( $InProgress.PercentComplete -lt 100 ) {
                        If ( $InProgress.StepName.Length -eq 0 ) { $StatusText = "Waiting for update" }
                        Start-Sleep -Seconds 5
                    }
                    Else {
                        Write-Progress -Activity "Task sequence complete" -PercentComplete 100
                    }
                }
                Until ($InProgress.CurrentStep -eq $InProgress.TotalSteps)
                write-log -message 'Task Sequence completed'

                # Creating snapshot
                while ($name.ExtensionData.Runtime.PowerState -eq "poweredOn"){
                Start-Sleep -Seconds 2
                $name.ExtensionData.UpdateViewData("Runtime.PowerState")
                }
                New-Snapshot -VM $Name -Name Ctx_MC_Snapshot | Out-null
                write-log -message 'Snapshot made from source VM'
                
                Disconnect-VIServer * -Confirm:$False | out-null
                write-log -message "Disconnecting from vCenter"
                $hypervisor = 'ESXi'

                if ($hypervisor -ne 'AHV' -or 'ESXi'){
                write-log -message "supported hypervisor provided ($hypervisor)"
}

}

#endregion Creating a VM on ESXi


