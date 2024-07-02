#region Params
# ============================================================================
# Parameters
# ============================================================================

Param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigFile = "C:\Users\Dave\Documents\Github\solutions-euc\engineering\login-enterprise\ExampleConfig-Omnissa.jsonc",
)
#endregion Params

#region Execute
# ============================================================================

#region Nutanix Module Import
#----------------------------------------------------------------------------------------------------------------------------
If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }
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
#----------------------------------------------------------------------------------------------------------------------------
Write-Log -Message "Configuration File is:        $($ConfigFile)" -Level Validation
#endregion Param Output

#region PowerShell Versions
#----------------------------------------------------------------------------------------------------------------------------
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
#----------------------------------------------------------------------------------------------------------------------------
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
#----------------------------------------------------------------------------------------------------------------------------

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
#----------------------------------------------------------------------------------------------------------------------------

$Filter = $var_Naming_Convention.Replace("#","")
$CurrentVmsUnsorted = Get-ADComputers -filter $Filter -UserName "$($var_NetBios_Domain)\$var_AD_User" -Password $var_Admin_Password -LDAPServer $var_LDAPServer -BaseDN $var_Base_DN
$CurrentVms = $CurrentVmsUnsorted | Sort-Object

if($null -eq $CurrentVmsUnsorted){
    $var_Start_Index = "1"
} else {
    $var_Start_Index = Get-NextComputerNumber -CurrentVMs $CurrentVMs -NamingConvention $var_Naming_Convention
}

Write-Log -Message "Updating Slack" -Level Info
$SlackMessage = "New AHV Omnissa Manual Pool Creation started by $TargetCVMAdmin on Cluster $($TargetCVM)."
Update-VSISlack -Message $SlackMessage -Slack $Slack


$var_Deployed_VMs = Set-OmnissaVMsAhv -BaseVM $var_Omnissa_Base_Vm_Name -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -NumberOfVMs $var_Number_Of_Vms -NamingConvention $var_Naming_Convention -StartIndex $var_Start_Index -Domain $var_Domain -AdminUserName $var_AD_Admin -AdminPassword $var_Admin_Password -OU $var_OU -RootPath $var_Ansible_Path

$CurrentVmsUnsorted = Get-ADComputers -filter $Filter -UserName "$($var_NetBios_Domain)\$var_AD_User" -Password $var_Admin_Password -LDAPServer $var_LDAPServer -BaseDN $var_Base_DN
$CurrentVms = $CurrentVmsUnsorted | Sort-Object
#endregion Build New VMs

#region Remove CD ROM
#----------------------------------------------------------------------------------------------------------------------------

$i = 1
foreach($VM in $CurrentVms){
    Write-Log -Update -Message "Removing CD-ROM $($i) of $($var_Number_Of_Vms)." -Level Info
    $vmUUID = (Get-NTNXVMS -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword | where-object { $_.name -eq $VM }).uuid
    $Result = Remove-NutanixCDROM -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -VmUuid $vmUUID
    $i++
}
#endregion Remove CD ROM

#region Create Omnissa Pool
#----------------------------------------------------------------------------------------------------------------------------

$Pool = New-OmnissaManualPool -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -PoolName $var_Omnissa_Pool_Name

$CreatedPool = Get-OmnissaDesktopPools -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -PoolName $var_Omnissa_Pool_Name
$Machines = Get-OmnissaPhysicalMachines -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -MachineNaming $Filter

$machinesToAdd = New-Object System.Collections.Generic.List[System.Object]

foreach ($machine in $machines){
    $machinesToAdd.Add($machine.id)
}

$machinesToAddPayload = $machinesToAdd | ConvertTo-Json
$addingMachines = Set-OmnissaManualPoolMachines -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -PoolID $CreatedPool.id -Payload $machinesToAddPayload

$OmnissaGroup = Get-OmnissaGroupSID -GroupName $var_Omnissa_Group -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain

$Entitlement = Set-OmnissaManualPoolEntitlement -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -PoolID $CreatedPool.id -GroupID $OmnissaGroup.id
#endregion Create Omnissa Pool

#region Update Slack
#----------------------------------------------------------------------------------------------------------------------------

Write-Log -Message "Updating Slack" -Level Info
$SlackMessage = "AHV Omnissa Manual Pool Created`r
Pool Name: $($var_Omnissa_Pool_Name)`r
Number of VMs: $($var_Number_Of_Vms)`r
VM Naming Convention: $($var_Naming_Convention)"
Update-VSISlack -Message $SlackMessage -Slack $Slack
#endregion Update Slack

#endregion Execute