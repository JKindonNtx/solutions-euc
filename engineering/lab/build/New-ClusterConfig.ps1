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

[Parameter(Mandatory = $false)]
[switch]$WithRegistration

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
$Hypervisor = $($JSON.VM.Hypervisor)

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
    Write-Host "This script CANNOT be used on NC2 due to the limitations with CVM access"
    Write-Host "Please configure the cluster manually"
    exit 
} else {
    Clear-Host
}

# Write out a "SNAZZY" header
Write-Host "
   ____ _           _               ____             __ _           
  / ___| |_   _ ___| |_ ___ _ __   / ___|___  _ __  / _(_) __ _   
 | |   | | | | / __| __/ _ \ '__| | |   / _ \| '_ \| |_| |/ _` |  
 | |___| | |_| \__ \ ||  __/ |    | |__| (_) | | | |  _| | (_| |  
  \____|_|\__,_|___/\__\___|_|     \____\___/|_| |_|_| |_|\__, | 
                                                          |___/                                                                                                                                                                                                            
"

# Display the selected options selected back to the user
Write-Host "
--------------------------------------------------------------------------------------------------------"
Write-Host "Cluster IP:             $($JSON.Cluster.IP)"
Write-Host "Hypervisor:             $($JSON.VM.Hypervisor)"
Write-Host "Cluster user:           $($github.username)"
Write-Host "VLAN:                   $($JSON.VM.VLAN)"
Write-Host "VLAN Name:              $VLANName"
Write-Host "Container Name:         EUC-<CLUSTER_NAME>"
Write-Host "ISO Image:              $($JSON.VM.ISO)"
Write-Host "ISO Url:                $($JSON.VM.ISOUrl)"
Write-Host "Register to PC:         $($JSON.Cluster.PCIP)"
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
    
    # Build Cluster name and Storage Name
    $AOSCluster = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "cluster"
    $AOSClusterName = $AOSCluster.Name
    $AOSHosts = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "hosts"
    $StorageName = "EUC-$($AOSClusterName)"

    # Install PowerCLI and get Clusters if configuring a VMware Cluster
    if($JSON.VM.Hypervisor -eq "VMware"){
        Write-Host (Get-Date) ":Installing VMware PowerCli" 
        #$null = Install-Module VMware.PowerCLI -AllowClobber -Force
        Write-Host (Get-Date) ":Connecting to VMware vSphere" 
        $Connection = Connect-VIServer -Server $JSON.VMwareCluster.ip -Protocol https -User $JSON.VMwareCluster.user -Password $JSON.VMwareCluster.password -Force
        if($connection){
            Write-Host (Get-Date) ":Connected to vSphere"
        } else {
            Write-Host (Get-Date) ":Connection to vSphere Failed - quitting"
            break 
        }
    }

    # Remove and re-add Host and Cluster to vSphere if applicable
    if($JSON.VM.Hypervisor -eq "VMware"){
        if($WithRegistration){
            # Remove Hosts from vSphere
            foreach($AOSHost in $AOSHosts.entities){
                $HostIP = $AOSHost.hypervisor_address
                $CurrentHost = Get-VMHost -Name $HostIP -ErrorAction SilentlyContinue
                if(!([string]::IsNullOrEmpty($CurrentHost))){
                    Write-Host (Get-Date) ":Host $($HostIP) Exists" 
                    Write-Host (Get-Date) ":Disconnecting $($HostIP)" 
                    $task = Set-VMHost -VMHost $HostIP -State "Disconnected" -Confirm:$false
                    Write-Host (Get-Date) ":Removing $($HostIP)" 
                    $task = Remove-VMHost -VMHost $HostIP -Confirm:$false
                    Write-Host (Get-Date) ":Host $($HostIP) Removed" 
                } else {
                    Write-Host (Get-Date) ":Host $($HostIP) not present in vSphere" 
                }
            }

            # Remove Cluster from vSphere
            $ClusterExists = Get-Cluster -Name $AOSClusterName -ErrorAction SilentlyContinue
            if(!([string]::IsNullOrEmpty($ClusterExists))){
                Write-Host (Get-Date) ":Cluster $($AOSClusterName) exists, removing hosts"
                $ClusterExists  | Get-VMHost | ForEach-Object {
                    Write-Host (Get-Date) ":Disconnecting $($_.Name)" 
                    $task = Set-VMHost $_ -State "Disconnected" -Confirm:$false
                    Write-Host (Get-Date) ":Removing $($_.Name)" 
                    $task = Remove-VMHost -VMHost $_ -Confirm:$false
                    Write-Host (Get-Date) ":Host $($_.Name) Removed" 
                }
                Write-Host (Get-Date) ":Removing $($AOSClusterName)"
                $ClusterExists | Remove-Cluster -Confirm:$false
                Write-Host (Get-Date) ":Cluster $($AOSClusterName) Removed"
            } else {
                Write-Host (Get-Date) ":Cluster $($AOSClusterName) not present in vSphere" 
            }

            # Create the new Cluster
            Write-Host (Get-Date) ":Creating $($AOSClusterName)"
            $task = New-Cluster -Name $($AOSClusterName) -Location "EUC-Solutions"

            # Add the hosts to the cluster
            $i = 1
            foreach($AOSHost in $AOSHosts.entities){
                $HostIP = $AOSHost.hypervisor_address
                Write-Host (Get-Date) ":Adding $($HostIP) to vSphere"
                $task = Add-VMHost -Server $JSON.VMwareCluster.ip -Name $HostIP -Location "EUC-Solutions" -User "root" -Password $JSON.Cluster.CVMsshpassword -Force -Confirm:$false
                if($i -eq 1){
                    $MasterHost = $HostIP
                    $i++
                }
                Write-Host (Get-Date) ":Adding NTP Server to $($HostIP)"
                $task = Get-VMHost -Name $HostIP | Add-VMHostNtpServer -ntpserver "10.56.1.177" -ErrorAction SilentlyContinue
                $task = Get-VMHost -Name $HostIP | Get-VMHostFirewallException | where {$_.name -eq "NTP client"} | Set-VMHostFirewallException -enabled $true -ErrorAction SilentlyContinue
                $task = Get-VMHost -Name $HostIP | Get-VMHostService | where {$_.key -eq "ntpd"} | Start-VMHostService -ErrorAction SilentlyContinue
                Write-Host (Get-Date) ":Setting High Performance Power Plan for $($HostIP)"
                $task = (Get-View (Get-VMHost -Name $HostIP | Get-View).ConfigManager.PowerSystem).ConfigurePowerPolicy(1)
                Write-Host (Get-Date) ":Adding VLAN $($VLANName) to $($HostIP)"
                $task = Get-VMHost -Name $HostIP | Get-VirtualSwitch -name "vSwitch0" | New-VirtualPortGroup -Name $VLANName -VLanId $JSON.VM.VLAN -ErrorAction SilentlyContinue
            }
        
            Write-Host (Get-Date) ":Moving $($MasterHost) to Cluster $($AOSClusterName)"
            $task = Move-VMHost -VMHost $MasterHost -Destination $AOSClusterName
            $SlackMessage = $SlackMessage + "VMware Cluster Created: $AOSClusterName`n"
            $SlackMessage = $SlackMessage + "VLAN Added: $VLANName`n"
            $SlackMessage = $SlackMessage + "VMware NTP and Power Options Set`n"
            $SendToSlack = "y"
        } else {
            $SlackMessage = $SlackMessage + "Skipped VMware Cluster Creation`n"
            $SendToSlack = "y"
        }
    }

    # Check and Update the Network
    if($JSON.VM.Hypervisor -eq "AHV"){
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
    }

    # Check and Update the Storage Containers
    $Storageinfo = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "storage_containers"
    $StorageUUID = ($Storageinfo.entities | Where-Object {$_.name -eq $($StorageName)}).storage_container_uuid
    if([string]::IsNullOrEmpty($StorageUUID)){
        # Storage Container not available
        Write-Host (Get-Date) ":Storage Container not found, creating"
        $Storage = New-NutanixStorageContainer -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -Container "$($StorageName)"
        Start-Sleep 5
        $Storageinfo = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIpath "storage_containers"
        $StorageUUID = ($Storageinfo.entities | Where-Object {$_.name -eq $($StorageName)}).storage_container_uuid
        if(!($null -eq $StorageUUID)) { Write-Host (Get-Date) ":Storage Container Created" } else { Write-Host (Get-Date) ":Error Creating Storage Container"; Exit}
        $SlackMessage = $SlackMessage + "Storage Container Added: $($StorageName)`n"
        $SendToSlack = "y"
    } else {
        # Storage Container is present on the cluster
        Write-Host (Get-Date) ":Storage Container found"
        $DSFound = $true
    }

    # Mount Storage Container to vSphere
    if($JSON.VM.Hypervisor -eq "VMware"){
        if(!($DSFound)){
            $ESXi = New-ESXiDatastore -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -Container "$($StorageName)"
            $SlackMessage = "Storage Container $($StorageName) mounted to ESXi`n"
            $SendToSlack = "y"
            Write-Host (Get-Date) ":Pausing for 30 seconds to let mount operation complete"
            start-sleep -Seconds 30
        }
    }

    #Check and Update the ISO Image
    if($JSON.VM.Hypervisor -eq "VMware"){
        if($WithRegistration){
            Write-Host (Get-Date) ":Getting Datastore $($StorageName)"
            $DS = Get-Datastore -Name $StorageName
            Write-Host (Get-Date) ":Creating ISO Directory"
            $task = New-Item -Path $DS.DatastoreBrowserPath -Name "ISO" -ItemType Directory -ErrorAction SilentlyContinue
            Write-Host (Get-Date) ":Downloading $($JSON.VM.ISO) - This will take some time"
            $ISOURL = "$($JSON.VM.ISOUrl)" + "$($JSON.VM.ISO)"
            $ProgressPreference = 'SilentlyContinue'
            $task = invoke-webrequest -Uri $ISOURL -outfile "$($JSON.VM.ISO)" 
            $Source = Join-Path -Path $ScriptRoot -ChildPath $JSON.VM.ISO
            $Destination = Join-Path -Path $DS.DatastoreBrowserPath -ChildPath "ISO\"
            Write-Host (Get-Date) ":Copying $($JSON.VM.ISO) to Datastore - This will take some time"
            $task = Copy-DatastoreItem -Item $Source -Destination $Destination -Force
            $SlackMessage = $SlackMessage + "ISO Uploaded: $($JSON.VM.ISO)`n"
            $SendToSlack = "y"
            remove-item -Path $Source -Force -ErrorAction SilentlyContinue
        } else {
            $SlackMessage = $SlackMessage + "Skipped VMware ISO Image Upload`n"
            $SendToSlack = "y"
        }
    } else {
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
    }

    # Get Cluster Name and update Slack Message
    $Clusterinfo = Invoke-NutanixAPI -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -APIPath "cluster"
    $ClusterName = $Clusterinfo.name

    # Create Citrix Hosting Connection
    if($JSON.VM.Hypervisor -eq "VMware"){
        if($WithRegistration){
            Set-CitrixHostingConnectionESXi -VLAN "$($VLANName)" -DDC "$($JSON.Citrix.DDC)" -ClusterName $ClusterName
            $SlackMessage = $SlackMessage + "VMware Hosting Connection Created: $($ClusterName)`n"
            $SendToSlack = "y"
        } else {
            $SlackMessage = $SlackMessage + "Skipped Citrix Hosting Connection Creation`n"
            $SendToSlack = "y"
        }
    } else {
        Set-CitrixHostingConnection -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($github.username)" -VLAN "$($VLANName)" -DDC "$($JSON.Citrix.DDC)"
        $SlackMessage = $SlackMessage + "Hosting Connection Created: $($ClusterName)`n"
        $SendToSlack = "y"
    }

    # Register Cluster with Prism Central
    if($WithRegistration){
        Remove-PrismCentral -PCIP "$($JSON.Cluster.PCIP)" -PCPassword "$($JSON.Cluster.PCPassword)" -ClusterName $ClusterName
        Set-PrismCentral -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.CVMsshpassword)" -PCIP "$($JSON.Cluster.PCIP)" -PCPassword "$($JSON.Cluster.PCPassword)"
        $SlackMessage = $SlackMessage + "$($ClusterName) registered with Prism Central $($PCIP)`n"
        $SendToSlack = "y"
    } else {
        $SlackMessage = $SlackMessage + "Skipped Prism Central Registration`n"
        $SendToSlack = "y"
    }

    # Update Slack Channel
    if ($SendToSlack -eq "y") {
        $SlackMessage = "$($Hypervisor) Cluster $($ClusterName) Reconfigured by $($github.username) `n`n" + $SlackMessage
        Update-Slack -Message $SlackMessage -Slack $($JSON.SlackConfig.Slack)
    } else {
        Write-Host (Get-Date)":Skipped - Updating Slack Channel"
    }    

}

#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion
