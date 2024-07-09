
<#
.SYNOPSIS
    This script sets up an Omnissa manual pool.

.DESCRIPTION
    The script imports the required modules, reads the configuration file, sets variables, deploys new VMs if necessary, creates or updates the Omnissa pool, and performs additional tasks.

.PARAMETER ConfigFile
    The path to the configuration file. Default value is "C:\Users\Dave\Documents\Github\solutions-euc\engineering\login-enterprise\ExampleConfig-Omnissa.jsonc".

.EXAMPLE
    Set-OmnissaManualPool.ps1 -ConfigFile "C:\Path\To\ConfigFile.jsonc"
#>

#region Params
Param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigFile = "C:\Users\Dave\Documents\Github\solutions-euc\engineering\login-enterprise\ExampleConfig-Omnissa.jsonc"
)
#endregion Params

#region Nutanix Module Import
If ([string]::IsNullOrEmpty($PSScriptRoot)) { 
    $ScriptRoot = $PWD.Path 
} else { 
    $ScriptRoot = $PSScriptRoot 
}

$var_ModuleName = "Nutanix.EUC"

Write-Host "$([char]0x1b)[96m[$([char]0x1b)[97m$(Get-Date)$([char]0x1b)[96m]$([char]0x1b)[97m INFO: Trying to import $var_ModuleName module"

try {
    Import-Module "$ScriptRoot\$var_ModuleName\$var_ModuleName.psd1" -Force -ErrorAction Stop
    Write-Log -Message "Successfully imported $var_ModuleName Module" -Level Info
}
catch {
    Write-Host "$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: Failed to import $var_ModuleName module. Exit script"
    Write-Host "$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: $_"
    Exit 1
}
#endregion Nutanix Module Import

#region Param Output
Write-Log -Message "Configuration File is:        $($ConfigFile)" -Level Validation
#endregion Param Output

#region PowerShell Versions
if ($PSVersionTable.PSVersion.Major -lt 5) { 
    Write-Log -Message "You must upgrade to PowerShell 5.x to run this script" -Level Warn
    Exit 1
}

if ($PSVersionTable.PSVersion.Major -lt 7 -and $Type -eq "RDP") {
    #No PowerShell 5.1 to be used. Use a container or use PS 7. 
    Write-Log -Message "You must use PowerShell 7 to run this script with RDP tests" -Level Warn
    Exit 1
}
#endregion PowerShell Versions

#region Config File
Write-Log -Message "Importing config file: $($ConfigFile)" -Level Info
try {
    $configFileData = Get-Content -Path $ConfigFile -ErrorAction Stop
}
catch {
    Write-Log -Message "Failed to import config file: $($configFile)" -Level Error
    Write-Log -Message $_ -Level Error
    Exit 1
}

$configFileData = $configFileData -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'

try {
    $config = $configFileData | ConvertFrom-Json -ErrorAction Stop
}
catch {
    Write-Log -Message $_ -Level Error
    Exit 1
}
#endregion Config File

#region Set Variables
$TargetCVM = $config.Nutanix.TargetCVM
$TargetCVMAdmin = $config.Nutanix.TargetCVMAdmin
$TargetCVMPassword = $config.Nutanix.TargetCVMPassword
$var_AD_User = $config.Microsoft.ADUserRegular
$var_AD_Admin = $Config.Microsoft.ADUserAdmin
$var_Admin_Password = $config.Microsoft.ADAdminPassword
$var_LDAPServer = $config.Microsoft.LDAPServer
$var_Base_DN = $config.Microsoft.BaseDN
$var_NetBios_Domain = $config.Microsoft.DomainNetBiosName
$var_Domain = $config.Microsoft.DomainDNSName
$var_OU = $config.Microsoft.TargetOU
$var_Api_Endpoint = $config.Omnissa.ConnectionServer
$var_UserName = $config.Omnissa.ConnectionServerUserName
$var_Password = $config.Omnissa.ConnectionServerPassword
$var_Omnissa_Pool_Name = $config.Omnissa.PoolName
$var_Naming_Convention = $config.Omnissa.NamingConvention
$var_Omnissa_Group = $config.Omnissa.EntitlementGroup
$var_Omnissa_Base_Vm_Name = $config.Omnissa.BaseVmName
$var_Number_Of_Vms = $config.Omnissa.NumberOfVMs
$Slack = $config.Various.Slack
$var_Ansible_Path = $config.Various.AnsiblePath
#endregion Set Variables

#region Build New VMs
$Filter = $var_Naming_Convention.Replace("#","")
[array]$CurrentVmsUnsorted = Get-ADComputers -filter $Filter -UserName "$($var_NetBios_Domain)\$var_AD_User" -Password $var_Admin_Password -LDAPServer $var_LDAPServer -BaseDN $var_Base_DN
[array]$CurrentVms = $CurrentVmsUnsorted | Sort-Object

if($null -eq $CurrentVmsUnsorted){
    $var_Start_Index = "1"
} else {
    $var_Start_Index = Get-NextComputerNumber -CurrentVMs $CurrentVMs -NamingConvention $var_Naming_Convention
}

Write-Log -Message "Updating Slack" -Level Info
$SlackMessage = "New AHV Omnissa Manual Pool Creation started by $TargetCVMAdmin on Cluster $($TargetCVM)."
Update-VSISlack -Message $SlackMessage -Slack $Slack

$ExistingPool = Get-OmnissaDesktopPools -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -PoolName $var_Omnissa_Pool_Name

$DeployVMs = $false

if ($ExistingPool -eq "NoPool") {
    Write-Log -Message "Desktop Pool $($var_Omnissa_Pool_Name) Does Not Exist" -Level Info
    $DeployVMs = $true
    $NumberInPool = $var_Number_Of_Vms
} else {
    Write-Log -Message "Desktop Pool $($var_Omnissa_Pool_Name) Already Exists" -Level Info
    $PoolMachines = Get-OmnissaMachines -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -Naming $Filter
    $PoolMachineCount = $PoolMachines | Measure-Object
    if ($PoolMachineCount.Count -ge $var_Number_Of_Vms) {
        Write-Log -Message "Already $($var_Number_Of_Vms) VMs available for deployment" -Level Info
        $DeployVMs = $false
        $NumberInPool = $var_Number_Of_Vms
    } else {
        Write-Log -Message "Desktop Pool $($var_Omnissa_Pool_Name) Has $($var_Number_Of_Vms) VMs" -Level Info
        $VMsToAdd = $var_Number_Of_Vms - $PoolMachineCount.Count
        Write-Log -Message "Deploying $($VMsToAdd) more VMs to $($var_Omnissa_Pool_Name)" -Level Info
        $NumberInPool = $var_Number_Of_Vms
        $var_Number_Of_Vms = $VMsToAdd
        $DeployVMs = $true
    }
}   

if ($DeployVMs -eq $true) {
    Write-Log -Message "VM Deployment Starting" -Level Info
    $var_Deployed_VMs = Set-OmnissaVMsAhv -BaseVM $var_Omnissa_Base_Vm_Name -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -NumberOfVMs $var_Number_Of_Vms -NamingConvention $var_Naming_Convention -StartIndex $var_Start_Index -Domain $var_Domain -AdminUserName $var_AD_Admin -AdminPassword $var_Admin_Password -OU $var_OU -RootPath $var_Ansible_Path
} else {
    Write-Log -Message "VM Deployment Skipped" -Level Info
}

$DeployedMachinesInPool = Get-OmnissaMachines -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -Naming $Filter
$DeployedMachinesSorted = $DeployedMachinesInPool | Sort-Object name
$DeployedMachineCount = $DeployedMachinesSorted | Measure-Object

$i = 1
foreach ($VM in $DeployedMachinesSorted) {
    Write-Log -Update -Message "Turning Off Machine $($i) of $($DeployedMachineCount.Count)." -Level Info
    $VmFqdn = $VM.name
    $VmSplit = $VmFqdn.Split(".")
    $VmNetbiosName = $VmSplit[0]
    $CurrentVM = Get-NTNXVMS -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword | where-object { $_.name -eq "$($VmNetbiosName)" }
    $var_Power_Result = Set-VmPower -VmUuid $CurrentVM.uuid -PowerState "OFF" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword
    $i++
}


Do {
    Write-Log -Update -Message "Waiting for machines to power off" -Level Info
    $VMsOn = (Get-NTNXVMS -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword | where-object { ($_.name -like "$($Filter)*") -and ($_.power_state -eq "on") } | measure-object).Count
    Start-Sleep -seconds 1
}
Until ($VMsOn -eq 0)
#endregion Build New VMs

#region Create Omnissa Pool
if ($ExistingPool -eq "NoPool") {
    $NewPool = $true
    $Pool = New-OmnissaManualPool -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -PoolName $var_Omnissa_Pool_Name
    $ExistingPool = Get-OmnissaDesktopPools -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -PoolName $var_Omnissa_Pool_Name
}

$machinesToRemove = @()
foreach ($machine in $DeployedMachinesSorted){
    $machinesToRemove += $machine.id
}

$machinesToRemovePayload = ConvertTo-Json @($machinesToRemove)
$RemovingMachines = Remove-OmnissaManualPoolMachines -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -PoolID $ExistingPool.id -Payload $machinesToRemovePayload

$machinesToAdd = @()
for ($i = 1; $i -le $NumberInPool; $i++) {
    $machinesToAdd += $DeployedMachinesSorted[$i - 1].id
}

$machinesToAddPayload = ConvertTo-Json @($machinesToAdd)
$addingMachines = Set-OmnissaManualPoolMachines -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -PoolID $ExistingPool.id -Payload $machinesToAddPayload

if ($NewPool -eq $true) {
    $OmnissaGroup = Get-OmnissaGroupSID -GroupName $var_Omnissa_Group -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain
    $Entitlement = Set-OmnissaManualPoolEntitlement -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -PoolID $ExistingPool.id -GroupID $OmnissaGroup.id
}
#endregion Create Omnissa Pool

#region Create Snapshot
$i = 1
foreach ($VM in $DeployedMachinesSorted) {
    $VmFqdn = $VM.name
    $VmSplit = $VmFqdn.Split(".")
    $VmNetbiosName = $VmSplit[0]
    $CurrentVM = Get-NTNXVMS -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword | where-object { $_.name -eq "$($VmNetbiosName)" }
    $Payload = "{ `
            ""snapshot_specs"":[ `
                {""snapshot_name"":""Omnissa_Default"", `
                ""vm_uuid"":""" + $CurrentVM.uuid + """ `
            }] `
        }"
    $CurrentSnap = Get-NTNXVmSnapshot -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -VMUUID $CurrentVM.uuid
    $Number = $CurrentSnap.entities | measure-object
    if($Number.Count -eq 0){
        Write-Log -Update -Message "Creating Snapshot (Omnissa_Default.shapshot) $($i) of $($DeployedMachineCount.Count)." -Level Info
        $Snap = Set-NTNXVmSnapshot -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -VMUUID $CurrentVM.uuid -Body $Payload
    } else {
        Write-Log -Update -Message "Skipping Snapshot $($i) of $($DeployedMachineCount.Count)." -Level Info
    }
    $i++
}
#endregion Create Snapshot

#region Power On
$PoolMachines = Get-OmnissaMachinesPool -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -PoolID $ExistingPool.id
$PoolMachineCount = $PoolMachines | Measure-Object
$i = 1
foreach ($VM in $PoolMachines) {
    Write-Log -Update -Message "Turning On Machine $($i) of $($PoolMachineCount.Count)." -Level Info
    $VmFqdn = $VM.name
    $VmSplit = $VmFqdn.Split(".")
    $VmNetbiosName = $VmSplit[0]
    $CurrentVM = Get-NTNXVMS -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword | where-object { $_.name -eq "$($VmNetbiosName)" }
    $var_Power_Result = Set-VmPower -VmUuid $CurrentVM.uuid -PowerState "ON" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword
    $i++
}


Do {
    Write-Log -Update -Message "Waiting for machines to power on" -Level Info
    $VMsOn = (Get-NTNXVMS -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword | where-object { ($_.name -like "$($Filter)*") -and ($_.power_state -eq "on") } | measure-object).Count
    Start-Sleep -seconds 1
}
Until ($VMsOn -eq $PoolMachineCount.Count)
#endregion Power On

#region Update Slack
#----------------------------------------------------------------------------------------------------------------------------

Write-Log -Message "Updating Slack" -Level Info
$SlackMessage = "AHV Omnissa Manual Pool Created`r
Pool Name: $($var_Omnissa_Pool_Name)`r
Number of VMs: $($var_Number_Of_Vms)`r
VM Naming Convention: $($var_Naming_Convention)"
Update-VSISlack -Message $SlackMessage -Slack $Slack
#endregion Update Slack



# Nice to have
# - Switch for Remove
#  - Get VMs - Omnissa
#  - Delete Pool - Omnissa
#  - Delete VMs - Omnissa
#  - Delete AD Computer Objects
#  - Shutdown VMs on AHV
#  - Delete VMs on AHV
# - Switch for Create

# Test with Windows 11 and unattend
# Test with Server 2022 Unattend