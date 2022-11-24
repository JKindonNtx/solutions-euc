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
    [Alias('CVAD Controller')] [string] $CVADController,
    [Parameter(Mandatory = $true)]
    [Alias('Hosting Connection Name')] [string] $ConnectionName,
    [Parameter(Mandatory = $true)]
    [Alias('ResourceName')] [string] $VlanName
)


#Machine Catalog properties
$nxPasswordSec = ConvertTo-SecureString $nxPassword -AsPlainText -Force

$provSchemeName = "Login VSI automated test"            #Name of the machine catalog that will be created (Name must be unique.)
$domain = "Contoso.local"              #Domain Name (Domain controller)
$idPoolName = "LoginVSI2"               #Name of the Identity pool that will be created (Name must be unique.)
$adAccountNameSpecification = "XDMS-###"     #AD machine account naming conventions
$allocType = "Random"                        #Machine allocation type : Random, Static
$persistChanges = "Discard"                  #Persist Changes : Discard, OnLocal, OnPvd
$sessionSupport = "SingleSession"            #Session : SingleSession, MultipleSession
$machineCount = 50                            #Number of machines to be created
$containerID = 1265                           #Container Id
$vCPU = 1                                    #Number of vCPUs
$RAM = 3072                                  #RAM Size in MB
$coresPerCPU = 2                             #Cores per vCPU$hostingUnitName = $VlanName $baseImage = "W10-1803-VirtIO1.1.4"            #Name of the base image
$network = $VlanName                       #Name of the network 
$storage = "VDI"                            #Name of the container$adContainerDN = "OU=VSI-test,OU=Computers,OU=CORP,DC=contoso,DC=local"

#************************** End of Global variables************************************************


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

$hypRootPath = "xdhyp:\Connections\"+$hypConnName+"\"
$baseImagePath = "xdhyp:\HostingUnits\" + $hostingUnitName +"\"+ $baseImage+".template"
$networkPath1 = $hypRootPath+$network+".network"
$networkMap = @{ "0" = "XDHyp:\HostingUnits\" + $hostingUnitName +"\"+ $network+".network" }
$storagePath = $hypRootPath+$storage+".storage"

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
# Connect to the Citrix VCAD Controller


# Setting up the hosting connection

$ExistinghostingConnection = Test-Path -EA Stop -Path @("XDHyp:\Connections\$ConnectionName") -AdminAddress $CVADController

if ($ExistinghostingConnection -eq $False){
                                           $Connectionuid = New-Item -ConnectionType "Custom" -CustomProperties "" -HypervisorAddress @("$nxIP") -Path @("XDHyp:\Connections\$ConnectionName") -PluginId "AcropolisFactory" -Scope @() -SecurePassword $nxPasswordSec -UserName $nxUser -persist | select HypervisorConnectionUid
                                           New-BrokerHypervisorConnection -AdminAddress $CVADController -HypHypervisorConnectionUid $connectionuid.HypervisorConnectionUid | Out-Null
                                           write-log -message "Creating the hosting connection $ConnectionName"
                                        }
Else {
        write-log -message "This hosting connection already exists"
        }

 
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

$hypHc = get-Item -Path xdhyp:\Connections\$ConnectionName 

# ------------------------------- Create the AdIdentity Pool -----------------------------------
$adAccountPool = New-AcctIdentityPool -IdentityPoolName $idPoolName -NamingScheme $adAccountNameSpecification -NamingSchemeType Numeric -Domain $domain -OU $adContainerDN write-log -message "Creating the AD account pool"
# ----------------------------- Create the Provisioning Scheme ---------------------------------

$provScheme = New-ProvScheme -ProvisioningSchemeName $provSchemeName -HostingUnitName $hostingUnitName -MasterImageVM $baseImagePath -IdentityPoolName $idPoolName -CleanOnBoot -NetworkMapping $networkMap -CustomProperties $provcustomProperties write-log -message "Creating the prov scheme"

# --------------------------------- Create the AD accounts and VMs ---------------------------------------------

$adAccounts = New-AcctADAccount -IdentityPoolName $idPoolName -Count $machineCount
$vms = New-ProvVm -ProvisioningSchemeName $provSchemeName -ADAccountName $adAccounts.SuccessfulAccounts  write-log -message "Creating the AD accounts"

# ------------------------------- Integrate With Broker ----------------------------------------

$provScheme = Get-ProvScheme -ProvisioningSchemeName $provSchemeName

# The broker has its own representation of the connection, but this is simple to create by just referencing the UID
# of the object in the hosting service.
$bhc = get-BrokerHypervisorConnection -HypHypervisorConnectionUid $hypHc.HypervisorConnectionUid

# Wait for the broker’s hypervisor connection to be ready before trying to use it.
while (-not $bhc.IsReady)
{
    Start-Sleep –s 5
    $bhc = Get-BrokerHypervisorConnection -HypHypervisorConnectionUid $hypHc.HypervisorConnectionUid     write-log -message "Waiting for the hypervisor connection to be ready"
}

# ------------------------------- Create Broker Catalog ----------------------------------------
$bdc = New-BrokerCatalog -Name $provSchemeName -AllocationType $allocType -ProvisioningType MCS -ProvisioningSchemeId $provScheme.ProvisioningSchemeUid -PersistUserChanges $persistChanges -SessionSupport $sessionSupport
 write-log -message "Creating the broker catalog"
# ------------------------------- Create Broker Machine ----------------------------------------
$machineCreatedCount = 0
foreach ($provVm in $vms.CreatedVirtualMachines)
{
    $bpm = New-BrokerMachine -CatalogUid $bdc.Uid -HypervisorConnectionUid $bhc.Uid -HostedMachineId $provVm.VMId -MachineName $provVm.AdAccountSid
    $machineCreatedCount++     write-log -message "Creating $($ProvVm.VMName)"
}
if($machineCreatedCount -gt 0)
{
    Write-Host "setup completed successfully."
}
