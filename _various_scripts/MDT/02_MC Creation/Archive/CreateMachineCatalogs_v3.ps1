
#*****************************************************************************
#CONSTANTS: No need to change these values.
#*****************************************************************************

$hypType = "Custom"                           #hypervisor connection type must currently be "Custom" for all plugins that use the provisioning SDK.
$pluginId = "AcropolisFactory"                #ID that Plugin currently publishes


#*****************************************************************************
#Global variables for entire script
#*****************************************************************************

#Connection properties

$hypConnName = "Acropolis11"                 #Name of the Hypervisor connection that will be created (Name must be unique.)
$hypAddress = "10.68.68.40"                  #Hypervisor/Cluster IP address
$hypUser = "admin"                           #Hypervisor UserName
$hypPassword = "Nutanix/4u$"                  #Hypervisor Password

#Hosting Resources

$hostingUnitName = "HostingUnit11"           #Name of the hosting unit that will be created (Name must be unique.)
$baseImage = "W10-1803-VirtIO1.1.4"            #Name of the base image
$network = "VDI-VLAN"                       #Name of the network 
$storage = "VDI"                            #Name of the container

#Machine Catalog properties

$provSchemeName = "VDI-Catalog11"            #Name of the machine catalog that will be created (Name must be unique.)
$domain = "Contoso.local"              #Domain Name (Domain controller)
$idPoolName = "IdentityPool11"               #Name of the Identity pool that will be created (Name must be unique.)
$adAccountNameSpecification = "XDMS-###"     #AD machine account naming conventions
$allocType = "Random"                        #Machine allocation type : Random, Static
$persistChanges = "Discard"                  #Persist Changes : Discard, OnLocal, OnPvd
$sessionSupport = "SingleSession"            #Session : SingleSession, MultipleSession
$machineCount = 2                            #Number of machines to be created
$containerID = 1265                           #Container Id
$vCPU = 3                                    #Number of vCPUs
$RAM = 3072                                  #RAM Size in MB
$coresPerCPU = 2                             #Cores per vCPU

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

$snapins = Get-PSSnapin | where { $_.Name -like "Citrix*" }
if ($snapins -eq $null)
{
    Write-Host "Loading the XenDesktop cmdlets into this session..."
    asnp citrix*
}
else
{
    Write-Host "XenDesktop cmdlets are already loaded into this session..."
}


$connNameAvailable = Test-HypHypervisorConnectionNameAvailable -HypervisorConnectionName $hypConnName
$hostUnitAvailable = Test-HypHostingUnitNameAvailable -HostingUnitName $hostingUnitName
$IdPoolNameAvailable = Test-AcctIdentityPoolNameAvailable -IdentityPoolName $idPoolName
$provSchemeNameAvailable = Test-ProvSchemeNameAvailable -ProvisioningSchemeName $provSchemeName

if($connNameAvailable.Available)
{
    if($hostUnitAvailable.Available)
    {
        if($IdPoolNameAvailable.Available)
        {
            if($provSchemeNameAvailable.Available)
            {
                Write-Host "Proceeding with setup.."
            }
            else
            {
                Write-Host "provisioning scheme Name already in use. Please enter unique name & start again."
                Exit
            }
        }
        else
        {
            Write-Host "ID pool Name already in use. Please enter unique name & start again."
            Exit          
        }

    }
    else
    {
        Write-Host "Hosting unit Name already in use. Please enter unique name & start again."
        Exit
    }
}
else
{
    Write-Host "Connection Name already in use. Please enter unique name & start again."
    Exit
}


$hypRootPath = "xdhyp:\Connections\"+$hypConnName+"\"
$baseImagePath = "xdhyp:\HostingUnits\" + $hostingUnitName +"\"+ $baseImage+".template"
$networkPath1 = $hypRootPath+$network+".network"
$networkMap = @{ "0" = "XDHyp:\HostingUnits\" + $hostingUnitName +"\"+ $network+".network" }
$storagePath = $hypRootPath+$storage+".storage"



Set-ProvServiceConfigurationData -Name ImageManagementPrep_DoImagePreparation -Value $true 
# ------------------------------ Create the HypervisorConnection -------------------------------
$hypHc = New-Item -Path xdhyp:\Connections -Name $hypConnName -HypervisorAddress $hypAddress -UserName $hypUser -Password $hypPassword -ConnectionType $hypType -PluginId $pluginId  -CustomProperties $connectionCustomProperties -Persist 
# --------------------------------- Create the HostingUnit -------------------------------------
$hypHu = New-Item -Path xdhyp:\HostingUnits -Name $hostingUnitName -HypervisorConnectionName $hypConnName -RootPath $hypRootPath -NetworkPath @($networkPath1)  -StoragePath $storagePath -CustomProperties $hostingCustomProperties

# ------------------------------- Create the AdIdentity Pool -----------------------------------
$adAccountPool = New-AcctIdentityPool -IdentityPoolName $idPoolName -NamingScheme $adAccountNameSpecification -NamingSchemeType Numeric -Domain $domain #-OU $adContainerDN
# ----------------------------- Create the Provisioning Scheme ---------------------------------

$provScheme = New-ProvScheme -ProvisioningSchemeName $provSchemeName -HostingUnitName $hostingUnitName -MasterImageVM $baseImagePath -IdentityPoolName $idPoolName -CleanOnBoot -NetworkMapping $networkMap -CustomProperties $provcustomProperties

# --------------------------------- Create the AD accounts and VMs ---------------------------------------------

$adAccounts = New-AcctADAccount -IdentityPoolName $idPoolName -Count $machineCount
$vms = New-ProvVm -ProvisioningSchemeName $provSchemeName -ADAccountName $adAccounts.SuccessfulAccounts 

# ------------------------------- Integrate With Broker ----------------------------------------

$provScheme = Get-ProvScheme -ProvisioningSchemeName $provSchemeName

# The broker has its own representation of the connection, but this is simple to create by just referencing the UID
# of the object in the hosting service.
$bhc = New-BrokerHypervisorConnection -HypHypervisorConnectionUid $hypHc.HypervisorConnectionUid

# Wait for the broker’s hypervisor connection to be ready before trying to use it.
while (-not $bhc.IsReady)
{
    Start-Sleep –s 5
    $bhc = Get-BrokerHypervisorConnection -HypHypervisorConnectionUid $hypHc.HypervisorConnectionUid
}

# ------------------------------- Create Broker Catalog ----------------------------------------
$bdc = New-BrokerCatalog -Name $provSchemeName -AllocationType $allocType -ProvisioningType MCS -ProvisioningSchemeId $provScheme.ProvisioningSchemeUid -PersistUserChanges $persistChanges -SessionSupport $sessionSupport

# ------------------------------- Create Broker Machine ----------------------------------------
$machineCreatedCount = 0
foreach ($provVm in $vms.CreatedVirtualMachines)
{
    $bpm = New-BrokerMachine -CatalogUid $bdc.Uid -HypervisorConnectionUid $bhc.Uid -HostedMachineId $provVm.VMId -MachineName $provVm.AdAccountSid
    $machineCreatedCount++
}
if($machineCreatedCount -gt 0)
{
    Write-Host "setup completed successfully."
}


