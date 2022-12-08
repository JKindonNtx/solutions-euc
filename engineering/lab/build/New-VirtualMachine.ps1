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
#>

# Region Functions and Variables
# ====================================================================================================================================================
# Import the Functions and set the Variables used throughout the remainder of the script
# Validate the build type and get additional information from the relevant platform
# Ensure that the Network, Storage Container and ISO Image are available if building out on Nutanix AHV
# Ensure that connectivity to the MDT Server is available is building the OS using MDT
# ====================================================================================================================================================

# Define the Variables for the script
$functions = get-childitem -Path "/workspaces/solutions-euc/engineering/lab/build/functions/*.psm1"
$JSONFile = "/workspaces/solutions-euc/engineering/lab/build/LabConfig.json"

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
$VLANName = "VLAN" + $($JSON.VM.VLAN)

# Fetching local GitHub user to report owner
$GitHub = Get-GitHubInfo

# Check on build type and if AHV then gather cluster specific information
if ($JSON.vm.Hypervisor -eq "AHV"){
    Write-Host (Get-Date) ":AHV build selected, getting cluster specific information"
<<<<<<< db_function_updates
    $Clusterinfo = Get-NutanixCluster -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)"
    $VMTimezone = ($Clusterinfo.entities | Where-Object {$_.status.resources.network.external_ip -eq $($JSON.Cluster.IP)}).status.resources.config.timezone
    $Containerinfo = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIPath "storage_containers"
    $StorageUUID = ($Containerinfo.entities | Where-Object {$_.name -eq $($JSON.VM.Container)}).storage_container_uuid
    $Networkinfo = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIpath "networks"
    $VLANUUID = ($Networkinfo.entities | Where-Object {$_.name -eq $VLANName}).uuid
    $ISOinfo = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIpath "images"
=======
    $Clusterinfo = Get-Cluster -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)"
    $VMTimezone = ($Clusterinfo.entities | Where-Object {$_.status.resources.network.external_ip -eq $($JSON.Cluster.IP)}).status.resources.config.timezone
    $Containerinfo = Get-NutanixV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "storage_containers"
    $StorageUUID = ($Containerinfo.entities | Where-Object {$_.name -eq $($JSON.VM.Container)}).storage_container_uuid
    $Networkinfo = Get-NutanixV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "networks"
    $VLANUUID = ($Networkinfo.entities | Where-Object {$_.name -eq $VLANName}).uuid
    $ISOinfo = Get-NutanixV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "images"
>>>>>>> main
    $ISOUUID = ($ISOinfo.entities | Where-Object {$_.name -eq $($json.VM.ISO)}).vm_disk_id

    # Validate ISO, Storage Container and VLAN are available for the build
    if (!($ISOinfo.entities | Where-Object {$_.name -eq "$($json.VM.ISO)"})){ Write-Host (Get-Date)":ISO File Not Found"; Write-Host (Get-Date)":Please run New-ClusterConfigAHV.ps1"; exit } else { Write-Host (Get-Date)":ISO file found" }
    if (!($Networkinfo.entities | Where-Object {$_.name -eq "$VLANName"})){ Write-Host (Get-Date)":VLAN File Not Found"; Write-Host (Get-Date)":Please run New-ClusterConfigAHV.ps1"; exit }  else { Write-Host (Get-Date)":VLAN found" }
    if (!($Containerinfo.entities | Where-Object {$_.name -eq "$($json.VM.Container)"})){ Write-Host (Get-Date)":Storage Container Not Found"; Write-Host (Get-Date)":Please run New-ClusterConfigAHV.ps1"; exit }  else { Write-Host (Get-Date)":Storage Container found" }
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
Write-Host "Cluster IP:             $($JSON.Cluster.IP)"
Write-Host "Hypervisor:             $($JSON.vm.Hypervisor)"
Write-Host "Container name:         $($JSON.VM.Container)"
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
    # Get the OS GUID from the MDT configuration files
    if ($JSON.VM.method -eq "MDT"){
        $MdtOSGuid = Get-MdtOSGuid -WinVerBuild "$($OSDetails.WinVerBuild)" -OSversion $OSversion
        Update-MdtTaskSequence -TaskSequenceID "$($OSDetails.TaskSequenceID)" -Guid "$($MdtOSGuid.Guid)"
        Update-MdtTaskSequenceProductKey -JSON $JSON -TaskSequenceID "$($OSDetails.TaskSequenceID)" -SearchString $SearchString -WinVerBuild "$($OSDetails.WinVerBuild)"
        if ($JSON.vm.Hypervisor -eq "AHV"){
            try {
                # Create the VM
                Write-Host (Get-Date)":Create the VM with name "$($OSDetails.Name)""
                $VMTask = New-NutanixVM -JSON $JSON -Name "$($OSDetails.Name)" -VMTimezone $VMtimezone -StorageUUID $StorageUUID -ISOUUID $ISOUUID -VLANUUID $VLANUUID

                # Wait for VM to finish creating
                $VMtaskID = $VMtask.task_uuid
                Write-Host (Get-Date)":Wait for VM create task ($VMtaskID) to finish" 
                Do {
<<<<<<< db_function_updates
                    $VMtaskinfo = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIPath "tasks/$($VMtaskID)"
=======
                    $VMtaskinfo = Get-NutanixV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "tasks/$($VMtaskID)"
>>>>>>> main
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
<<<<<<< db_function_updates
                $VMinfo = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIPath "vms"
                $VMUUID = ($VMinfo.entities | Where-Object {$_.name -eq $("$($OSDetails.Name)")}).uuid
                Write-Host (Get-Date)":ID is $VMUUID"
                $VMNIC = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIPath "vms/$($VMUUID)/nics"
=======
                $VMinfo = Get-NutanixV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "vms"
                $VMUUID = ($VMinfo.entities | Where-Object {$_.name -eq $("$($OSDetails.Name)")}).uuid
                Write-Host (Get-Date)":ID is $VMUUID"
                $VMNIC = Get-NutanixV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "vms/$($VMUUID)/nics"
>>>>>>> main
                $VMMAC = ($VMNIC.entities | Where-Object {$_.is_connected -eq "True"}).mac_address

                # Update the CustomSettings File
                Update-MDTControl -Name "$($OSDetails.Name)" -TaskSequenceID "$($OSDetails.TaskSequenceID)" -VMMAC $VMMAC

                # Power on the VM
                Write-Host (Get-Date)":Power on VM"
<<<<<<< db_function_updates
                Set-NutanixVMPower -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIpath "vms/$($VMUUID)/set_power_state" -Action "ON"
=======
                Set-NutanixVmPowerV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "vms/$($VMUUID)/set_power_state" -Action "ON"
>>>>>>> main
                
                # Preparing MDT phase, monitoring the VM to ensure the Task Sequence has finished
                Write-Host (Get-Date)":Waiting for the VM to PXE boot to the MDT share and start the task sequence"
                Start-Sleep 180 

                # Wait for task sequence to finish and VM Shutdown to be completed
                Write-Host (Get-Date)":Wait for VM to power off" 
                Do {
<<<<<<< db_function_updates
                    Write-Host "Current Power State: $((Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIPath "vms/$($VMUUID)" -Silent $true).power_state)"
                    start-sleep 30
                }
                Until (((Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIPath "vms/$($VMUUID)" -Silent $true).power_state) -eq "off")

                # Remove MDT Build CD-Rom
                Write-Host (Get-Date)":Eject CD-ROM from VM"
                $CDROM = Remove-NutanixCDROM -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -VMUUID $VMUUID
=======
                    Write-Host "Current Power State: $((Get-NutanixV2Silent -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "vms/$($VMUUID)").power_state)"
                    start-sleep 30
                }
                Until (((Get-NutanixV2Silent -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "vms/$($VMUUID)").power_state) -eq "off")

                # Remove MDT Build CD-Rom
                Write-Host (Get-Date)":Eject CD-ROM from VM"
                $CDROM = Remove-NutanixCdRomV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -VMUUID $VMUUID
>>>>>>> main
                Start-Sleep 5

                # Start the VM Back Up
                Write-Host (Get-Date)":Power on VM"
<<<<<<< db_function_updates
                $NutanixVmPowerstate = Set-NutanixVMPower -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIpath "vms/$($VMUUID)/set_power_state" -Action "ON"
=======
                $NutanixVmPowerstate = set-NutanixVmPowerV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "vms/$($VMUUID)/set_power_state" -Action "ON"
>>>>>>> main
                
                # Wait for the VM to get an IP Address
                Write-Host (Get-Date)":Wait for IP-address"
                Start-Sleep 10
                Do {
<<<<<<< db_function_updates
                    $VMNIC = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIPath "vms/$($VMUUID)/nics" -Silent $true
=======
                    $VMNIC = Get-NutanixV2Silent -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "vms/$($VMUUID)/nics"
>>>>>>> main
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
            Write-Host (Get-Date)":Hypervisor type currently not supported, quitting"
            Exit
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



# Region Finalize
# ====================================================================================================================================================
# Region to Shutdown and snapshot the VM
# ====================================================================================================================================================

if ($JSON.vm.Hypervisor -eq "AHV"){
    # Power off the VM
    Write-Host (Get-Date)":Power off VM"
<<<<<<< db_function_updates
    Set-NutanixVMPower -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIpath "vms/$($VMUUID)/set_power_state" -Action "ACPI_SHUTDOWN"
=======
    Set-NutanixVmPowerV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "vms/$($VMUUID)/set_power_state" -Action "ACPI_SHUTDOWN"
>>>>>>> main

    # Wait for task sequence to finish and VM Shutdown to be completed
    Write-Host (Get-Date)":Wait for VM to power off" 
    Do {
<<<<<<< db_function_updates
        Write-Host "Current Power State: $((Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIPath "vms/$($VMUUID)" -Silent $true).power_state)"
        start-sleep 15
    }
    Until (((Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIPath "vms/$($VMUUID)" -Silent $true).power_state) -eq "off")
=======
        Write-Host "Current Power State: $((Get-NutanixV2Silent -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "vms/$($VMUUID)").power_state)"
        start-sleep 15
    }
    Until (((Get-NutanixV2Silent -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "vms/$($VMUUID)").power_state) -eq "off")
>>>>>>> main

    # Finished Build
    Start-Sleep 5
    Write-Host (Get-Date)":Finished installation" 

    # Create VM Snapshot
    Write-Host (Get-Date)":Create snapshot"
<<<<<<< db_function_updates
    $Snapshot = New-NutanixSnapshot -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -VMUUID "$($VMUUID)" -Snapname "$("$($OSDetails.Name)")_Snap_Optimized"
=======
    New-NutanixVmSnapV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -VMUUID "$($VMUUID)" -Snapname "$("$($OSDetails.Name)")_Snap_Optimized"
>>>>>>> main
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
    
    # Fetching local GitHub user to report owner
    $GitHub = Get-GitHubInfo

    # Update Slack Channel
    if ($Ansible -eq "y") {
        $Message = "$($OSDetails.Name) initiated by $($GitHub.UserName) has finished running the Ansible Playbook $PlaybookToRun and has been shutdown and snapshotted. The following actions/installs have been executed: $($yaml.roles)"
    } else {
        $Message = "$($OSDetails.Name) initiated by $($GitHub.UserName) has been shutdown and snapshotted - No post OS Ansible Playbooks have been run"
    }    
    Write-Host (Get-Date)":Updating Slack Channel" 
    Update-Slack -Message $Message -Slack $($JSON.SlackConfig.Slack)
} else {
    Write-Host (Get-Date)":Invalid Hypervisor defined, quitting"
    Exit
}