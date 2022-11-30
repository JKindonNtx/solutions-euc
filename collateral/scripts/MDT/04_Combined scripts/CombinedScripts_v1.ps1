# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on April, 2019

 
# Setting parameters for the connection
[CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = "None") ]
 
Param(
    # Nutanix cluster IP address
    [Parameter(Mandatory = $true)]
    [Alias('IP')] [string] $nxIP,   
    # Nutanix cluster username
    [Parameter(Mandatory = $true)]
    [Alias('User')] [string] $nxUser,
    # Nutanix cluster password
    [Parameter(Mandatory = $true)]
    [Alias('Password')] [String] $nxPassword,
    # Nutanix VM Specs
    [Parameter(Mandatory = $true)]
    [Alias('VM Name')] [string] $Name,
    [Parameter(Mandatory = $true)]
    [Alias('Number of vCPUs')] [string] $NumVcpus,
    [Parameter(Mandatory = $true)]
    [Alias('vRAM')] [string] $MemoryMB,
    [Parameter(Mandatory = $false)]
    [Alias('ISO')] [string] $ISOName,
    [Parameter(Mandatory = $true)]
    [Alias('VLAN')] [string] $VMNetwork,
    [Parameter(Mandatory = $true)]
    [Alias('TaskSequence')] [string] $TaskSequenceID,
    [Parameter(Mandatory = $true)]
    [Alias('Container')] [string] $Containername,
    # Citrix CVAD Specs
    [Parameter(Mandatory = $true)]
    [Alias('CVAD Controller')] [string] $CVADController, # Name of the Citrix Delivery Controller
    [Parameter(Mandatory = $true)]
    [Alias('Hosting Connection Name')] [string] $ConnectionName, # Hosting Connection (Name must be unique.)
    [Parameter(Mandatory = $true)]
    [Alias('Machine Catalog Name')] [string] $provSchemeName, # Name of the machine catalog that will be created (Name must be unique.)
    [Parameter(Mandatory = $true)]
    [Alias('Domain Name')] [string] $domain, # Domain Name (Domain controller)
    [Parameter(Mandatory = $true)]
    [Alias('ID Pool')] [string] $idPoolName, # Name of the Identity pool that will be created (Name must be unique.)
    [Parameter(Mandatory = $true)]
    [Alias('AD Machine Account Naming Convention')] [string] $adAccountNameSpecification, # AD machine account naming conventions
    [Parameter(Mandatory = $true)]
    [Alias('Allocation Type')] [string] $allocType, # Machine allocation type : Random, Static
    [Parameter(Mandatory = $true)]
    [Alias('Persist Changes')] [string] $persistChanges, # Persist Changes : Discard, OnLocal, OnPvd
    [Parameter(Mandatory = $true)]
    [Alias('Session Type')] [string] $sessionSupport, # Session : SingleSession, MultipleSession
    [Parameter(Mandatory = $true)]
    [Alias('Machine Count')] [string] $machineCount, # Number of machines to be created
    [Parameter(Mandatory = $true)]
    [Alias('Number of vCPUs MC')] [string] $vCPU, # Number of vCPUs
    [Parameter(Mandatory = $true)]
    [Alias('Cores per vCPU')] [string] $coresPerCPU, # Cores per vCPU
    [Parameter(Mandatory = $true)]
    [Alias('RAM in MB per VM')] [string] $RAM, # RAM Size in MB
    [Parameter(Mandatory = $true)]
    [Alias('Delivery Group Name')] [string] $DeliveryGroupName                                 # Name of the Delivery Group that will be created (Name must be unique.)
)

$nxPasswordSec = ConvertTo-SecureString $nxPassword -AsPlainText -Force # Converting the Nutanix Prism password to a secure string to connect to the cluster

#region Functions
Function write-log {
    <#
       .Synopsis
       Write logs for debugging purposes
       
       .Description
       This function writes logs based on the message including a time stamp for debugging purposes.
    #>
    param (
        $message,
        $sev = "INFO"
    )
    if ($sev -eq "INFO") {
        Write-Host "$(Get-Date -format "hh:mm:ss") | INFO | $message"
    }
    elseif ($sev -eq "WARN") {
        Write-Host "$(Get-Date -format "hh:mm:ss") | WARN | $message"
    }
    elseif ($sev -eq "ERROR") {
        Write-Host "$(Get-Date -format "hh:mm:ss") | ERROR | $message"
    }
    elseif ($sev -eq "CHAPTER") {
        Write-Host "`n`n### $message`n`n"
    }
} 

#endregion Functions 

#region Requirements 
# Adding PS cmdlets for Nutanix
$loadedsnapins = (Get-PSSnapin -Registered | Select-Object name).name
if (!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))) {
    Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}
 
if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue)) {
    write-log -message "Nutanix CMDlets are not loaded, aborting the script"
    break
}

# Adding PS cmdlets for Citrix
$loadedsnapins = (Get-PSSnapin -Registered | Select-Object name).name
if (!($loadedsnapins.Contains("Citrix"))) {
    Add-PSSnapin -Name Citrix* 
    write-log -message "Citrix cmdlets are loaded, commencing the script"
}

if ($null -eq (Get-PSSnapin -Name Citrix* -ErrorAction SilentlyContinue)) {
    write-log -message "Citrix cmdlets are not loaded, aborting the script"
    break
}

# Importing MDT DB modules
Remove-Module 'MDTDB' -ErrorAction SilentlyContinue
$loadedmodules = (Get-Module | Select-Object name).name
if (!($loadedmodules.contains('MDTDB'))) {
    Import-Module .\MDTDB.psm1 -force
    write-log -message "Loading the MDT Powershell module"
}
else {
    write-log -message "Can't load the MDT Powershell module"
    Break
}

#endregion Requirements

#region Connectivity
 
# Connecting to the Nutanix Cluster
$nxServerObj = Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPasswordsec -AcceptInvalidSSLCerts | Out-Null
write-log -message "Connecting to the Nutanix Cluster $nxIP"
 
if ($null -eq (get-ntnxclusterinfo)) {
    write-log -message "Cluster connection isn't available, abborting the script"
    break
}

# Connecting to the MDT DB with current user logon
Try {
    Connect-MDTDatabase -sqlServer CONTMSQL001 -database MDTLoginvsi | Out-Null
    write-log -message "Connecting to the MDT Database"
}
Catch {
    write-log -message "Couldn't connect to the MDT Database"
}

#endregion Connectivity

#region VM Creation

#
#
# VM Creation Including snapshot - MDTBasedVM_v10
#
#

Try {
    # Creating the VM
    new-ntnxvirtualmachine -Name $Name -NumVcpus $NumVcpus -MemoryMB $MemoryMB | Out-Null
    write-log -message "Creating a VM with the name $name"
    Start-Sleep 10

    ## Network Settings
    # Get the VmID of the VM
    $vminfo = Get-NTNXVM | Where-Object { $_.vmName -eq $Name }
    $vmId = ($vminfo.vmid.split(":"))[2]
 
    # Set NIC for VM on vlan specified
    $nicuuid = Get-NTNXNetwork | Where-Object { $_.name -eq $VMNetwork }
    if ($Null -ne $nicuuid) {
        $nic = New-NTNXObject -Name VMNicSpecDTO
        $nic.networkUuid = $nicuuid.uuid
        $nic.isConnected = $True
            
        # Adding a Nic
        Add-NTNXVMNic -Vmid $vmId -SpecList $nic | Out-Null
        write-log -message "Adding a NIC to $Name"
 
        ## Disk Creation
        # Setting the SCSI disk of 50GB on the container specified 
        if ($Null -ne $ContainerName) {
            $Container = $ContainerName
        }
        $Containerid = Get-NTNXContainer | Where-Object { $_.name -eq $container }
        if ($Null -ne $Containerid) {
            $diskCreateSpec = New-NTNXObject -Name VmDiskSpecCreateDTO
            $diskcreatespec.containerid = ($Containerid.id.split(":"))[2]
            $diskcreatespec.sizeMb = 51200
 
            # Creating the Disk
            $vmDisk = New-NTNXObject –Name VMDiskDTO
            $vmDisk.vmDiskCreate = $diskCreateSpec
 
            # Adding the Disk to the VM
            Add-NTNXVMDisk -Vmid $vmId -Disks $vmDisk | Out-Null
            write-log -message "Adding a disk to $Name"
        }
        if ($Null -ne $ISOName) {
            $ISO = $ISOName
        }
        if ($Null -ne $ISO) {
            Try {
                # Mount ISO Image
                $diskCloneSpec = New-NTNXObject -Name VMDiskSpecCloneDTO
                $ISOImage = (Get-NTNXImage | Where-Object { $_.name -eq $ISO })
                $diskCloneSpec.vmDiskUuid = $ISOImage.vmDiskId
                #setup the new ISO disk from the Cloned Image
                $vmISODisk = New-NTNXObject -Name VMDiskDTO
                #specify that this is a Cdrom
                $vmISODisk.isCdrom = $true
                $vmISODisk.vmDiskClone = $diskCloneSpec

                # Adding the Disk to the VM
                Add-NTNXVMDisk -Vmid $vmId -Disks $vmISODisk | Out-Null
                write-log -message "ISO mounted to $Name"
            }
            Catch {
                write-log -message "No ISO was mounted to $Name"
            }
               
            # Booting the VM
            Set-NTNXVMPowerOn -Vmid $VMid | Out-Null
            Write-log -message "Starting $Name" 

            # Grabbing the MAC Address
            $VMNIC = Get-NTNXVMNIC -Vmid $VMid
            Write-log -message "Getting the VM Mac Address" 
               
            # Adding the VM to the MDT database
            # $TaskSequence = $TaskSequenceID
            New-MDTComputer -assettag $Name -macAddress $VMNIC.MacAddress.ToUpper() -settings @{SkipWizard = "YES"; TaskSequenceID = "$TaskSequenceID"; OSDComputerName = "$Name"; SkipComputerName = "YES"; SkipTaskSequence = "YES" }
            Write-log -message "Adding $Name to the MDT Database"
               
            # Preparing MDT phase, monitoring the DB to make sure the VM deployment is finished
            Start-Sleep 180
            Write-log -message "Waiting for the VM to PXE boot to the MDT share and start the task sequence"
            Import-Module C:\Temp\MicrosoftDeploymentToolkit.psd1
            Add-PSSnapin "Microsoft.BDD.PSSNAPIN" | Out-Null
            Write-log -message "Loading MDT Powershell cmdlets"

            #$target = "KBTestVM503"
            $deploymentShare = "\\CONTMAUT001\MDTLoginVSI$"

             
            If (!(Test-Path MDT:)) { New-PSDrive -Name MDT -Root $deploymentShare -PSProvider Microsoft.BDD.PSSNAPIN\MDTPROVIDER | Out-Null } 


            Get-MDTMonitorData -Path MDT: | Where-Object { $_.Name -eq $Name } | Out-Null
            Write-log -message "Getting MDT Monitoring Data"

            # Write-Host "Waiting for task sequence to complete."
            write-log -message 'Waiting for task sequence to complete'
            # If ((Test-Path variable:InProgress) -eq $True) { Remove-Variable -Name InProgress }
            Do {
                $InProgress = Get-MDTMonitorData -Path MDT: | Where-Object { $_.Name -eq $Name }
                If ( $InProgress.PercentComplete -lt 100 ) {
                    If ( $InProgress.StepName.Length -eq 0 ) { $StatusText = "Waiting for update" }
                    Start-Sleep -Seconds 5
                }
                Else {
                    Write-Progress -Activity "Task sequence complete" -PercentComplete 100
                }
            }
            Until ($InProgress.CurrentStep -eq $InProgress.TotalSteps)
            write-log -message 'Task Sequence completed'

            Start-Sleep 60

            # Creating VM snapshot

            $nxServerObj = Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPasswordsec -AcceptInvalidSSLCerts | Out-Null
            write-log -message "Reconnecting to the Nutanix Cluster $nxIP"

            $vminfo = Get-NTNXVM | Where-Object { $_.vmName -eq $Name }
            $vmId = ($vminfo.vmid.split(":"))[2]

            $VM = Get-NTNXVM | Where-Object { $_.vmName -eq $Name } | Where-Object { $_.powerState -eq 'Off' }
            $snaps = Get-NTNXVMSnapshot -Vmid $VMInfo.uuid
    
            $snap = new-ntnxobject -Name SnapshotSpecDTO
            $snap.vmuuid = $VMInfo.uuid
            $snap.snapshotname = "Ctx_MC_Snapshot"

            New-NTNXSnapshot -SnapshotSpecs $snap | Out-Null
            write-log -message 'Snapshot made from source VM'
            Start-Sleep 5
                
            If ($snaps.linklist.snapshotuuid.count -eq 1) {
                write-log -message 'This VM has one or more snapshots' 
                break
            }

        }
    }       
}
Catch {
    write-log -message "Something happened during VM Creation"
    Break
}

#endregion VM Creation

#region Hosting Connection and Machine Catalog Creation
#
#
# Creation of the hosting connection and the machine catalog
#
#


# Setting parameters for Machine Catalog properties

$network = $VlanName                                                    # Reusing the name of the network 
$hostingUnitName = $VlanName                                            # Reusing the VLAN Name as ResourceName to avoid multiple connections with the same resource definition
$adContainerDN = "OU=VSI-test,OU=Computers,OU=CORP,DC=contoso,DC=local" # Setting the OU for the desktops

# Grabbing the containerID from the parameter Container

$ContainerInfo = Get-NTNXContainer | Where-Object { $_.name -eq $Containername }
$ContainerId = ($Containerinfo.id.split(":"))[2]

# End of Global variables

$connectionCustomProperties = "<CustomProperties></CustomProperties>"
$hostingCustomProperties = "<CustomProperties></CustomProperties>"

$provcustomProperties = @"

<CustomProperties xmlns="http://schemas.citrix.com/2014/xd/machinecreation">

  <StringProperty Name="ContainerPath" Value="$containerID.container"/>

  <StringProperty Name="vCPU" Value="$vCPU"/>

  <StringProperty Name="RAM" Value="$RAM"/>

  <StringProperty Name="CPUCores" Value="$coresPerCPU"/>            

</CustomProperties>

"@

# Setting variables for the hosting connection(s)

$hypRootPath = "xdhyp:\Connections\" + $hypConnName + "\"
$baseImagePath = "xdhyp:\HostingUnits\" + $hostingUnitName + "\" + $snap.snapshotname + ".template"
$networkPath1 = $hypRootPath + $network + ".network"
$networkMap = @{ "0" = "XDHyp:\HostingUnits\" + $hostingUnitName + "\" + $network + ".network" }
$storagePath = $hypRootPath + $Containername + ".storage"

# Setting up the hosting connection

$ExistinghostingConnection = Test-Path -EA Stop -Path @("XDHyp:\Connections\$ConnectionName") -AdminAddress $CVADController
write-log -message "Checking if the hosting connection already exists"

if ($ExistinghostingConnection -eq $False) {
    $Connectionuid = New-Item -ConnectionType "Custom" -CustomProperties "" -HypervisorAddress @("$nxIP") -Path @("XDHyp:\Connections\$ConnectionName") -PluginId "AcropolisFactory" -Scope @() -SecurePassword $nxPasswordSec -UserName $nxUser -persist | Select-Object HypervisorConnectionUid
    New-BrokerHypervisorConnection -AdminAddress $CVADController -HypHypervisorConnectionUid $connectionuid.HypervisorConnectionUid | Out-Null
    write-log -message "Creating the hosting connection $ConnectionName"

    # Create Resources 'NTNX-LAN'  

    Set-HypAdminConnection  -AdminAddress $CVADController

    $ExistinghostingResource = Test-Path -EA Stop -Path @("XDHyp:\HostingUnits\ $VMNetwork") -AdminAddress $CVADController

    if ($ExistinghostingResource -eq $False) {
        New-Item -HypervisorConnectionName $ConnectionName -NetworkPath @("XDHyp:\Connections\$ConnectionName\VDI-LAN.network") -Path @("XDHyp:\HostingUnits\ $VMNetwork") -PersonalvDiskStoragePath @() -RootPath "XDHyp:\Connections\$ConnectionName" -StoragePath @() | Out-Null
        write-log -message "Creating the resources  $VMNetwork for $ConnectionName"
    }
    Else {
        Write-log -message "This VLAN is already assigned as a resource to the hosting connection, terminating the script"
        break
    }
}
Else {
    write-log -message "This hosting connection already exists"
}
 
$hypHc = Get-Item -Path xdhyp:\Connections\$ConnectionName 

# Check if the idPool already exists

$idPools = (Get-AcctADAccount | Select-Object IdentityPoolName).IdentityPoolName
if (!$idPools.Contains($($idPoolName))) { }     
else {
    write-log -message "The hosting unit $idPoolName already exists"
    Break
}

# Create the AdIdentity Pool 
Try {        
    $adAccountPool = New-AcctIdentityPool -IdentityPoolName $idPoolName -NamingScheme $adAccountNameSpecification -NamingSchemeType Numeric -Domain $domain -OU $adContainerDN
    write-log -message "Creating the AD account pool"
}
Catch {
    write-log -message "Unable to create the AD account pool"
    break
}


# Create the Provisioning Scheme

Try {
    $provScheme = New-ProvScheme -ProvisioningSchemeName $provSchemeName -HostingUnitName $hostingUnitName -MasterImageVM $baseImagePath -IdentityPoolName $idPoolName -CleanOnBoot -NetworkMapping $networkMap -CustomProperties $provcustomProperties
    write-log -message "Creating the prov scheme"
}
Catch {
    write-log -message "Unable to create the prov scheme"
    break
}


# Create the AD accounts and VMs

Try {
    $adAccounts = New-AcctADAccount -IdentityPoolName $idPoolName -Count $machineCount

    $vms = New-ProvVm -ProvisioningSchemeName $provSchemeName -ADAccountName $adAccounts.SuccessfulAccounts 
    write-log -message "Creating the AD accounts"
}
Catch {
    write-log -message "Unable to create the AD accounts"
    Break
}

# Integrate With Broker

$provScheme = Get-ProvScheme -ProvisioningSchemeName $provSchemeName
$bhc = Get-BrokerHypervisorConnection -HypHypervisorConnectionUid $hypHc.HypervisorConnectionUid

# Wait for the broker’s hypervisor connection to be ready before trying to use it.

while (-not $bhc.IsReady)
{

    Start-Sleep –s 5

    
    $bhc = Get-BrokerHypervisorConnection -HypHypervisorConnectionUid $hypHc.HypervisorConnectionUid -AdminAddress $CVADController
    write-log -message "Waiting for the hypervisor connection to be ready"

}

# Create a new Machine Catalog

Try {
    $bdc = New-BrokerCatalog -Name $provSchemeName -AllocationType $allocType -ProvisioningType MCS -ProvisioningSchemeId $provScheme.ProvisioningSchemeUid -PersistUserChanges $persistChanges -SessionSupport $sessionSupport
    write-log -message "Creating the broker catalog"
}
Catch {
    write-log -message "Unable to create the broker catalog"
    break
}

# Clone the VMs and make sure they're available under the machine catalog

$machineCreatedCount = 0

foreach ($provVm in $vms.CreatedVirtualMachines)
{

    $bpm = New-BrokerMachine -CatalogUid $bdc.Uid -HypervisorConnectionUid $bhc.Uid -HostedMachineId $provVm.VMId -MachineName $provVm.AdAccountSid

    $machineCreatedCount++
    

}

write-log -message "Creating $($machineCount) VMs"
if ($machineCreatedCount -gt 0)
{

    write-log -message "Setup and Machine Catalog creation completed successfully"

}

#endregion Hosting Connection and Machine Catalog Creation

#region Delivery Group Creation

$AvailableVMs = Get-BrokerMachine -AdminAddress $CVADController | Where-Object { $_.DesktopGroupName -eq $null }
write-log -message "Grabbing all available VMs"

New-BrokerDesktopGroup -AdminAddress $CVADController -ColorDepth "TwentyFourBit" -DeliveryType "DesktopsAndApps" -DesktopKind "Shared" -InMaintenanceMode $False -IsRemotePC $False -MinimumFunctionalLevel "L7_9" -Name $DeliveryGroupName -OffPeakBufferSizePercent 10 -OffPeakDisconnectAction "Nothing" -OffPeakDisconnectTimeout 0 -OffPeakExtendedDisconnectAction "Nothing" -OffPeakExtendedDisconnectTimeout 0 -OffPeakLogOffAction "Nothing" -OffPeakLogOffTimeout 0 -PeakBufferSizePercent 10 -PeakDisconnectAction "Nothing" -PeakDisconnectTimeout 0 -PeakExtendedDisconnectAction "Nothing" -PeakExtendedDisconnectTimeout 0 -PeakLogOffAction "Nothing" -PeakLogOffTimeout 0 -PublishedName "AHV - Windows - 10 - Delivery Group Name" -Scope @() -SecureIcaRequired $False -SessionSupport "SingleSession" -ShutdownDesktopsAfterUse $True -TimeZone "W. Europe Standard Time" | Out-Null
write-log -message "Creating the delivery group $DeliveryGroupName"

Foreach ($vm in $AvailableVMs) {
    Add-BrokerMachine -AdminAddress $CVADController -DesktopGroup $DeliveryGroupName -InputObject $vm.UID
}


write-log -message "Adding $($AvailableVMs.count) VMs to the Delivery Group $DeliveryGroupName"

$DesktopBrokerGroup = Get-BrokerDesktopGroup | Where-Object { $_.Name -eq $DeliveryGroupName }

# Setting up Access Policy rules for the Delivery group
New-BrokerAccessPolicyRule -AdminAddress $CVADController -AllowedConnections "NotViaAG" -AllowedProtocols @("HDX", "RDP") -AllowedUsers "AnyAuthenticated" -AllowRestart $True -DesktopGroupUid $DesktopBrokerGroup.Uid -Enabled $True -IncludedSmartAccessFilterEnabled $True -IncludedUserFilterEnabled $True -IncludedUsers @() -Name $DeliveryGroupName+"_Direct" | Out-Null
write-log -message "Creating Access Rule for connections NOT traversing Access Gateway"
New-BrokerAccessPolicyRule -AdminAddress $CVADController -AllowedConnections "ViaAG" -AllowedProtocols @("HDX", "RDP") -AllowedUsers "AnyAuthenticated" -AllowRestart $True -DesktopGroupUid $DesktopBrokerGroup.Uid -Enabled $True -IncludedSmartAccessFilterEnabled $True -IncludedSmartAccessTags @() -IncludedUserFilterEnabled $True -IncludedUsers @() -Name $DeliveryGroupName+"_AG" | Out-Null
write-log -message "Creating Access Rule for connections traversing Access Gateway"

# Testing if the access policy rules where created
Test-BrokerAccessPolicyRuleNameAvailable -AdminAddress $CVADController -Name @($DeliveryGroupName + "_Direct") | Out-Null
write-log -message "Testing Broker Access Policies for Direct connections"
Test-BrokerAccessPolicyRuleNameAvailable -AdminAddress $CVADController -Name @($DeliveryGroupName + "_AG") | Out-Null
write-log -message "Testing if the access rule for connections NOT traversing Access Gateway was created"

# Setting up Power schedules

# weekdays
Test-BrokerPowerTimeSchemeNameAvailable -AdminAddress $CVADController -Name @($DeliveryGroupName + "_Weekdays") | Out-Null
write-log -message "Testing if there's a power schedule available during weekdays"
New-BrokerPowerTimeScheme -AdminAddress $CVADController -DaysOfWeek "Weekdays" -DesktopGroupUid $DesktopBrokerGroup.Uid -DisplayName "Weekdays" -Name $DeliveryGroupName+"_Weekdays" -PeakHours @($True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True) -PoolSize @(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) | Out-Null
write-log -message "Creating a new power schedule during weekdays for the delivery group"

# weekends
Test-BrokerPowerTimeSchemeNameAvailable -AdminAddress $CVADController -Name @($DeliveryGroupName + "_Weekend") | Out-Null
write-log -message "Testing if there's a power schedule available during weekends"
New-BrokerPowerTimeScheme -AdminAddress $CVADController -DaysOfWeek "Weekend" -DesktopGroupUid $DesktopBrokerGroup.Uid -DisplayName "Weekend" -Name $DeliveryGroupName+"_Weekend" -PeakHours @($True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True, $True) -PoolSize @(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) | Out-Null
write-log -message "Creating a new power schedule during weekends for the delivery group"

#endregion Delivery Group Creation

#region closure of the script
write-log -message "Done creating the VM, Snapshot, Machine Catalog and the Delivery Group"
Disconnect-NTNXCluster *
write-log -message "Disconnecting from the cluster"
#endregion closure of the script