# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on March, 2019

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
     # Citrix CVAD Specs
    [Parameter(Mandatory = $true)]
    [Alias('CVAD Controller')] [string] $CVADController,                                       # Name of the Citrix Delivery Controller
    [Parameter(Mandatory = $true)]
    [Alias('Hosting Connection Name')] [string] $ConnectionName,                               # Hosting Connection (Name must be unique.)
    [Parameter(Mandatory = $true)]
    [Alias('ResourceName')] [string] $VlanName,                                                # Name of the VLAN
    [Parameter(Mandatory = $true)]
    [Alias('Machine Catalog Name')] [string] $provSchemeName,                                  # Name of the machine catalog that will be created (Name must be unique.)
    [Parameter(Mandatory = $true)]
    [Alias('Domain Name')] [string] $domain,                                                   # Domain Name (Domain controller)
    [Parameter(Mandatory = $true)]
    [Alias('ID Pool')] [string] $idPoolName,                                                   # Name of the Identity pool that will be created (Name must be unique.)
    [Parameter(Mandatory = $true)]
    [Alias('AD Machine Account Naming Convention')] [string] $adAccountNameSpecification,      # AD machine account naming conventions
    [Parameter(Mandatory = $true)]
    [Alias('Allocation Type')] [string] $allocType,                                            # Machine allocation type : Random, Static
    [Parameter(Mandatory = $true)]
    [Alias('Persist Changes')] [string] $persistChanges,                                       # Persist Changes : Discard, OnLocal, OnPvd
    [Parameter(Mandatory = $true)]
    [Alias('Session Type')] [string] $sessionSupport,                                          # Session : SingleSession, MultipleSession
    [Parameter(Mandatory = $true)]
    [Alias('Machine Count')] [string] $machineCount,                                           # Number of machines to be created
    [Parameter(Mandatory = $true)]
    [Alias('Number of vCPUs')] [string] $vCPU,                                                 # Number of vCPUs
    [Parameter(Mandatory = $true)]
    [Alias('Cores per vCPU')] [string] $coresPerCPU,                                           # Cores per vCPU
    [Parameter(Mandatory = $true)]
    [Alias('RAM in MB per VM')] [string] $RAM,                                                 # RAM Size in MB
    [Parameter(Mandatory = $true)]
    [Alias('Container')] [string] $storage,                                                    # Name of the container
    [Parameter(Mandatory = $true)]
    [Alias('Base Image Snapshot Name')] [string] $baseImage                                    # Name of the base image
)

$nxPasswordSec = ConvertTo-SecureString $nxPassword -AsPlainText -Force # Converting the Nutanix Prism password to a secure string to connect to the cluster

# Adding PS cmdlets
$loadedsnapins = (Get-PSSnapin -Registered | Select-Object name).name
if (!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))) {
    Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}
 
if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue)) {
    write-log -message "Nutanix CMDlets are not loaded, aborting the script"
    break
}
 
# Connecting to the Nutanix Cluster
$nxServerObj = Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPasswordsec -AcceptInvalidSSLCerts | out-null
write-log -message "Connecting to the Nutanix Cluster $nxIP"
 
if ($null -eq (get-ntnxclusterinfo)) {
    write-log -message "Cluster connection isn't available, abborting the script"
    break
}

# Setting parameters for Machine Catalog properties
$nxPasswordSec = ConvertTo-SecureString $nxPassword -AsPlainText -Force # Converting the Nutanix Prism password to a secure string to connect to the cluster
$network = $VlanName                                                    # Reusing the name of the network 
$hostingUnitName = $VlanName                                            # Reusing the VLAN Name as ResourceName to avoid multiple connections with the same resource definition$adContainerDN = "OU=VSI-test,OU=Computers,OU=CORP,DC=contoso,DC=local" # Setting the OU for the desktops
# Grabbing the containerID from the parameter Container
$ContainerInfo = Get-NTNXContainer | Where-Object {$_.name -eq $storage}
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

$hypRootPath = "xdhyp:\Connections\"+$hypConnName+"\"$baseImagePath = "xdhyp:\HostingUnits\" + $hostingUnitName +"\"+ $baseImage+".template"$networkPath1 = $hypRootPath+$network+".network"$networkMap = @{ "0" = "XDHyp:\HostingUnits\" + $hostingUnitName +"\"+ $network+".network" }$storagePath = $hypRootPath+$storage+".storage"

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
  if ($sev -eq "INFO"){
  write-host "$(get-date -format "hh:mm:ss") | INFO | $message"
  } elseif ($sev -eq "WARN"){
  write-host "$(get-date -format "hh:mm:ss") | WARN | $message"
  } elseif ($sev -eq "ERROR"){
  write-host "$(get-date -format "hh:mm:ss") | ERROR | $message"
  } elseif ($sev -eq "CHAPTER"){
  write-host "`n`n### $message`n`n"
  }
} 

# Adding PS cmdlets for Citrix
$loadedsnapins=(Get-PSSnapin -Registered | Select-Object name).name
if(!($loadedsnapins.Contains("Citrix"))){
 Add-PSSnapin -Name Citrix* 
 write-log -message "Citrix cmdlets are loaded, commencing the script"
}

if ($null -eq (Get-PSSnapin -Name Citrix* -ErrorAction SilentlyContinue))
{
  write-log -message "Citrix cmdlets are not loaded, aborting the script"
  break
}

# Setting up the hosting connection

$ExistinghostingConnection = Test-Path -EA Stop -Path @("XDHyp:\Connections\$ConnectionName") -AdminAddress $CVADController
write-log -message "Checking if the hosting connection already exists"

if ($ExistinghostingConnection -eq $False){
                                           $Connectionuid = New-Item -ConnectionType "Custom" -CustomProperties "" -HypervisorAddress @("$nxIP") -Path @("XDHyp:\Connections\$ConnectionName") -PluginId "AcropolisFactory" -Scope @() -SecurePassword $nxPasswordSec -UserName $nxUser -persist | select HypervisorConnectionUid
                                           New-BrokerHypervisorConnection -AdminAddress $CVADController -HypHypervisorConnectionUid $connectionuid.HypervisorConnectionUid | Out-Null
                                           write-log -message "Creating the hosting connection $ConnectionName"

                                           # Create Resources 'NTNX-LAN'  

                                            Set-HypAdminConnection  -AdminAddress $CVADController

                                            $ExistinghostingResource = Test-Path -EA Stop -Path @("XDHyp:\HostingUnits\$VlanName") -AdminAddress $CVADController

                                            if ($ExistinghostingResource -eq $False){
                                                                                       New-Item -HypervisorConnectionName $ConnectionName -NetworkPath @("XDHyp:\Connections\$ConnectionName\VDI-LAN.network") -Path @("XDHyp:\HostingUnits\$VlanName") -PersonalvDiskStoragePath @() -RootPath "XDHyp:\Connections\$ConnectionName" -StoragePath @() | Out-Null
                                                                                       write-log -message "Creating the resources $VlanName for $ConnectionName"
                                                                                    }
                                            Else {
                                                    Write-log -message "This VLAN is already assigned as a resource to the hosting connection, terminating the script"
                                                    break
                                                    }
                                        }
Else {
        write-log -message "This hosting connection already exists"
        }
 
$hypHc = get-Item -Path xdhyp:\Connections\$ConnectionName 
# Create the AdIdentity Pool 
Try{
$adAccountPool = New-AcctIdentityPool -IdentityPoolName $idPoolName -NamingScheme $adAccountNameSpecification -NamingSchemeType Numeric -Domain $domain -OU $adContainerDN write-log -message "Creating the AD account pool" } Catch { write-log -message "Unable to create the AD account pool" break }
# Create the Provisioning Scheme
Try{
$provScheme = New-ProvScheme -ProvisioningSchemeName $provSchemeName -HostingUnitName $hostingUnitName -MasterImageVM $baseImagePath -IdentityPoolName $idPoolName -CleanOnBoot -NetworkMapping $networkMap -CustomProperties $provcustomProperties write-log -message "Creating the prov scheme"
 }
 Catch{
 write-log -message "Unable to create the prov scheme"
 break
 }

# Create the AD accounts and VMs
Try{
$adAccounts = New-AcctADAccount -IdentityPoolName $idPoolName -Count $machineCount
$vms = New-ProvVm -ProvisioningSchemeName $provSchemeName -ADAccountName $adAccounts.SuccessfulAccounts  write-log -message "Creating the AD accounts" } Catch {        write-log -message "Unable to create the AD accounts"        Break        }
# Integrate With Broker
$provScheme = Get-ProvScheme -ProvisioningSchemeName $provSchemeName
$bhc = get-BrokerHypervisorConnection -HypHypervisorConnectionUid $hypHc.HypervisorConnectionUid
# Wait for the broker’s hypervisor connection to be ready before trying to use it.
while (-not $bhc.IsReady)
{
    Start-Sleep –s 5
    $bhc = Get-BrokerHypervisorConnection -HypHypervisorConnectionUid $hypHc.HypervisorConnectionUid     write-log -message "Waiting for the hypervisor connection to be ready"
}
# Create a new Machine Catalog
Try{$bdc = New-BrokerCatalog -Name $provSchemeName -AllocationType $allocType -ProvisioningType MCS -ProvisioningSchemeId $provScheme.ProvisioningSchemeUid -PersistUserChanges $persistChanges -SessionSupport $sessionSupportwrite-log -message "Creating the broker catalog"}Catch{write-log -message "Unable to create the broker catalog"break}
# Clone the VMs and make sure they're available under the machine catalog
$machineCreatedCount = 0
foreach ($provVm in $vms.CreatedVirtualMachines)
{
    $bpm = New-BrokerMachine -CatalogUid $bdc.Uid -HypervisorConnectionUid $bhc.Uid -HostedMachineId $provVm.VMId -MachineName $provVm.AdAccountSid
    $machineCreatedCount++    
}
write-log -message "Creating $($machineCount) VMs"
if($machineCreatedCount -gt 0)
{
    write-log -message "Setup and Machine Catalog creation completed successfully"
}
