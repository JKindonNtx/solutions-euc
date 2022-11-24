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
    [Alias('Container')] [string] $Containername
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

# Importing MDT DB modules
$loadedmodules = (Get-module | Select-Object name).name
if (!($loadedmodules.Contains("MDTDB"))) {
    import-module .\MDTDB.psm1 -force
    write-log -message "Loading the MDT Powershell module"
}
else {
    
}

# Connecting to the MDT DB with current user logon
    Try {
    Connect-MDTDatabase -sqlServer CONTMSQL001 -database MDTLoginvsi | Out-Null
    write-log -message "Connecting to the MDT Database"
    }
    Catch {
     write-log -message "Couldn't connect to the MDT Database"
    }

Try {
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
                Import-Module C:\Temp\MicrosoftDeploymentToolkit.psd1
                Add-PSSnapin "Microsoft.BDD.PSSNAPIN"
                Write-log -message "Loading MDT Powershell cmdlets"

            #$target = "KBTestVM503"
            $deploymentShare = "\\CONTMAUT001\MDTLoginVSI$"


            If (!(Test-Path MDT:)) { New-PSDrive -Name MDT -Root $deploymentShare -PSProvider Microsoft.BDD.PSSNAPIN\MDTPROVIDER }


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

                Start-Sleep 60

                # Creating VM snapshot

                $nxServerObj = Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPassword -AcceptInvalidSSLCerts | out-null
                write-log -message "Reconnecting to the Nutanix Cluster $nxIP"

                $vminfo = Get-NTNXVM | Where-Object {$_.vmName -eq $Name}
                $vmId = ($vminfo.vmid.split(":"))[2]

                $VM = Get-NTNXVM | Where-Object {$_.vmName -eq $Name} | Where-Object {$_.powerState -eq 'Off'}
                $snaps = Get-NTNXVMSnapshot -Vmid $VMInfo.uuid
    
                $snap = new-ntnxobject -Name SnapshotSpecDTO
                $snap.vmuuid = $VMInfo.uuid
                $snap.snapshotname = "Ctx_MC_Snapshot"

                New-NTNXSnapshot -SnapshotSpecs $snap | Out-Null
                write-log -message 'Snapshot made from source VM'
                Start-Sleep 5
                
                If($snaps.linklist.snapshotuuid.count -eq 1) {
                write-log -message 'This VM has one or more snapshots' 
                break
                }

          }
        }       
}
Catch {
    write-log -message "Something happened"
}



Disconnect-NTNXCluster *
write-log -message "Disconnecting from the cluster"