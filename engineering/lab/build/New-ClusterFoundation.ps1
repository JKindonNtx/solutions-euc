<#
.SYNOPSIS
    This Script will Foundation a new Nutanix Cluster
.NOTES
    There are 2 regions in this script - the details of the regions are:
        - Gather Foundation Info - this region gathers environment info for the build
        - Foundation - this region foundations the cluster ready for use
#>

#region Gather Foundation Info

Param()

# Define the Variables for the script
If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }
$functions = get-childitem -Path "$($ScriptRoot)\functions\*.psm1"
$JSONFile = "$($ScriptRoot)\LabConfig.json"

# Import all the functions required
foreach($function in $functions){ Write-Host (Get-Date)":Importing - $function." ; import-module $function }

# Read the JSON input file into an object
if($null -eq ($JSON = (Get-JSON -JSONFile $JSONFile))){
    Write-Host (Get-Date) ":Unable to read JSON configuration file, quitting"
    Exit 1
} else {
    Write-Host (Get-Date) ":JSON configuration file loaded"
}

# Install the NCP Ansible Collection
Write-Host (Get-Date) ":Installing Nutanix NCP Ansible Collection"
$NCP = & ansible-galaxy collection install nutanix.ncp
if(($NCP -like "*installed successfully*") -or ($NCP -like "*already installed*")){
    Write-Host (Get-Date) ":Nutanix NCP Ansible Collection Installed"
} else {
    Write-Host (Get-Date) ":Nutanix NCP Ansible Collection Install Failed, Quitting"
    Exit 1
}

if($($JSON.Cluster.Hypervisor) -eq "AHV"){
    Write-Host (Get-Date)":Hypervisor $($JSON.Cluster.Hypervisor) selected, running foundation."

    # Get AOS Images Available
    Write-Host (Get-Date)":Getting AOS Images from Foundation"
    $PlaybookPath = "$($JSON.Ansibleconfig.ansiblepath)"
    $Playbook = "nutanix_foundation_get_nos_packages.yml"
    $PlaybookToRun = Join-Path -Path $PlaybookPath -ChildPath $Playbook
    $NosData = & ansible-playbook $PlaybookToRun --extra-vars="foundation_ip=$($JSON.Cluster.FvmIP)"

    # Get NOS Version to Use
    $i = 1 
    $NOS = @() 
    $SearchString = "nutanix_installer_package"
    foreach($Line in $NosData){
        if($Line -like "*$SearchString*"){
                $NOSDisplay = ($Line.Trim()).Replace("""", "")
                Write-Host "$i = $NOSDisplay"
                $NOS += $NOSDisplay
                $i++
        }
    }

    # Ask for the specific build to install
    $n = Read-Host "Select a version of AOS to install"

    # Get the Windows version selected out of the array and into a variable
    $NOSVersion = $NOS[$n-1]

    $ClusterToFoundation = (Get-AnsiblePlaybooks -SearchString $($JSON.Cluster.Hypervisor) -AnsiblePath "$($JSON.Ansibleconfig.ansiblepath)").PlaybookToRun

    Write-Host (Get-Date)":Building Foundation Playbook"
    $PlaybookToRun = Join-Path -Path $PlaybookPath -ChildPath $ClusterToFoundation

} else {
    if($($JSON.Cluster.Hypervisor)){
        Write-Host (Get-Date)":Hypervisor $($JSON.Cluster.Hypervisor) selected, running foundation."
    } else {
        Write-Host (Get-Date)":Hypervisor $($JSON.Cluster.Hypervisor) Not Supported, Quitting."
        Exit 1
    }
}

#endregion Gather Foundation Info

#region Foundation

# Fetching local GitHub user to report owner
$GitHub = Get-GitHubInfo

# Sanity Check Github User Account Name to ensure compliance with Nutanix account requirements
If ($GitHub.UserName -like "* *") {
    Write-Host (Get-Date) ":UserName: ($($GitHub.UserName)) contains spaces which are not valid in Nutanix Prism Accounts. Removing space from the Username"
    $GitHub.UserName = $GitHub.UserName -Replace " ",""
    Write-Host (Get-Date) ":Updated UserName is: $($GitHub.UserName)"
}

# Ask for confirmation to start the build - if no the quit

Do { $confirmationNC2 = Read-Host "Is this cluster running on NC2? [y/n]" } Until (($confirmationNC2 -eq "y") -or ($confirmationNC2 -eq "n"))

if ($confirmationNC2 -eq 'y') { 
    Write-Host "This script CANNOT be used on NC2"
    Write-Host "Please foundation the cluster using the Nutanix Cloud Portal"
    exit  1
}

# Validate if post configuration is required
Do { $PostConfigure = Read-Host "Would you like to configure the cluster after Nutanix Foundation is finished? [y/n]" } Until (($PostConfigure -eq "y") -or ($PostConfigure -eq "n"))

if ($PostConfigure -eq 'n') { 
    $Configure = $false
} else {
    $Configure = $true
}

# Clear the display
Clear-Host

# Write out a "SNAZZY" header
Write-Host "
  _   _       _              _        _____                     _       _   _             
 | \ | |_   _| |_ __ _ _ __ (_)_  __ |  ___|__  _   _ _ __   __| | __ _| |_(_) ___  _ __  
 |  \| | | | | __/ _` | '_ \| \ \/ / | |_ / _ \| | | | '_ \ / _` |/ _` | __| |/ _ \| '_ \ 
 | |\  | |_| | || (_| | | | | |>  <  |  _| (_) | |_| | | | | (_| | (_| | |_| | (_) | | | |
 |_| \_|\__,_|\__\__,_|_| |_|_/_/\_\ |_|  \___/ \__,_|_| |_|\__,_|\__,_|\__|_|\___/|_| |_|
                                                                                                                                                                                                                                                                                                                                                                      
"

# Display the selected options selected back to the user
Write-Host "
--------------------------------------------------------------------------------------------------------"
Write-Host "Hypervisor:                $($JSON.Cluster.Hypervisor)"
Write-Host "Foundation VM:             $($JSON.Cluster.FvmIP)"
Write-Host "NOS Version:               $($NOSVersion)"
Write-Host "Playbook to Run:           $PlaybookToRun"
Write-Host "Post Foundation Config:    $Configure"
Write-Host "
--------------------------------------------------------------------------------------------------------"

Do { $confirmationStart = Read-Host "Ready to foundation the cluster? [y/n]" } Until (($confirmationStart -eq "y") -or ($confirmationStart -eq "n"))

if ($confirmationStart -eq 'n') { 
    Write-Host (Get-Date) ":Confirmation denied, quitting"
    Exit 1
} else {

    # Display Console Output
    Write-Host (Get-Date)":Please wait whilst the Nutanix nodes built"
    Write-Host (Get-Date)":This can take up to 60 minutes"
    Write-Host (Get-Date)":If you would like to check the progress of the job please click the link below"
    Write-Host (Get-Date)":http://$($JSON.Cluster.FvmIP):8000"

    # Get Cluster Name
    $ClusterYAML = $PlaybookToRun.Split("_")
    $ClusterName = ($ClusterYAML[3]).Replace(".yml", "")

    # Update Slack
    $SlackMessage = "EUC Cluster Foundation initiated by $($GitHub.UserName)`n`nCluster Name: $($ClusterName)`nHypervisor Type: $($JSON.Cluster.Hypervisor)`nFoundation VM: $($JSON.Cluster.FvmIP)`nNOS Verion: $($NOSVersion)`nPost Foundation Config: $($Configure)`n`nThis can take up to 60 minutes to complete." 
    Update-Slack -Message $SlackMessage -Slack $($JSON.SlackConfig.Slack)

    # Start Foundation Job
    $FoundationData = & ansible-playbook $PlaybookToRun --extra-vars="foundation_ip=$($JSON.Cluster.FvmIP) nos_package_name=$($NOSVersion)"

    # Validate Completion
    $Complete = $false
    foreach($Line in $FoundationData){
        if($Line -like "*""failed"": false*"){
                $Complete = $true
                break
        }
    }

    # Update Slack
    if($Complete){
        $SlackMessage = "EUC Cluster Foundation completed by $($GitHub.UserName)`n`nCluster Name: $($ClusterName)" 
    } else {
        $SlackMessage = "EUC Cluster Foundation Errored`n`n Started by $($GitHub.UserName)`nCluster Name: $($ClusterName)`nCheck http://$($JSON.Cluster.FvmIP):8000 for more details."
    }
    Update-Slack -Message $SlackMessage -Slack $($JSON.SlackConfig.Slack)

    # Configure the cluster if requested
    if($Configure) {
        $SlackMessage = "EUC Cluster $($ClusterName) Post Nutanix Foundation Configuration Requested by $($GitHub.UserName)" 
        Update-Slack -Message $SlackMessage -Slack $($JSON.SlackConfig.Slack)

        & $ScriptRoot\New-ClusterConfig.ps1 -WithRegistration -Silent -ContainerDriven
    } else {
        $SlackMessage = "EUC Cluster $($ClusterName) Configuration Skipped by $($GitHub.UserName)" 
        Update-Slack -Message $SlackMessage -Slack $($JSON.SlackConfig.Slack)
    }

    # Exit Success
    Exit 0
}

#endregion Foundation
