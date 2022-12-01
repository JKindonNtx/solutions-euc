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
$functions = get-childitem -Path "/workspaces/solutions-euc/engineering/lab/build/functions/*.psm1"
$JSONFile = "/workspaces/solutions-euc/engineering/lab/build/ConfigureClusterAHV.json"

# Import all the functions required
foreach($function in $functions){ Write-Host (Get-Date)":Importing - $function." ; import-module $function }

# Read the JSON input file into an object
if($null -eq ($JSON = (Read-JSON -JSONFile $JSONFile))){
    Write-Host (Get-Date) ":Unable to read JSON configuration file, quitting"
    Break 
} else {
    Write-Host (Get-Date) ":JSON configuration file loaded"
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
Write-Host "Cluster IP:             $($JSON.Cluster.IP)"
Write-Host "VLAN:                   $($JSON.Defaults.VLAN)"
Write-Host "VLAN Name:              $($JSON.Defaults.VLANName)"
Write-Host "Container Name:         $($JSON.Defaults.Container)"
Write-Host "ISO Image:              $($JSON.Defaults.ISO)"
Write-Host "ISO Url:                $($JSON.Defaults.ISOUrl)"
Write-Host "
--------------------------------------------------------------------------------------------------------"

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion



# Region Configuration
# ====================================================================================================================================================
# Configure the Nutanix Cluster ready for use
# ====================================================================================================================================================

# Ask for confirmation to start the build - if no the quit
Do { $confirmationStart = Read-Host "Ready to configure the cluster? [y/n]" } Until (($confirmationStart -eq "y") -or ($confirmationStart -eq "n"))

if ($confirmationStart -eq 'n') { 
    Write-Host (Get-Date) ":Confirmation denied, quitting"
    exit 
} else {
    # Start configuration of the Nutanix Cluster
    $SendToSlack = "n"
    $SlackMessage = ""

    # Add new local user to the cluster and disable admin account
    New-NutanixLocalUser -ClusterIP $($JSON.Cluster.IP) -CVMsshpassword $($JSON.Cluster.CVMsshpassword) -username $($JSON.Cluster.username) -userpassword $($JSON.Cluster.password)
    # Check and Update the Network
    $VLANinfo = Get-NutanixV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIpath "networks"
    $VLANUUID = ($VLANinfo.entities | Where-Object {$_.name -eq $($JSON.Defaults.VLANName)}).uuid
    if($null -eq $VLANUUID){
        # VLAN not available
        Write-Host (Get-Date) ":VLAN not found, creating"
        New-NutanixVlanV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -VLAN "$($JSON.Defaults.VLAN)" -VLANName "$($JSON.Defaults.VLANName)"
        Start-Sleep 5
        $VLANinfo = Get-NutanixV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIpath "networks"
        $VLANUUID = ($VLANinfo.entities | Where-Object {$_.name -eq $($JSON.Defaults.VLANName)}).uuid
        if(!($null -eq $VLANUUID)) { Write-Host (Get-Date) ":VLAN Created" } else { Write-Host (Get-Date) ":Error Creating VLAN"; Exit}
        $SlackMessage = "VLAN Added: $($JSON.Defaults.VLANName)`n"
        $SendToSlack = "y"
    } else {
        # VLAN is present on the cluster
        Write-Host (Get-Date) ":VLAN found"
    }

    # Check and Update the Storage Containers
    $Storageinfo = Get-NutanixV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIpath "storage_containers"
    $StorageUUID = ($Storageinfo.entities | Where-Object {$_.name -eq $($JSON.Defaults.Container)}).storage_container_uuid
    if($null -eq $StorageUUID){
        # Storage Container not available
        Write-Host (Get-Date) ":Storage Container not found, creating"
        New-NutanixStorageV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -Container "$($JSON.Defaults.Container)"
        Start-Sleep 5
        $Storageinfo = Get-NutanixV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIpath "storage_containers"
        $StorageUUID = ($Storageinfo.entities | Where-Object {$_.name -eq $($JSON.Defaults.Container)}).storage_container_uuid
        if(!($null -eq $StorageUUID)) { Write-Host (Get-Date) ":Storage Container Created" } else { Write-Host (Get-Date) ":Error Creating Storage Container"; Exit}
        $SlackMessage = $SlackMessage + "Storage Container Added: $($JSON.Defaults.Container)`n"
        $SendToSlack = "y"
    } else {
        # Storage Container is present on the cluster
        Write-Host (Get-Date) ":Storage Container found"
    }

    #Check and Update the ISO Image
    $ISOinfo = Get-NutanixV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIpath "images"
    $ISOUUID = ($ISOinfo.entities | Where-Object {$_.name -eq $($JSON.Defaults.ISO)}).vm_disk_id
    if($null -eq $ISOUUID){
        # ISO file not available
        Write-Host (Get-Date) ":ISO file not found, uploading"
        $ISOTask = New-NutanixIsoV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -StorageUUID $StorageUUID -ISOurl "$($JSON.Defaults.ISOUrl)" -ISOname "$($JSON.Defaults.ISO)"

        # Wait for upload task to complete
        $ISOTaskUUID = $ISOTask.task_uuid
        Write-Host (Get-Date)":Wait for ISO Upload ($ISOTaskUUID) to finish" 
        Do {
            $ISOtaskinfo = Get-NutanixV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIPath "tasks/$($ISOTaskUUID)"
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
        $ISOinfo = Get-NutanixV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIpath "images"
        $ISOUUID = ($ISOinfo.entities | Where-Object {$_.name -eq $($JSON.Defaults.ISO)}).vm_disk_id
        if(!($null -eq $ISOUUID)) { Write-Host (Get-Date) ":ISO Uploaded" } else { Write-Host (Get-Date) ":Error Uploading ISO"; Exit}
        $SlackMessage = $SlackMessage + "ISO Uploaded: $($JSON.Defaults.ISO)`n"
        $SendToSlack = "y"
    } else {
        # ISO file is present on the cluster
        Write-Host (Get-Date) ":ISO file found"
    }

    # Update Slack Channel
    if ($SendToSlack -eq "y") {
        $SlackMessage = "Nutanix AHV Cluster Reconfiguration`n`n" + $SlackMessage
        Update-Slack -Message $SlackMessage -Slack $($JSON.SlackConfig.Slack)
    } else {
        Write-Host (Get-Date)":Skipped - Updating Slack Channel"
    }    

}

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion
