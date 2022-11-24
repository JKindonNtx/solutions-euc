<#
.Synopsis
    This Script will build a new VM on Nutanix using standard Nutanix build practices
.Description
    This Script will build a new VM on Nutanix using standard Nutanix build practices
    It will do this using a combination of MDT and Ansible
    First it will deploy the MDT base image after the user selects a Windows Version
    Then it will overlay an Ansible playbook to update the application stack on top of the Operating System
    Once done it will update you in the relevant Slack Channel 
    ** BEFORE YOU RUN THIS SCRIPT ENSURE YOU HAVE A DRIVE MOUNTED
    sudo mkdir /mnt/mdt
    sudo chmod 777 /mnt/mdt
    sudo mount -t cifs -o rw,file_mode=0117,dir_mode=0177,username=%%DOMAIN_USER_NAME%%,password='%%DOMAIN_PASSWORD%%',domain=wsperf //%%MDT_SERVER_IP%%/%%MDT_SHARE_NAME%% /mnt/mdt"
#>

# Region Functions and Variables
# ====================================================================================================================================================
# Import the Functions and set the Variables used throughout the remainder of the script
# ====================================================================================================================================================

# Import all the functions required
$functions = get-childitem -Path "/workspaces/ntnx-euc-lab/deployments/images/mdt/functions/*.ps1"
foreach($function in $functions){ Write-Host (Get-Date)":Importing - $function." ; import-module $function }

# Set the variables for the rest of the script
if(Test-Path -Path "/workspaces/ntnx-euc-lab/deployments/images/mdt/CreateVM.json") {
    # JSON file found
    Write-Host (Get-Date)":JSON configuration file found." 

    # Read JSON File
    Write-Host (Get-Date)":Reading JSON File." 
    $VMconfig = Get-Content -Path "/workspaces/ntnx-euc-lab/deployments/images/mdt/CreateVM.json" -Raw | ConvertFrom-Json

    # AHV Cluster Details
    Write-Host (Get-Date)":Reading AHV Details." 
    $mgmtIP = "$($VMconfig.Cluster.ip)"   
    $mgmtUser = "$($VMconfig.Cluster.username)"
    $mgmtPassword = "$($VMconfig.Cluster.password)"
    $mgmtPasswordSec = ConvertTo-SecureString $mgmtPassword -AsPlainText -Force

    # Hypervisor Details
    Write-Host (Get-Date)":Reading Hypervisor Details." 
    $hypervisor = "$($VMconfig.VM.Hypervisor)"

    # MDT Details
    Write-Host (Get-Date)":Reading MDT Details." 
    $MDTServerIP = "$($VMConfig.MDTconfig.serverIP)"
    $MDTShare = "$($VMConfig.MDTconfig.share)"

    # Ansible Details
    Write-Host (Get-Date)":Reading Ansible Details." 
    $ansiblepath = "$($VMconfig.Ansibleconfig.ansiblepath)"

    # Slack Details
    Write-Host (Get-Date)":Reading Slack Details." 
    $Slack = "$($VMConfig.Slackconfig.slack)"

    # Debug Status
    Write-Host (Get-Date)":Reading Debug Details." 
    $debug = 2

    # AHV Cluster Specifics
    Write-Host (Get-Date)":Reading Nutanix Specific Build Details." 
    $Clusterinfo = Get-Cluster -ClusterPC_IP $mgmtIP -nxPassword $mgmtPassword -clusername $mgmtUser -debug $debug
    $VMTimezone = ($Clusterinfo.entities |Where-Object {$_.status.resources.network.external_ip -eq $($mgmtIP)}).status.resources.config.timezone
    $Containerinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "storage_containers" -debug $debug
    $StorageUUID = ($Containerinfo.entities |Where-Object {$_.name -eq $($VMconfig.VM.Container)}).storage_container_uuid
    $Hostinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "hosts" -debug $debug
    $HostUUID = ($Hostinfo.entities |Where-Object {$_.service_vmexternal_ip -eq $($Testhost)}).uuid
    $Networkinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "networks" -debug $debug
    $VLANUUID = ($Networkinfo.entities |Where-Object {$_.name -eq $($VMconfig.VM.VLAN)}).uuid
    $ISOinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "images" -debug $debug
    $ISOUUID = ($ISOinfo.entities |Where-Object {$_.name -eq $($VMconfig.VM.ISO)}).vm_disk_id

    Write-Host (Get-Date)":Variable Read Finished." 
} else {
    # JSON file not found
    # Future State: Add the ability to generate a variable set at runtime
    Write-Host (Fet-Date)":JSON configuration file NOT found - quitting." 
    Break
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion

# Ensure MDT Mount Is Active
# ====================================================================================================================================================
# Check that there is connectivity from the Docker Container to the MDT Server
# ====================================================================================================================================================

if(Test-Path -Path "/mnt/mdt/Control"){
    Write-Host (Get-Date) ":Connection to MDT Server is good, continuing."
} else {
    Write-Host (Get-Date) ":No Connection to MDT Server, quitting."
    Break
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion

# Region Gather Build Specifics
# ====================================================================================================================================================
# Get details from the user for the Build Specifics
# ====================================================================================================================================================

# Ask for the version of Windows to build
$OSversion = Read-Host "Select Windows version (10, 11 or SRV)"
$OSversion = $OSversion.toupper()

# Build a search string based on the option entered by the user
If ($OSversion -eq "SRV") { $SearchString = "SRV" } else { $SearchString = "W$OSversion" }

# Query the XML Config Files Directly as the docker container will not support the MDT Powershell Snapin
$Folders = get-childitem -path "/mnt/mdt/Operating Systems"

# Loop through the folders and display the folders that match the search string to the user
$i = 1 
$Builds = @() 
foreach ($Folder in $Folders){
    if($folder.Name -like "*$SearchString*"){
        $OSDislpay = $folder.name
        Write-Host "$i = $OSDislpay"
        $Builds += $OSDislpay
        $i++
    }
}

# Ask for the specific build of Windows to install
$n = Read-Host "Select a version (Last 4 digits represents the installed updates: YYMM)"

# Get the Windows version selected out of the array and into a variable
$WinVerBuild = $Builds[$n-1]

# Generate a random 4 digit ID
$VMId = (New-Guid).Guid.SubString(1,4)

# Generate the new VM name from the folder name selected minus the patch version and the new random 4 digit ID
$VName = $WinVerBuild.Substring(0,$WinVerBuild.Length-5) 
$Name = "$VName-$VMId"

# Set the task sequence ID to the Build Version Selected Earlier
$TaskSequenceID = "W$OSversion-BASE"

# Ask if an Ansible Playbook should be run after the OS Build
Do { $Ansible = Read-Host "Would you like to run an Ansible Playbook post OS Build? [y/n]" } Until (($Ansible -eq "y") -or ($Ansible -eq "n"))

if($Ansible -eq "y"){
    # Get available Ansible Playbooks
    $PlaybooksAvailable = get-childitem -Path "/workspaces/ntnx-euc-lab/deployments/images/ansible/*.yml"

    # Loop through the Playbooks and display only those relevant to the operating system selected
    $i = 1 
    $Playbooks = @() 
    foreach ($Playbook in $PlaybooksAvailable){
        $PlaybookName = $Playbook.name
        if(($SearchString -eq "SRV") -and ($PlaybookName -like "server_*")){
            Write-Host $i " = " $PlaybookName.substring(7)
            $Playbooks += $PlaybookName
            $i++
        } elseif (($SearchString -like "W*") -and ($PlaybookName -like "workstation_*")) {
            Write-Host $i " = " $PlaybookName.substring(12)
            $Playbooks += $PlaybookName
            $i++
        }
    }

    # Ask for the specific playbook to run
    $p = Read-Host "Select a playbook you would like to run post OS install"

    # Get the Windows version selected out of the array and into a variable
    $PlaybookToRun = $Playbooks[$p-1]
} else {
    $PlaybookToRun = "No Playbooks being run"
}

# Write out a "SNAZZY" header
Write-Host "
_   _ _   _ _____  _    _   _ _____  __  
| \ | | | | |_   _|/ \  | \ | |_ _\ \/ / 
|  \| | | | | | | / _ \ |  \| || | \  /  
| |\  | |_| | | |/ ___ \| |\  || | /  \  
|_| \_|\___/  |_/_/   \_\_| \_|___/_/\_\ 
                                                                                                                                                                                        
"

# Display the selected options selected back to the user
Write-Host "
--------------------------------------------------------------------------------------------------------"
Write-Host "Cluster IP:             $mgmtIP"
Write-Host "Hypervisor:             $hypervisor"
Write-Host "Container name:         $($VMconfig.VM.Container)"
Write-Host "Configured VLAN:        $($VMconfig.VM.VLAN)"
Write-Host "Windows version:        $OSversion"
Write-Host "Windows Build:          $WinVerBuild"
Write-Host "VM Name:                $Name"
Write-Host "vCPUs:                  $($VMconfig.VM.CPUSockets) sockets - $($VMconfig.VM.CPUCores) core(s) per socket"
Write-Host "Memory:                 $($VMconfig.VM.vRAM) MB"
Write-Host "Run Ansible:            $Ansible"
Write-Host "Playbook Path:          $ansiblepath"
Write-Host "Playbook to Run:        $PlaybookToRun"
Write-Host "
--------------------------------------------------------------------------------------------------------"

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion

# Region Confirmation
# ====================================================================================================================================================
# Ask for confirmation to start the build process
# ====================================================================================================================================================

# Ask for confirmation to start the build - if no the quit
Do { $confirmationStart = Read-Host "Ready to deploy the template? [y/n]" } Until (($confirmationStart -eq "y") -or ($confirmationStart -eq "n"))
if ($confirmationStart -eq 'n') { exit }

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion

# Region VM Task Sequence
# ====================================================================================================================================================
# Update the Task Sequence with the Operating System GUID
# ====================================================================================================================================================

# Get OS XML for Operating system GUID
Write-Host (Get-Date) ":Getting available operating systems."
[xml]$OperatingSystems = Get-Content -path "/mnt/mdt/control/operatingsystems.xml"

# Search XML file for matching Operating System
foreach($OperatingSystem in $OperatingSystems.oss.os){
    $OS = $OperatingSystem.Name
    if($OSversion -eq "SRV"){
        # Server based operating system
        if($OS -like "*$WinVerBuild*") {
            if(($OS -like "*ServerDataCenter*") -and ($OS -notlike "*ServerDataCenterCore*")){
                Write-Host (Get-Date) ":Operating System selected - $os."
                $RefImgOSguid = $OperatingSystem.guid
                Write-Host (Get-Date) ":Operating system GUID - $RefImgOSguid"
            }
        }
    } else {
        # Desktop based operating system
        if($OS -like "*$WinVerBuild*") {
            if(($OS -like "*Enterprise*") -and ($OS -notlike "*Enterprise N*")){
                Write-Host (Get-Date) ":Operating System selected - $os"
                $RefImgOSguid = $OperatingSystem.guid
                Write-Host (Get-Date) ":Operating system GUID - $RefImgOSguid"
            }
        }
    }
}

# Read the Task Sequence Details into a variable and update the OS Guid with the build version selected
Write-Host (Get-Date) ":Reading Task Sequence - $TaskSequenceID"
$TSPath = "/mnt/mdt/control/$($TaskSequenceID)/ts.xml"
$TSXML = [xml](Get-Content $TSPath)
$TSXML.sequence.globalVarList.variable | Where-Object {$_.name -eq "OSGUID"} | ForEach-Object {$_."#text" = $RefImgOSguid}
$TSXML.sequence.group | Where-Object {$_.Name -eq "Install"} | ForEach-Object {$_.step} | Where-Object {$_.Name -eq "Install Operating System"} | ForEach-Object {$_.defaultVarList.variable} | Where-Object {$_.name -eq "OSGUID"} | ForEach-Object {$_."#text" = $RefImgOSguid}
$TSXML.Save($TSPath)
Write-Host (Get-Date) ":Updated Task Sequence - $TaskSequenceID with new OS GUID $RefImgOSGuid"

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion

# Region VM Create
# ====================================================================================================================================================
# Region to create the VM and start it up
# MDT Task Sequence will be deployed
# If Selected an additional Ansible Playbook with be deployed after MDT is complete
# ====================================================================================================================================================

# Build the Virtual Machine
Try {

    # Create the VM
    Write-Host (Get-Date)":Create the VM with name $Name."
    $VMtask = Create-VMV2 -VMconfig $VMconfig -Name $Name -VMTimezone $VMtimezone -StorageUUID $StorageUUID -ISOUUID $ISOUUID -VLANUUID $VLANUUID -debug $debug
    $VMtaskID = $VMtask.task_uuid
    Write-Host (Get-Date)":Wait for VM create task ($VMtaskID) to finish." 
    Do {
        $VMtaskinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "tasks/$($VMtaskID)" -debug $debug
        $VMtaskstatus = $VMtaskinfo.percentage_complete
        If ( $VMtaskstatus -ne 100) {
            Start-Sleep -Seconds 5
        }
        Else {
            Write-Host (Get-Date)":Task is completed."
        }
    }
    Until ($VMtaskstatus -eq 100)

    # Add virtual TPM to VM if needed
    if ($($VMconfig.VM.vTPM) -eq 'true' or $($OSversion) -eq '11') {
        Set-VMvTPMacli -ClusterIP $($ClusterIP) -CVMsshpassword $($CVMsshpassword) -VMname $($Name)
    }

    # Get the Virtual Machine Information into a variable
    Write-Host (Get-Date)":Gather Virtual Machine Details."
    $VMinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms" -debug $debug
    $VMUUID = ($VMinfo.entities |Where-Object {$_.name -eq $($Name)}).uuid
    Write-Host (Get-Date)":ID is $VMUUID"
    $VMNIC = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms/$($VMUUID)/nics" -debug $debug
    $VMMAC = ($VMNIC.entities |Where-Object {$_.is_connected -eq "True"}).mac_address

    # Get the contents of the original CustomSettings File
    $OriginalCustomSettings = Get-Content -Path "/mnt/mdt/control/CustomSettings.ini"

    # Update the customsettings.ini file with the new VM Details to enable auto selection of the task sequence
    Write-Host (Get-Date)":Adding $Name to the MDT Control File" 
    Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "`r"
    Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "[$VMMAC]`r"
    Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "SkipWizard=YES`r"
    Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "TaskSequenceID=$TaskSequenceID`r"
    Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "ComputerName=$Name`r"
    Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "OSDComputerName=$Name`r"
    Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "SkipComputerName=YES`r"
    Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "SkipTaskSequence=YES`r"
    Add-Content -Path "/mnt/mdt/control/CustomSettings.ini" -value "SkipWizard=YES`r"
    
    # Power on the VM
    Write-Host (Get-Date)":Power on VM."
    Set-VMpowerV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms/$($VMUUID)/set_power_state" -Action "ON" -debug $debug

    # Preparing MDT phase, monitoring the VM to ensure the Task Sequence has finished
    Write-Host (Get-Date)":Waiting for the VM to PXE boot to the MDT share and start the task sequence"
    Start-Sleep 180 
    
    # Wait for task sequence to finish and VM Shutdown to be completed
    Write-Host (Get-Date)":Wait for VM to power off." 
    Do {
        $VMinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms/$($VMUUID)" -debug $debug
        $VMpower = $VMinfo.power_state
        If ( $VMpower -ne "OFF" ) {
            Start-Sleep -Seconds 5
        }
        Else {
            Write-Host (Get-Date)":VM is $VMpower."
        }
    }
    Until ($VMpower -eq "OFF")

    # Remove MDT Build CD-Rom
    Write-Host (Get-Date)":Eject CD-ROM from VM."
    Remove-CDROMV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -VMUUID "$($VMUUID)" -debug $debug
    Start-Sleep 5

    # Revert CustomSettings File to Original
    Write-Host (Get-Date)":Reverting the MDT Control File back to original" 
    Set-Content -Path "/mnt/mdt/control/CustomSettings.ini" -Value $OriginalCustomSettings

    # Start the VM Back Up
    Write-Host (Get-Date)":Power on VM."
    Set-VMpowerV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms/$($VMUUID)/set_power_state" -Action "ON" -debug $debug

    # Wait for the VM to get an IP Address
    Write-Host (Get-Date)":Wait for IP-address."
    Start-Sleep 10
    Do {
        $VMNIC = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms/$($VMUUID)/nics" -debug $debug
        $VMip = ($VMNIC.entities |Where-Object {$_.is_connected -eq "True"}).ip_address
        If ([string]::IsNullOrEmpty($VMip) -Or $VMip.StartsWith("169.254")) {
            Start-Sleep -Seconds 5
        }
        Else {
            Write-Host (Get-Date)":IP address is $VMip."
        }
    }
    Until (![string]::IsNullOrEmpty($VMip) -And $VMip -notlike "169.254*")

    # Pause and get ready for the Ansible Playbooks
    Start-Sleep 20

    # Start ansible playbooks if previously selected
    if ($Ansible -eq "y") {
        Write-Host (Get-Date)":Start Ansible playbook."
        $Playbook = $ansiblepath + $PlaybookToRun
        $command = "ansible-playbook"
        $arguments = " -i " + $VMip + ", " + $playbook + " --extra-vars winos_path=" + $WinVerBuild
        start-process -filepath $command -argumentlist $arguments -passthru -wait 
        Write-Host (Get-Date)":Ansible playbook is finished."
    } else {
        Write-Host (Get-Date)":Skipping Ansible playbook."
    }

    # Power off the VM
    Write-Host (Get-Date)":Power off VM."                
    Set-VMpowerV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms/$($VMUUID)/set_power_state" -Action "ACPI_SHUTDOWN" -debug $debug
    Write-Host (Get-Date)":Wait for VM to power off." 
    Do {
        $VMinfo = Get-NTNXV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -APIpath "vms/$($VMUUID)" -debug $debug
        $VMpower = $VMinfo.power_state
        If ( $VMpower -ne "OFF" ) {
            Start-Sleep -Seconds 5
        }
        Else {
            Write-Host (Get-Date)":VM is $VMpower."
        }
    }
    Until ($VMpower -eq "OFF")

    # Finished Build
    Start-Sleep 5
    Write-Host (Get-Date)":Finished installation." 

    # Create VM Snapshot
    Write-Host (Get-Date)":Create snapshot."
    New-VMSnapV2 -ClusterIP $mgmtIP -nxPassword $mgmtPassword -nxusrname $mgmtUser -VMUUID "$($VMUUID)" -Snapname "$($Name)_Snap_Optimized" -debug $debug
    Write-Host (Get-Date)":Snapshot created."

    # Update Slack Channel
    if ($Ansible -eq "y") {
        $Message = "$Name has finished running the Ansible Playbook $PlaybookToRun and has been shutdown and snapshotted"
    } else {
        $Message = "$Name has been shutdown and snapshotted - No post OS Ansible Playbooks have been run"
    }    
    Write-Host (Get-Date)":Updating Slack Channel." 
    Update-Slack -Message $Message -Slack $Slack
}
Catch {
    Write-Host (Get-Date)":Can't create the VM"
}

