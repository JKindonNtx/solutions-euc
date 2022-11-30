<#
.Synopsis
    This Script will build a new VM using standard Nutanix build practices
.Description
    This Script will build a new VM using standard Nutanix build practices
    It will do this using a base OS build then Ansible to lay down the post build applications
    First it will deploy the base OS image after the user selects a Windows Version
    Then it will overlay an Ansible playbook to update the application stack on top of the Operating System
    Once done it will update you in the relevant Slack Channel 
#>

# Region Functions and Variables
# ====================================================================================================================================================
# Import the Functions and set the Variables used throughout the remainder of the script
# ====================================================================================================================================================

# Define the Variables for the script
$functions = get-childitem -Path "/workspaces/solutions-euc/ntnx-euc-lab/deployments/images/mdt/functions/*.psm1"
$JSONFile = "/workspaces/solutions-euc/ntnx-euc-lab/deployments/images/mdt/CreateVM.json"

# Import all the functions required
foreach($function in $functions){ Write-Host (Get-Date)":Importing - $function." ; import-module $function }

# Install the Posh-SSH Module to enable vTPM Connection
Install-Module -Name Posh-SSH -Force

# Read the JSON input file into an object
if($null -eq ($JSON = (Read-JSON -JSONFile $JSONFile))){
    Write-Host (Get-Date) ":Unable to read JSON configuration file, quitting"
    Break 
} else {
    Write-Host (Get-Date) ":JSON configuration file loaded"
}

switch ($JSON.Build.type) {
    "AHV"       { Write-Host (Get-Date) ":AHV build selected" }
    "ESXi"      { Write-Host (Get-Date) ":ESXi build selected" }
    "Azure"     { Write-Host (Get-Date) ":Azure build selected" }
    "AWS"       { Write-Host (Get-Date) ":AWS build selected" }
    "GCP"       { Write-Host (Get-Date) ":GCP build selected" }
    default     { Write-Host (Get-Date) ":Invalid build type selected" }
}