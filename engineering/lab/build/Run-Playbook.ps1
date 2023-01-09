<#
.SYNOPSIS
    This Script will run an Ansible playbook on a VM using the ip-address.
.DESCRIPTION
    This Script will run an Ansible playbook on a VM using the ip-address.
.NOTES
    This script is based on the New-VirtualMachine.ps1 script. It is created to be able
    to run an Ansible Playbook on a VM that is already deployed using MDT.
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
$OSversion = Read-Host "Select Windows version (10, 11 or SRV)"
$OSversion = $OSversion.toupper()

# Build a search string based on the option entered by the user
If ($OSversion -eq "SRV") { $SearchString = "SRV" } else { $SearchString = "W$OSversion" }

$PlaybookToRun = (Get-AnsiblePlaybooks -SearchString $SearchString -AnsiblePath "$($JSON.Ansibleconfig.ansiblepath)").PlaybookToRun

# Region Ansible
# ====================================================================================================================================================
# Region to run the Ansible Playbook selected
# ====================================================================================================================================================

$VMip = Read-Host "Enter ip-address of VM"
if ($VMip -NotLike "*.*.*.*") { 
    Write-Host (Get-Date) ":Incorrect IP, quitting"
    exit 
}
$WinVerBuild = Read-Host "Enter Windows version build like W10-22H2-2210"
if ($WinVerBuild -NotLike "???-????-????") { 
    Write-Host (Get-Date) ":Incorrect WinVerBuild, quitting"
    exit 
}
# Start ansible playbooks if previously selected
Write-Host (Get-Date)":Start Ansible playbook"
$Playbook = "$($JSON.Ansibleconfig.ansiblepath)" + $PlaybookToRun
$command = "ansible-playbook"
$arguments = " -i " + $VMip + ", " + $playbook + " --extra-vars winos_path=" + $WinVerBuild
start-process -filepath $command -argumentlist $arguments -passthru -wait 
Write-Host (Get-Date)":Ansible playbook is finished"

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion
