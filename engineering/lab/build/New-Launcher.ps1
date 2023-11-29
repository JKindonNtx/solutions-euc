<#
.SYNOPSIS
    This Script will build a new Launcher VM
.DESCRIPTION
    This Script will build a new Launcher VM using standard Nutanix build practices
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
$JSONFile = "/workspaces/solutions-euc/engineering/lab/build/LauncherConfig.json"

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

# Sanity Check Github User Account Name to ensure compliance with Nutanix account requirements
If ($GitHub.UserName -like "* *") {
    Write-Host (Get-Date) ":UserName: ($($GitHub.UserName)) contains spaces which are not valid in Nutanix Prism Accounts. Removing space from the Username"
    $GitHub.UserName = $GitHub.UserName -Replace " ",""
    Write-Host (Get-Date) ":Updated UserName is: $($GitHub.UserName)"
}

# Build Cluster name and Storage Name
$AOSCluster = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "cluster"
$AOSClusterName = $AOSCluster.Name
$StorageName = "EUC-$($AOSClusterName)"

# Check on build type and if AHV then gather cluster specific information
Write-Host (Get-Date) ":AHV build selected, getting cluster specific information"
$Clusterinfo = Get-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "cluster"
$VMTimezone = $Clusterinfo.timezone
$ClusterName = $Clusterinfo.name
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

# Build a search string based on the option entered by the user
$OSversion = "10"
$SearchString = "W$($OSversion)"

# If building VM using MDT gather the OS Specifics
$OSDetails = Get-MdtOSLatest -SearchString $SearchString -OSVersion $OSVersion
$OSDetails.Name = ($OSDetails.Name).Replace("W10", "$($JSON.VM.Prefix)")

# Ask if an Ansible Playbook should be run after the OS Build
$PlaybookToRun = Join-Path -Path $JSON.AnsibleConfig.ansiblepath $JSON.AnsibleConfig.ansibleplaybook


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

$MdtOSGuid = Get-MdtOSGuid -WinVerBuild "$($OSDetails.WinVerBuild)" -OSversion $OSversion
Update-MdtTaskSequence -TaskSequenceID "$($OSDetails.TaskSequenceID)" -Guid "$($MdtOSGuid.Guid)"
Update-MdtTaskSequenceProductKey -JSON $JSON -TaskSequenceID "$($OSDetails.TaskSequenceID)" -SearchString $SearchString -WinVerBuild "$($OSDetails.WinVerBuild)"

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
$MDTmessage = "Launcher VM $($OSDetails.Name) initiated by $($GitHub.UserName) has been created on cluster $($ClusterName) using MDT" 
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

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion

# Region Ansible
# ====================================================================================================================================================
# Region to run the Ansible Playbook selected
# ====================================================================================================================================================

# Start ansible playbooks if previously selected

Write-Host (Get-Date)":Start Ansible playbook"
$Playbook = $PlaybookToRun
$command = "ansible-playbook"
$arguments = " -i " + $VMip + ", " + $playbook + " --extra-vars winos_path=" + $($OSDetails.WinVerBuild)
start-process -filepath $command -argumentlist $arguments -passthru -wait 
Write-Host (Get-Date)":Ansible playbook is finished"

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion

# Region Finalize
# ====================================================================================================================================================
# Region to Shutdown and snapshot the VM
# ====================================================================================================================================================

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
Install-Module powershell-yaml -Force
Import-Module powershell-yaml
[string[]]$fileContent = Get-Content  "$Playbook"
$content = ''
foreach ($line in $fileContent) { $content = $content + "`n" + $line }
$yaml = ConvertFrom-YAML $content

# Fetching local GitHub user to report owner (This replaces username alterations made for account creation and reports Github UserName value)
$GitHub = Get-GitHubInfo

# Update Slack Channel
$Message = "Launcher VM $($OSDetails.Name) `n Initiated by $($GitHub.UserName) has finished running the Launcher Ansible Playbook and has been shutdown and snapshotted on the AHV Cluster $($ClusterName). `nThe following actions/installs have been executed: `n$($yaml.roles)"  
Write-Host (Get-Date)":Updating Slack Channel" 
Update-Slack -Message $Message -Slack $($JSON.SlackConfig.Slack)
