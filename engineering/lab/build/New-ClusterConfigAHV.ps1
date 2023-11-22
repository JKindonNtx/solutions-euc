<#
.SYNOPSIS
    This Script will configure a new Cluster with the default values ready for the performance testing to be done
.DESCRIPTION
    This Script will configure a new Cluster with the default values ready for the performance testing to be done
    First it will check for and add a VLAN if its not available
    Second it will check for and add a storage container is it does not exist
    Finally it will check for and upload a Build ISO for MDT is its not available
.NOTES
    There are 2 regions in this script - the details of the regions are:
        - Functions and Variables - this region gathers environment info for the build
        - Configuration - this region configures the cluster ready for use
#>

# Region Functions and Variables
# ====================================================================================================================================================
# Import the Functions and set the Variables used throughout the remainder of the script
# ====================================================================================================================================================

# Define the Variables for the script
If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }
$functions = get-childitem -Path "$($ScriptRoot)\functions\*.psm1"
$JSONFile = "$($ScriptRoot)\LabConfig.json"

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

# Write out a "SNAZZY" header
Write-Host "
   ____ _           _               ____             __ _            _    _   ___     __
  / ___| |_   _ ___| |_ ___ _ __   / ___|___  _ __  / _(_) __ _     / \  | | | \ \   / /
 | |   | | | | / __| __/ _ \ '__| | |   / _ \| '_ \| |_| |/ _` |   / _ \ | |_| |\ \ / / 
 | |___| | |_| \__ \ ||  __/ |    | |__| (_) | | | |  _| | (_| |  / ___ \|  _  | \ V /  
  \____|_|\__,_|___/\__\___|_|     \____\___/|_| |_|_| |_|\__, | /_/   \_\_| |_|  \_/   
                                                          |___/                                                                                                                                                                                                            
"

# Display the selected options selected back to the user
Write-Host "
--------------------------------------------------------------------------------------------------------"
Write-Host "Cluster IP:             $($JSON.Cluster.IP)"
Write-Host "Cluster user:           $($github.username)"
Write-Host "VLAN:                   $($JSON.VM.VLAN)"
Write-Host "VLAN Name:              $VLANName"
Write-Host "Container Name:         $($JSON.VM.Container)"
Write-Host "ISO Image:              $($JSON.VM.ISO)"
Write-Host "ISO Url:                $($JSON.VM.ISOUrl)"
Write-Host "Create Hosting:         True"
Write-Host "
--------------------------------------------------------------------------------------------------------"

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion



# Region Configuration
# ====================================================================================================================================================
# Configure the Nutanix Cluster ready for use
# ====================================================================================================================================================

# Check if admin is used as user.
if ($($github.username).ToLower() -eq 'admin') { 
    Write-Host (Get-Date) ":Don't use the admin account, enter different user in the config file, user will be created."
    Write-Host (Get-Date) ":Quitting"
    exit 
}

# Ask for confirmation to start the build - if no the quit
Do { $confirmationStart = Read-Host "Ready to configure the cluster? [y/n]" } Until (($confirmationStart -eq "y") -or ($confirmationStart -eq "n"))

if ($confirmationStart -eq 'n') { 
    Write-Host (Get-Date) ":Confirmation denied, quitting"
    exit 
} else {
    # Start configuration of the Nutanix Cluster
    $SendToSlack = "n"
    $SlackMessage = ""
    
    #Remove existing SSH keys.
    if (((Get-Module -ListAvailable *) | Where-Object {$_.Name -eq "Posh-SSH"})) {
        Get-SSHTrustedHost | Remove-SSHTrustedHost
    }
    
    # Add new local user to the cluster and disable admin account
    $Result = New-NutanixLocalUser -ClusterIP $($JSON.Cluster.IP) -CVMsshpassword $($JSON.Cluster.CVMsshpassword) -LocalUser $($github.username) -LocalPassword $($JSON.Cluster.password)
    if($Result -eq "added"){
        $SlackMessage = "New User Added: $($github.username)`n"
        $SendToSlack = "y"
    }
    
    # Check and Update the Network
    $VLANinfo = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "networks"
    $VLANUUID = ($VLANinfo.entities | Where-Object {$_.name -eq $VLANName}).uuid
    if([string]::IsNullOrEmpty($VLANUUID)){
        # VLAN not available
        Write-Host (Get-Date) ":VLAN not found, creating"
        $VLAN = New-NutanixVLAN -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -VLAN "$($JSON.VM.VLAN)" -VLANName "$VLANName"
        Start-Sleep 5
        $VLANinfo = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "networks"
        $VLANUUID = ($VLANinfo.entities | Where-Object {$_.name -eq $VLANName}).uuid
        if(!($null -eq $VLANUUID)) { Write-Host (Get-Date) ":VLAN Created" } else { Write-Host (Get-Date) ":Error Creating VLAN"; Exit}
        $SlackMessage = $SlackMessage + "VLAN Added: $VLANName`n"
        $SendToSlack = "y"
    } else {
        # VLAN is present on the cluster
        Write-Host (Get-Date) ":VLAN found"
    }

    # Check and Update the Storage Containers
    $Storageinfo = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "storage_containers"
    $StorageUUID = ($Storageinfo.entities | Where-Object {$_.name -eq $($JSON.VM.Container)}).storage_container_uuid
    if([string]::IsNullOrEmpty($StorageUUID)){
        # Storage Container not available
        Write-Host (Get-Date) ":Storage Container not found, creating"
        $Storage = New-NutanixStorageContainer -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -Container "$($JSON.VM.Container)"
        Start-Sleep 5
        $Storageinfo = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "storage_containers"
        $StorageUUID = ($Storageinfo.entities | Where-Object {$_.name -eq $($JSON.VM.Container)}).storage_container_uuid
        if(!($null -eq $StorageUUID)) { Write-Host (Get-Date) ":Storage Container Created" } else { Write-Host (Get-Date) ":Error Creating Storage Container"; Exit}
        $SlackMessage = $SlackMessage + "Storage Container Added: $($JSON.VM.Container)`n"
        $SendToSlack = "y"
    } else {
        # Storage Container is present on the cluster
        Write-Host (Get-Date) ":Storage Container found"
    }

    #Check and Update the ISO Image
    $ISOinfo = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "images"
    $ISOUUID = ($ISOinfo.entities | Where-Object {$_.name -eq $($JSON.VM.ISO)}).vm_disk_id
    if([string]::IsNullOrEmpty($ISOUUID)){
        # ISO file not available
        Write-Host (Get-Date) ":ISO file not found, uploading"
        $ISOURL = "$($JSON.VM.ISOUrl)" + "$($JSON.VM.ISO)"
        $ISOTask = New-NutanixISO -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -StorageUUID $StorageUUID -ISOurl "$ISOURL" -ISOname "$($JSON.VM.ISO)"

        # Wait for upload task to complete
        $ISOTaskUUID = $ISOTask.task_uuid
        Write-Host (Get-Date)":Wait for ISO Upload ($ISOTaskUUID) to finish" 
        Do {
            $ISOtaskinfo = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "tasks/$($ISOTaskUUID)"
            $ISOtaskstatus = $ISOtaskinfo.percentage_complete
            If ( $ISOtaskstatus -ne 100) {
                Start-Sleep -Seconds 5
            }
            Else {
                Write-Host (Get-Date)":Task is completed"
            }
        }
        Until ($ISOtaskstatus -eq 100)

        # Confirm that ISO is availavle
        $ISOinfo = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "images"
        $ISOUUID = ($ISOinfo.entities | Where-Object {$_.name -eq $($JSON.VM.ISO)}).vm_disk_id
        if(!($null -eq $ISOUUID)) { Write-Host (Get-Date) ":ISO Uploaded" } else { Write-Host (Get-Date) ":Error Uploading ISO"; Exit}
        $SlackMessage = $SlackMessage + "ISO Uploaded: $($JSON.VM.ISO)`n"
        $SendToSlack = "y"
    } else {
        # ISO file is present on the cluster
        Write-Host (Get-Date) ":ISO file found"
    }

    # Get Cluster Name and update Slack Message
    $Clusterinfo = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "cluster"
    $ClusterName = $Clusterinfo.name

    # Create Citrix Hosting Connection
    # Set-CitrixHostingConnection -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -VLAN "$($VLANName)" -DDC "$($JSON.Citrix.DDC)"
    # $SlackMessage = $SlackMessage + "Hosting Connection Created: $($ClusterName)`n"
    # $SendToSlack = "y"

    # Update Slack Channel
    if ($SendToSlack -eq "y") {
        $SlackMessage = "Nutanix Cluster $($ClusterName) Reconfigured by $($github.username) `n`n" + $SlackMessage
        Update-Slack -Message $SlackMessage -Slack $($JSON.SlackConfig.Slack)
    } else {
        Write-Host (Get-Date)":Skipped - Updating Slack Channel"
    }    

}

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion
