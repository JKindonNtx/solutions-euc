<#
.SYNOPSIS
    This Script will build a new VM using standard Nutanix build practices
.DESCRIPTION
    This Script will build a new VM using standard Nutanix build practices
    It will do this using a base OS build then Ansible to lay down the post build applications
    First it will deploy the base OS image after the user selects a Windows Version
    Then it will overlay an Ansible playbook to update the application stack on top of the Operating System
    Once done it will update you in the relevant Slack Channel 
.NOTES
    There are 5 regions in this script - the details of the regions are:
        - Functions and Variables - this region gathers environment info for the build
        - VM Specifics - this region gathers information about the OS wou wish to build
        - VM Create - this region creates and builds the VM Operating System
        - Ansible - this region runs any post OS build Playbooks
        - Finalize - this region shuts down and shapshots the VM
.NOTES
    CHANGELOG
    | Date | Author | Detail |
    | 18.12.2023 | James Kindon | Added JSONFile param, allowing to specify a custom JSON file. Optional. |
#>

Param(
    [Parameter(Mandatory = $false)]
    [string]$JSONFile
)

# Region Functions and Variables
# ====================================================================================================================================================
# Import the Functions and set the Variables used throughout the remainder of the script
# Validate the build type and get additional information from the relevant platform
# Ensure that the Network, Storage Container and ISO Image are available if building out on Nutanix AHV
# Ensure that connectivity to the MDT Server is available is building the OS using MDT
# ====================================================================================================================================================

# Define the Variables for the script
$functions = get-childitem -Path "/workspaces/solutions-euc/engineering/lab/build/functions/*.psm1"

if ([string]::IsNullOrEmpty($JSONFile)){
    $JSONFile = "/workspaces/solutions-euc/engineering/lab/build/LabConfig.json"
} else {
    $JSONFile = $JSONFile
}


# Import all the functions required
foreach($function in $functions){ Write-Host (Get-Date)":Importing - $function." ; import-module $function }

# Read the JSON input file into an object
if($null -eq ($JSON = (Get-JSON -JSONFile $JSONFile))){
    Write-Host (Get-Date) ":Unable to read JSON configuration file, quitting"
    Break 
} else {
    Write-Host (Get-Date) ":JSON configuration file loaded"
}

# Build VLAN Name
if ($JSON.VM.Hypervisor -eq "AHV") {
    $VLANName = "VLAN" + $($JSON.VM.VLAN)
}
elseif ($JSON.VM.Hypervisor -eq "ESXi") {
    $VLANName = $JSON.VM.VLAN
}

# Fetching local GitHub user to report owner
$GitHub = Get-GitHubInfo

# Sanity Check Github User Account Name to ensure compliance with Nutanix account requirements
If ($GitHub.UserName -like "* *") {
    Write-Host (Get-Date) ":UserName: ($($GitHub.UserName)) contains spaces which are not valid in Nutanix Prism Accounts. Removing space from the Username"
    $GitHub.UserName = $GitHub.UserName -Replace " ",""
    Write-Host (Get-Date) ":Updated UserName is: $($GitHub.UserName)"
}

# Build Cluster name and Storage Name
$AOSCluster = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "cluster"
$AOSClusterName = $AOSCluster.Name
if ($AOSCluster.hypervisor_types -eq 'kVMware') {
    $JSON.VM.Hypervisor = "ESXi"
}
if ($AOSCluster.hypervisor_types -eq 'kKvm') {
    $JSON.VM.Hypervisor = "AHV"
}
$AOSHosts = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "hosts"
$StorageName = "EUC-$($AOSClusterName)"

$Clusterinfo = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "cluster"
$ClusterName = $Clusterinfo.name
# Check on build type and if AHV then gather cluster specific information
if ($JSON.VM.Hypervisor -eq "AHV"){
    Write-Host (Get-Date) ":AHV build selected, getting cluster specific information"
    $VMTimezone = $Clusterinfo.timezone
    #$VMTimezone = "UTC"
    $Containerinfo = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "storage_containers"
    $StorageUUID = ($Containerinfo.entities | Where-Object {$_.name -eq $($StorageName)}).storage_container_uuid
    $Networkinfo = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "networks"
    $VLANUUID = ($Networkinfo.entities | Where-Object {$_.name -eq $VLANName}).uuid
    $ISOinfo = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "images"
    $ISOUUID = ($ISOinfo.entities | Where-Object {$_.name -eq $($json.VM.ISO)}).vm_disk_id

    # Validate ISO, Storage Container and VLAN are available for the build
    if (!($ISOinfo.entities | Where-Object {$_.name -eq "$($json.VM.ISO)"})){ Write-Host (Get-Date)":ISO File Not Found"; Write-Host (Get-Date)":Please run New-ClusterConfigAHV.ps1"; exit } else { Write-Host (Get-Date)":ISO file found" }
    if (!($Networkinfo.entities | Where-Object {$_.name -eq "$VLANName"})){ Write-Host (Get-Date)":VLAN File Not Found"; Write-Host (Get-Date)":Please run New-ClusterConfigAHV.ps1"; exit }  else { Write-Host (Get-Date)":VLAN found" }
    if (!($Containerinfo.entities | Where-Object {$_.name -eq "$($StorageName)"})){ Write-Host (Get-Date)":Storage Container Not Found"; Write-Host (Get-Date)":Please run New-ClusterConfigAHV.ps1"; exit }  else { Write-Host (Get-Date)":Storage Container found" }
} else {
    if ($JSON.vm.Hypervisor -eq "ESXi"){
        #Write-Host (Get-Date) ":Installing VMware PowerCli" 
        #$null = Install-Module VMware.PowerCLI -Force
        if (-not (Get-Module -Name "VMware.PowerCLI" -ListAvailable)) {
            Write-Host (Get-Date) ":Installing VMware PowerCli"
            try {
                Install-Module VMware.PowerCLI -AllowClobber -Force -ErrorAction Stop
            }
            catch {
                Write-Host (Get-Date) ":Failed to Install PowerCLI module. Exit script"
                Break
            }
        }
        Write-Host (Get-Date) ":Connecting to VMware vSphere" 
        $Connection = Connect-VIServer -Server $JSON.VMwareCluster.ip -Protocol https -User $JSON.VMwareCluster.user -Password $JSON.VMwareCluster.password -Force
        if($connection){
            $Cluster = Get-Cluster -Name $ClusterName
        } else {
            Write-Host (Get-Date) ":Connection to vSphere Failed - quitting"
            break 
        }
    } else {
        write-host "Invalid Hypervisor"
        break
    }
} 

# Validate connectivity to MDT Server and mount drive if required
if ($JSON.VM.method -eq "MDT"){
    if((Connect-MDT -UserName "$($json.MDTconfig.UserName)" -Password "$($json.MDTconfig.password)" -Domain "$($json.MDTconfig.Domain)" -MDTServerIP "$($json.MDTconfig.serverIP)" -ShareName "$($json.MDTconfig.share)") -eq $true) { 
        Write-Host (Get-Date) ":Connection to MDT Server is good, continuing" 
    } else { 
        Write-Host (Get-Date) ":No Connection to MDT Server, quitting"
        Exit
    }
}

Write-Host (Get-Date) ":Environment ready and compliant for build, continuing"

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion



# Region VM Specifics
# ====================================================================================================================================================
# Gather information about the VM and Operating System to install
# ====================================================================================================================================================

# Ask for the version of Windows to build
$OSversion = Read-Host "Select Windows version (10, 11 or SRV)"
$OSversion = $OSversion.toupper()

# Build a search string based on the option entered by the user
If ($OSversion -eq "SRV") { $SearchString = "SRV" } else { $SearchString = "W$OSversion" }

# If building VM using MDT gather the OS Specifics
if ($JSON.VM.method -eq "MDT"){
    # Query the XML Config Files Directly as the docker container will not support the MDT Powershell Snapin
    $OSDetails = Get-MdtOS -SearchString $SearchString -OSVersion $OSVersion
} else {
    Write-Host (Get-Date) ":Invalid build method selected, quitting"
    break
}

# Ask if an Ansible Playbook should be run after the OS Build
Do { $Ansible = Read-Host "Would you like to run an Ansible Playbook post OS Build? [y/n]" } Until (($Ansible -eq "y") -or ($Ansible -eq "n"))

if($Ansible -eq "y"){
    $PlaybookToRun = (Get-AnsiblePlaybooks -SearchString $SearchString -AnsiblePath "$($JSON.Ansibleconfig.ansiblepath)").PlaybookToRun
} else {
    $PlaybookToRun = "No Playbooks being run"
}

# Write out a "SNAZZY" header
Write-Host "
  _   _       _              _       __     ____  __   ____        _ _     _ 
 | \ | |_   _| |_ __ _ _ __ (_)_  __ \ \   / /  \/  | | __ ) _   _(_) | __| |
 |  \| | | | | __/ _` | '_ \| \ \/ /  \ \ / /| |\/| | |  _ \| | | | | |/ _` |
 | |\  | |_| | || (_| | | | | |>  <    \ V / | |  | | | |_) | |_| | | | (_| |
 |_| \_|\__,_|\__\__,_|_| |_|_/_/\_\    \_/  |_|  |_| |____/ \__,_|_|_|\__,_|
                                                                                                                                                                                                                                                                 
"

# Display the selected options selected back to the user
Write-Host "
--------------------------------------------------------------------------------------------------------"
if($JSON.vm.Hypervisor -eq "AHV"){
    Write-Host "Cluster IP:             $($JSON.Cluster.IP)"
} else {
    Write-Host "vCenter IP:             $($JSON.VMwareCluster.IP)"
    Write-Host "Cluster Name:           $($ClusterName)"
}
Write-Host "Hypervisor:             $($JSON.vm.Hypervisor)"
Write-Host "Container name:         $($StorageName)"
Write-Host "Configured VLAN:        $VLANName"
Write-Host "Windows version:        $OSversion"
Write-Host "Windows Build:          $($OSDetails.WinVerBuild)"
Write-Host "VM Name:                $($OSDetails.Name)"
Write-Host "vCPUs:                  $($JSON.VM.CPUSockets) sockets - $($JSON.VM.CPUCores) core(s) per socket"
Write-Host "Memory:                 $($JSON.VM.vRAM) MB"
Write-Host "Run Ansible:            $Ansible"
Write-Host "Playbook Path:          $($JSON.Ansibleconfig.ansiblepath)"
Write-Host "Playbook to Run:        $PlaybookToRun"
Write-Host "
--------------------------------------------------------------------------------------------------------"

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion



# Region VM Create
# ====================================================================================================================================================
# Ask for confirmation to start the build process
# Update the MDT Task Sequence with new OS
# Update MDT Unattend file with OS Guid
# Create the VM and install the Operating System
# ====================================================================================================================================================

# Ask for confirmation to start the build - if no the quit
Do { $confirmationStart = Read-Host "Ready to deploy the template? [y/n]" } Until (($confirmationStart -eq "y") -or ($confirmationStart -eq "n"))

if ($confirmationStart -eq 'n') { 
    Write-Host (Get-Date) ":Confirmation denied, quitting"
    exit 
} else {
    #Remove existing SSH keys.
    Write-Host (Get-Date)":Remove existing SSH keys."
    if (((Get-Module -ListAvailable *) | Where-Object {$_.Name -eq "Posh-SSH"})) {
        Import-Module Posh-SSH -RequiredVersion 3.1.1 -force
        Get-SSHTrustedHost | Remove-SSHTrustedHost
    }

    # Get the OS GUID from the MDT configuration files
    if ($JSON.VM.method -eq "MDT"){
        $MdtOSGuid = Get-MdtOSGuid -WinVerBuild "$($OSDetails.WinVerBuild)" -OSversion $OSversion
        Update-MdtTaskSequence -TaskSequenceID "$($OSDetails.TaskSequenceID)" -Guid "$($MdtOSGuid.Guid)"
        Update-MdtTaskSequenceProductKey -JSON $JSON -TaskSequenceID "$($OSDetails.TaskSequenceID)" -SearchString $SearchString -WinVerBuild "$($OSDetails.WinVerBuild)"
        if ($JSON.vm.Hypervisor -eq "AHV"){
            try {
                # Create the VM
                Write-Host (Get-Date)":Create the VM with name "$($OSDetails.Name)""
                try {
                    $VMTask = New-NutanixVM -JSON $JSON -Name "$($OSDetails.Name)" -VMTimezone $VMtimezone -StorageUUID $StorageUUID -ISOUUID $ISOUUID -VLANUUID $VLANUUID -UserName "$($github.username)" -ErrorAction Stop 
                }
                catch {
                    Write-Host $Error[0]
                    Exit
                }

                # Wait for VM to finish creating
                $VMtaskID = $VMtask.task_uuid
                Write-Host (Get-Date)":Wait for VM create task ($VMtaskID) to finish" 
                Do {
                    $VMtaskinfo = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "tasks/$($VMtaskID)"
                    $VMtaskstatus = $VMtaskinfo.percentage_complete
                    If ( $VMtaskstatus -ne 100) {
                        Start-Sleep -Seconds 5
                    }
                    Else {
                        Write-Host (Get-Date)":Task is completed"
                    }
                }
                Until ($VMtaskstatus -eq 100)

                # Add virtual TPM to VM if needed
                if ($($JSON.VM.vTPM) -eq 'true' -or $($OSversion) -eq '11') {
                    Write-Host (Get-Date)":Add vTPM to VM "$($OSDetails.Name)""
                    Set-NutanixvTPM -ClusterIP "$($JSON.Cluster.IP)" -CVMsshpassword "$($JSON.Cluster.CVMsshpassword)" -VMname "$($OSDetails.Name)"
                    Write-Host (Get-Date)":vTPM added to VM "$($OSDetails.Name)""
                } else {
                    Write-Host (Get-Date)":vTPM not required on VM "$($OSDetails.Name)""
                }

                # Get the Virtual Machine Information into a variable
                Write-Host (Get-Date)":Gather Virtual Machine Details"
                $VMinfo = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "vms"
                $VMUUID = ($VMinfo.entities | Where-Object {$_.name -eq $("$($OSDetails.Name)")}).uuid
                Write-Host (Get-Date)":ID is $VMUUID"
                $VMNIC = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "vms/$($VMUUID)/nics"
                $VMMAC = ($VMNIC.entities | Where-Object {$_.is_connected -eq "True"}).mac_address

                # Backup the MDT Control File
                $MDTControlOriginal = Backup-MDTControl
                
                # Update the CustomSettings File
                Update-MDTControl -Name "$($OSDetails.Name)" -TaskSequenceID "$($OSDetails.TaskSequenceID)" -VMMAC $VMMAC

                # Power on the VM
                Write-Host (Get-Date)":Power on VM"
                Set-NutanixVMPower -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "vms/$($VMUUID)/set_power_state" -Action "ON"
                
                # Preparing MDT phase, monitoring the VM to ensure the Task Sequence has finished
                Write-Host (Get-Date)":Waiting for the VM to PXE boot to the MDT share and start the task sequence"
                Start-Sleep 180 

                # Wait for task sequence to finish and VM Shutdown to be completed
                Write-Host (Get-Date)":Wait for VM to power off" 
                Do {
                    Write-Host (Get-Date)":Current Power State: $((Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "vms/$($VMUUID)" -Silent $true).power_state)"
                    start-sleep 30
                }
                Until (((Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "vms/$($VMUUID)" -Silent $true).power_state) -eq "off")

                # Restore the MDT Control File
                Restore-MDTControl -ControlFile $MDTControlOriginal

                # Slack message to inform that MDT job is finished
                Write-Host (Get-Date)":Updating Slack Channel" 
                $MDTmessage = "$($OSDetails.Name) initiated by $($GitHub.UserName) has been created on cluster $($ClusterName) using MDT" 
                Update-Slack -Message $MDTMessage -Slack $($JSON.SlackConfig.Slack)

                # Remove MDT Build CD-Rom
                Write-Host (Get-Date)":Eject CD-ROM from VM"
                $CDROM = Remove-NutanixCDROM -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -VMUUID $VMUUID
                Start-Sleep 5

                # Start the VM Back Up
                Write-Host (Get-Date)":Power on VM"
                $NutanixVmPowerstate = Set-NutanixVMPower -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "vms/$($VMUUID)/set_power_state" -Action "ON"
                
                # Wait for the VM to get an IP Address
                Write-Host (Get-Date)":Wait for IP-address"
                Start-Sleep 10
                Do {
                    $VMNIC = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "vms/$($VMUUID)/nics" -Silent $true
                    $VMip = ($VMNIC.entities | Where-Object {$_.is_connected -eq "True"}).ip_address
                    If ([string]::IsNullOrEmpty($VMip) -Or $VMip.StartsWith("169.254")) {
                        Start-Sleep -Seconds 5
                    }
                    Else {
                        Write-Host (Get-Date)":IP address is $VMip"
                    }
                }
                Until (![string]::IsNullOrEmpty($VMip) -And $VMip -notlike "169.254*")

                # Pause and get ready for next phase
                Start-Sleep 20
                Write-Host (Get-Date)":Base VM Created with Operating System"

            } catch {
                Write-Host (Get-Date)":Can't create the VM"
                Exit
            }
        } else {
            if ($JSON.vm.Hypervisor -eq "ESXi"){
                # Create the VM
                Write-Host (Get-Date)":Create the VM with name "$($OSDetails.Name)""
                try {
                    ## Check sockets etc
                    $CPU = [int]($JSON.VM.CpuSockets) * [int]($JSON.VM.CpuCores)
                    $RAM = [int]($JSON.VM.vRAM) / 1024
                    if($OSversion -eq "SRV"){
                        $GuestID = "windows2019srv_64Guest"
                    } else {
                        $GuestID = "windows9_64Guest"
                    }
                    
                    $VMTask = New-VM -Name $($OSDetails.Name) -ResourcePool $Cluster -Datastore $StorageName -NumCPU $CPU -CoresPerSocket $JSON.VM.CpuCores -MemoryGB $RAM -DiskGB $JSON.VM.Disksize -NetworkName $VLANName -DiskStorageFormat Thin -GuestID $GuestID
                    ## set VM NIC to VMXNet3
                    Write-Host (Get-Date)":Set NIC to VMXNET3"
                    Get-VM $($OSDetails.Name) | Get-ScsiController | Set-ScsiController -Type VirtualLsiLogicSAS -Confirm:$false
                    Get-VM $($OSDetails.Name) | Get-NetworkAdapter | Set-NetworkAdapter -Type Vmxnet3 -Confirm:$false
                }
                catch {
                    Write-Host $Error[0]
                    Exit
                }

                # Wait for VM to finish creating
                Write-Host (Get-Date)":Wait for VM create task to finish" 
                Write-Host (Get-Date)":VM create task finished" 

                # Add virtual TPM to VM if needed
                if ($($JSON.VM.vTPM) -eq 'true' -or $($OSversion) -eq '11') {
                    Write-Host (Get-Date)":Add vTPM to VM "$($OSDetails.Name)""
                    Get-VM $($OSDetails.Name) | New-VTpm
                    Write-Host (Get-Date)":vTPM added to VM "$($OSDetails.Name)""
                } else {
                    Write-Host (Get-Date)":vTPM not required on VM "$($OSDetails.Name)""
                }

                # Get the Virtual Machine Information into a variable
                Write-Host (Get-Date)":Gather Virtual Machine Details"
                $VMinfo = Get-VM $($OSDetails.Name)
                $VMNicDetails = Get-VM $($OSDetails.Name) | Get-NetworkAdapter
                $VMMAC = $VMNicDetails.macAddress

                # Backup the MDT Control File
                $MDTControlOriginal = Backup-MDTControl
                
                # Update the CustomSettings File
                Update-MDTControl -Name "$($OSDetails.Name)" -TaskSequenceID "$($OSDetails.TaskSequenceID)" -VMMAC $VMMAC

                # Connect CD Rom to VM
                Write-Host (Get-Date)":Attach MDT CD ROM"
                $CD = New-CDDrive -VM $($OSDetails.Name) -ISOPath "[$($StorageName)] ISO/LiteTouchPE_x64-NP.iso"
                Set-CDDrive -CD $CD -StartConnected $true -Confirm:$false
                
                # Power on the VM
                Write-Host (Get-Date)":Power on VM"
                Start-VM -VM $($OSDetails.Name)
                
                # Preparing MDT phase, monitoring the VM to ensure the Task Sequence has finished
                Write-Host (Get-Date)":Waiting for the VM to PXE boot to the MDT share and start the task sequence"
                Start-Sleep 180 

                # Wait for task sequence to finish and VM Shutdown to be completed
                Write-Host (Get-Date)":Wait for VM to power off" 
                Do {
                    Write-Host (Get-Date)":Current Power State: $((Get-VM $($OSDetails.Name)).PowerState)"
                    start-sleep 30
                }
                Until (((Get-VM $($OSDetails.Name)).PowerState) -eq "PoweredOff")

                # Restore the MDT Control File
                Restore-MDTControl -ControlFile $MDTControlOriginal

                # Slack message to inform that MDT job is finished
                Write-Host (Get-Date)":Updating Slack Channel" 
                if ($JSON.vm.Hypervisor -eq "AHV"){
                    $MDTmessage = "$($OSDetails.Name) initiated by $($GitHub.UserName) has been created on AHV Cluster $($ClusterName) using MDT" 
                } else {
                    if ($JSON.vm.Hypervisor -eq "ESXi"){
                        $MDTmessage = "$($OSDetails.Name) initiated by $($GitHub.UserName) has been created on VMware Cluster $($ClusterName) using MDT" 
                    }
                }
                Update-Slack -Message $MDTMessage -Slack $($JSON.SlackConfig.Slack)

                # Remove MDT Build CD-Rom
                Write-Host (Get-Date)":Eject CD-ROM from VM"
                $CDROM = get-vm $($OSDetails.Name) | Get-CDDrive | Set-CDDrive -NoMedia -Confirm:$false

                Start-Sleep 5

                # Start the VM Back Up
                Write-Host (Get-Date)":Power on VM"
                Start-VM -VM $($OSDetails.Name)
                
                # Wait for the VM to get an IP Address
                Write-Host (Get-Date)":Wait for IP-address"
                Start-Sleep 10
                Do {
                    $vm = get-vm $($OSDetails.Name)
                    $VMip = $vm.extensiondata.guest.IPAddress
                    If ([string]::IsNullOrEmpty($VMip) -Or $VMip.StartsWith("169.254")) {
                        Start-Sleep -Seconds 5
                    }
                    Else {
                        Write-Host (Get-Date)":IP address is $VMip"
                    }
                }
                Until (![string]::IsNullOrEmpty($VMip) -And $VMip -notlike "169.254*")

                # Pause and get ready for next phase
                Start-Sleep 20
                Write-Host (Get-Date)":Base VM Created with Operating System"

                
            } else {
                Write-Host (Get-Date)":Hypervisor type currently not supported, quitting"
                Exit
            }
        }
    } else {
        Write-Host (Get-Date) ":Invalid build method selected, quitting"
        exit
    }
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion



# Region Ansible
# ====================================================================================================================================================
# Region to run the Ansible Playbook selected
# ====================================================================================================================================================

# Start ansible playbooks if previously selected
if ($Ansible -eq "y") {
    Write-Host (Get-Date)":Start Ansible playbook"
    $Playbook = "$($JSON.Ansibleconfig.ansiblepath)" + $PlaybookToRun
    $command = "ansible-playbook"
    $arguments = " -i " + $VMip + ", " + $playbook + " --extra-vars winos_path=" + $($OSDetails.WinVerBuild)
    start-process -filepath $command -argumentlist $arguments -passthru -wait 
    Write-Host (Get-Date)":Ansible playbook is finished"
} else {
    Write-Host (Get-Date)":Skipping Ansible playbook"
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion


Write-Host (Get-Date)":Waiting for post ansible tasks to complete."
Start-Sleep 120

# Region Finalize
# ====================================================================================================================================================
# Region to Shutdown and snapshot the VM
# ====================================================================================================================================================

if ($JSON.vm.Hypervisor -eq "AHV"){
    # Power off the VM
    Write-Host (Get-Date)":Power off VM"
    Set-NutanixVMPower -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "vms/$($VMUUID)/set_power_state" -Action "ACPI_SHUTDOWN"

    # Wait for task sequence to finish and VM Shutdown to be completed
    Write-Host (Get-Date)":Wait for VM to power off" 
    Do {
        Write-Host "Current Power State: $((Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "vms/$($VMUUID)" -Silent $true).power_state)"
        start-sleep 15
    }
    Until (((Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "vms/$($VMUUID)" -Silent $true).power_state) -eq "off")

    # Finished Build
    Start-Sleep 5
    Write-Host (Get-Date)":Finished installation" 

    # Create VM Snapshot
    Write-Host (Get-Date)":Create snapshot"
    $Snapshot = New-NutanixSnapshot -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -VMUUID "$($VMUUID)" -Snapname "$("$($OSDetails.Name)")_Snap_Optimized"
    Write-Host (Get-Date)":Snapshot created"

    # Grabbing YAML content
    if ($Ansible -eq "y") {
        Install-Module powershell-yaml -Force
        Import-Module powershell-yaml
        [string[]]$fileContent = Get-Content  "$Playbook"
        $content = ''
        foreach ($line in $fileContent) { $content = $content + "`n" + $line }
        $yaml = ConvertFrom-YAML $content
    }
    
    # Fetching local GitHub user to report owner (This replaces username alterations made for account creation and reports Github UserName value)
    $GitHub = Get-GitHubInfo

    # Update Slack Channel
    if ($Ansible -eq "y") {
        $Message = "$($OSDetails.Name) initiated by $($GitHub.UserName) has finished running the Ansible Playbook $PlaybookToRun and has been shutdown and snapshotted on the AHV Cluster $($ClusterName). The following actions/installs have been executed: $($yaml.roles)"
    } else {
        $Message = "$($OSDetails.Name) initiated by $($GitHub.UserName) has been shutdown and snapshotted on the AHV Cluster $($ClusterName) - No post OS Ansible Playbooks have been run"
    }    
    Write-Host (Get-Date)":Updating Slack Channel" 
    Update-Slack -Message $Message -Slack $($JSON.SlackConfig.Slack)
} else {
    if ($JSON.vm.Hypervisor -eq "ESXi"){
        # Power off the VM
        Write-Host (Get-Date)":Power off VM"
        Stop-VMGuest -VM $($OSDetails.Name) -confirm:$false

        # Finished Build
        Start-Sleep 30
        Write-Host (Get-Date)":Finished installation" 

        # Create VM Snapshot
        Write-Host (Get-Date)":Create snapshot"
        New-Snapshot -VM $($OSDetails.Name) -Name "$("$($OSDetails.Name)")_Snap_Optimized"
        Write-Host (Get-Date)":Snapshot created"

        # Grabbing YAML content
        if ($Ansible -eq "y") {
            Install-Module powershell-yaml -Force
            Import-Module powershell-yaml
            [string[]]$fileContent = Get-Content  "$Playbook"
            $content = ''
            foreach ($line in $fileContent) { $content = $content + "`n" + $line }
            $yaml = ConvertFrom-YAML $content
        }
        
        # Fetching local GitHub user to report owner (This replaces username alterations made for account creation and reports Github UserName value)
        $GitHub = Get-GitHubInfo

        # Update Slack Channel
        if ($Ansible -eq "y") {
            $Message = "$($OSDetails.Name) initiated by $($GitHub.UserName) has finished running the Ansible Playbook $PlaybookToRun and has been shutdown and snapshotted on the VMware Cluster $($ClusterName). The following actions/installs have been executed: $($yaml.roles)"
        } else {
            $Message = "$($OSDetails.Name) initiated by $($GitHub.UserName) has been shutdown and snapshotted on the VMware Cluster $($ClusterName) - No post OS Ansible Playbooks have been run"
        }    
        Write-Host (Get-Date)":Updating Slack Channel" 
        Update-Slack -Message $Message -Slack $($JSON.SlackConfig.Slack)
    } else {
        Write-Host (Get-Date)":Invalid Hypervisor defined, quitting"
        Exit
    }
}