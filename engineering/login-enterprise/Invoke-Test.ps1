<##
.SYNOPSIS
.DESCRIPTION
.PARAMETER ConfigFile
The JSON file containing the test configuration
.PARAMETER ReportConfigFile
.PARAMETER Type
Specify the type of test to be run, CitrixVAD, CitrixDaaS, Horizon, RAS
.NOTES
TODO
- Query Inlfux for running tests against LE appliance
- Remember to replace BREAK with Break! Temporarily using Break
- MaxRecordCount coming in from JSON file. Need to update the functions to include this value wherever a Get-BrokerMachine lookup occurs? Check with Dave on the best way to pull that through globally (line 275)
- Do we want to cset the $Type Parameter to align with the DeliveryType value in the JSON file?
------------------------------------------------------------------------------------------
### REVIEW NOTES - WORK IN PROGRESS - REMOVE ONCE VALIDATED
------------------------------------------------------
| Item | Requester | Reviewer | Date |
| Move HV Helper and HV Functions into new framework (review functions for logging etc) | James | James/Sven/Dave | 16.11.2023 |
| Review Output Logic - Search for "Report Output here on relevent variables" | James | Dave/Sven | 16.11.2023 |
------------------------------------------------------

-----------------------------------------------------------------------------------------

#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = "C:\DevOps\solutions-euc\engineering\login-enterprise\Nutanix.EUC\ExampleConfig-Kindon-Cleansed.jsonc",

    [Parameter(Mandatory = $false)]
    [string]$LEConfigFile = "C:\DevOps\solutions-euc\engineering\login-enterprise\Nutanix.EUC\ExampleConfig-LoginEnterpriseGlobal.jsonc",

    [Parameter(Mandatory = $false)]
    [string]$ReportConfigFile = ".\ReportConfiguration.jsonc",

    [Parameter(Mandatory = $false)]
    [ValidateSet("CitrixVAD", "CitrixDaaS", "Horizon", "RAS")]
    [string]$Type,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$SkipWaitForIdleVMs,

    [Parameter(Mandatory = $false)]
    [switch]$SkipPDFExport,

    [Parameter(Mandatory = $false)]
    [switch]$SkipADUsers,

    [Parameter(Mandatory = $false)]
    [switch]$SkipLEUsers,

    [Parameter(Mandatory = $false)]
    [switch]$SkipLaunchers,

    [Parameter(Mandatory = $false)]
    [ValidateSet("LE1", "LE2", "LE3", "LE4")]
    [String]$LEAppliance

)
#endregion Params

##// Add a JSON Builder job here - don't execute anything other than a JSON output

#region Variables
# ============================================================================
# Variables
# ============================================================================

If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }
$Validated_Workload_Profiles = @("Task Worker", "Knowledge Worker")
$Validated_OS_Types = @("multisession", "singlesession")
#$VSI_Target_RampupInMinutes = 10 ##// This needs to move to JSON
#$MaxRecordCount = 5000 ##// This needs to move to JSON Input
#$InfluxTestDashBucket = "Tests" ##// This needs to move to Variables
#endregion Variables

#Region Execute
# ============================================================================
# Execute
# ============================================================================

#region Nutanix Module Import
#----------------------------------------------------------------------------------------------------------------------------
$var_ModuleName = "Nutanix.EUC"
Write-Host "$([char]0x1b)[96m[$([char]0x1b)[97m$(Get-Date)$([char]0x1b)[96m]$([char]0x1b)[97m INFO: Trying to import $var_ModuleName module"
try {
    Import-Module "$ScriptRoot\$var_ModuleName\$var_ModuleName.psd1" -Force -ErrorAction Stop
    Write-Log -Message "Successfully imported $var_ModuleName Module" -Level Info
}
catch {
    Write-Host "$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: Failed to import $var_ModuleName module. Exit script"
    Write-Host "$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: $_"
    Break #Temporary! Replace with #Exit 1
}
#endregion Nutanix Module Import

#region Param Output
#----------------------------------------------------------------------------------------------------------------------------
Write-Log -Message "Configuration File is:        $($ConfigFile)" -Level Validation
Write-Log -Message "LE Configuration File is:     $($LEConfigFile)" -Level Validation
Write-Log -Message "Report Configuration File is: $($ReportConfigFile)" -Level Validation
Write-Log -Message "Test Type is:                 $($Type)" -Level Validation
#endregion Param Output

#region PowerShell Versions
#----------------------------------------------------------------------------------------------------------------------------
if ($PSVersionTable.PSVersion.Major -lt 5) { 
    Write-Log -Message "You must upgrade to PowerShell 5.x to run this script" -Level Warn
    Break #Temporary! Replace with #Exit 1
}

#endregion PowerShell Versions

#region Citrix Snapin Import
#----------------------------------------------------------------------------------------------------------------------------
if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
    if ($PSVersionTable.PSVersion.Major -gt 6) { 
        Write-Log -Message "You cannot use PowerShell $($PSVersionTable.PSVersion.Major) with Citrix snapins. Please revert to PowerShell 5.x" -Level Warn
        Break #Temporary! Replace with #Exit 1
    }
    try {
        Write-Log -Message "Importing Citrix Snapins" -Level Info
        Add-PSSnapin Citrix* -ErrorAction Stop
        Get-PSSnapin Citrix* -ErrorAction Stop | out-null
        Write-Log -Message "Successfully imported Citrix Snapins" -Level Info
    }
    catch {
        Write-Log -Message "Failed to import Citrix Snapins" -Level Error
        Write-Log -Message $_ -Level Error
        Break #Temporary! Replace with #Exit 1
    }
}
#endregion Citrix Snapin Import

#region VMWare Module Import
if ($Type -eq "Horizon") {
    Write-Log -Message "Importing VMware Modules" -Level Info
    try {
        $Modules = @("VMware.VimAutomation.Core", "VMware.VimAutomation.HorizonView")
        foreach ($moduleName in $Modules) {
            if (-not(Get-Module -Name $moduleName)){
                Write-Log -Message "Module: $($moduleName) does not exist. Attempting to install."
                try {
                    Install-Module $moduleName -ErrorAction Stop -Force -AllowClobber
                    Import-Module $moduleName -SkipEditionCheck -Force -ErrorAction Stop -DisableNameChecking -Verbose:$false | Out-Null
                }
                catch {
                    Write-Log -Message "Failed to Install Mode: $($moduleName)" -Level Error
                    Write-Log -Message $_ -Level Error
                    Break #Temporary! Replace with #Exit 1
                }
            }
        }
        
        Write-Log -Message "Importing VMWare Helper Module" -Level Info
        $moduleName = (Get-Item $ScriptRoot\$var_ModuleName\Nutanix.EUC.VMware\commands\VMware.Hv.Helper).FullName
        if ($moduleName) {
            try {
                Import-Module $moduleName -Force -ErrorAction Stop -SkipEditionCheck -Verbose:$false | Out-Null
            }
            catch {
                Write-Log -Message "Failed to Install Mode: $($moduleName)" -Level Error
                Write-Log -Message $_ -Level Error
                Break #Temporary! Replace with #Exit 1
            }
            
        }
        else {
            Write-Log -Message "Module: VMware.Hv.Helper not Found" -Level Error
            Break #Temporary! Replace with #Exit 1
        }
    }
    catch {
        Write-Log -Message "Failed to Import Modules" -Level Error
        Write-Log -Message $_ -Level Info
        Break #Temporary! Replace with #Exit 1
    }
}
#endregion VMWare Module Import

#region remove existing SSH Keys ***UPDATE****
#----------------------------------------------------------------------------------------------------------------------------
Write-Log -Message "Searching all modules for Posh-SSH" -Level Info
$Temp_Module = (Get-Module -ListAvailable *) | Where-Object { $_.Name -eq "Posh-SSH" }

if ($Null -ne $Temp_Module -and $Temp_Module.Version -contains "2.3.0") {
    Write-Log -Message "Module Posh-SSH Found. Clearing existing SSH Keys if present" -Level Info
    Get-SSHTrustedHost | Remove-SSHTrustedHost
} 
else {
    Write-Log -Message "Failed to find appropriate Posh-SSH Module. Attempting to Install" -Level Info
    try {
        Install-Module -Name Posh-SSH -RequiredVersion 2.3.0 -Force -ErrorAction Stop
        Write-Log -Message "Successfully installed Posh-SSH Module" -Level Info
        Get-SSHTrustedHost | Remove-SSHTrustedHost
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break #Temporary! Replace with #Exit 1
    }
}
$Temp_Module = $null
#endregion remove existing SSH Keys

#region Validate JSON

#if(Get-ValidJSON -JSON $ConfigFile){
    #Passed
#} else {
    #Failed - Break
#}

#endregion Validate JSON

#region variable setting
#----------------------------------------------------------------------------------------------------------------------------
Set-VSIConfigurationVariables -ConfigurationFile $ConfigFile

$LEAppliance = $VSI_Test_LEAppliance
if ($null -ne $LEAppliance) {
    Set-VSIConfigurationVariablesLEGlobal -ConfigurationFile $LEConfigFile -LEAppliance $LEAppliance
}
else {
    Write-Log -Message "Missing Logon Appliance Detail. Please check config file." -Level Warn
    Break #Temporary! Replace with #Exit 1
}


# Fix trailing slash issue
$VSI_LoginEnterprise_ApplianceURL = $VSI_LoginEnterprise_ApplianceURL.TrimEnd("/")
# Populates the $global:LE_URL
Connect-LEAppliance -Url $VSI_LoginEnterprise_ApplianceURL -Token $VSI_LoginEnterprise_ApplianceToken

#region Config File
#----------------------------------------------------------------------------------------------------------------------------
Write-Log -Message "Importing config file: $($ConfigFile)" -Level Info
try {
    $configFileData = Get-Content -Path $ConfigFile -ErrorAction Stop
}
catch {
    Write-Log -Message "Failed to import config file: $($configFile)" -Level Error
    Write-Log -Message $_ -Level Error
    Break #Temporary! Replace with #Exit 1
}

$configFileData = $configFileData -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'

try {
    $config = $configFileData | ConvertFrom-Json -ErrorAction Stop
}
catch {
    Write-Log -Message $_ -Level Error
    Break #Temporary! Replace with #Exit 1
}
#endregion Config File

#region Get Nutanix Infra
#----------------------------------------------------------------------------------------------------------------------------
$NTNXInfra = Get-NTNXinfo -Config $config
#endregion Get Nutanix Infra

#endregion variable setting

#region Script behaviour from file (params)
#----------------------------------------------------------------------------------------------------------------------------

## Allow the script to override JSON values via parameter
if ($SkipADUsers.IsPresent) { $SkipADUsers = $true } else { $SkipADUsers = $VSI_Test_SkipADUsers }
if ($SkipLEUsers.IsPresent) { $SkipLEUsers = $true } else { $SkipLEUsers = $VSI_Test_SkipLEUsers }
if ($SkipLaunchers.IsPresent) { $SkipLaunchers = $true } else { $SkipLaunchers = $VSI_Test_SkipLaunchers }
if ($SkipPDFExport.IsPresent) { $SkipPDFExport = $true } else { $SkipPDFExport = $VSI_Test_SkipPDFExport }
if ($SkipWaitForIdleVMs.IsPresent) { $SkipWaitForIdleVMs = $true } else { $SkipWaitForIdleVMs = $VSI_Test_SkipWaitForIdleVMs }
if (-not $LEAppliance) {$LEAppliance = $VSI_Test_LEAppliance}

$VSI_Target_RampupInMinutes = $VSI_Test_Target_RampupInMinutes
$InfluxTestDashBucket = $VSI_Test_InfluxTestDashBucket
$Global:MaxRecordCount = $VSI_Target_MaxRecordCount


#endregion Script behaviour from file (params)

#region Validation
#----------------------------------------------------------------------------------------------------------------------------
##// Report Output here on relevent variables- Dave wants a Snazzy Header
# We might use a standard JSON string lookup here and simply report on values that have no been set (but should be set).

##// Write out a prompt here post validation work - make sure all is good before going
$answer = read-host "Test details correct for test? yes or no? "
if ($answer -ne "yes" -and $answer -ne "y") { 
    Write-Log -Message "Input not confirmed. Exit" -Level Info
    Break #Temporary! Replace with #Exit 0
}
else {
    Write-Log -Message "Input confirmed" -Level Info
}

#region Nutanix Files Pre Flight Checks
#----------------------------------------------------------------------------------------------------------------------------
if ($VSI_Target_Files -ne "") {
    Write-Log -Message "Validating Nutanix Files Authentication" -Level Info
    
    Invoke-NutanixFilesAuthCheck

    if ($null -ne $VSI_Test_Nutanix_Files_Shares -and $VSI_Test_Delete_Files_Data -eq $true) {
        ##TODO Need to validate this
        Write-Log -Message "Processing Nutanix Files Data Removal Validation" -Level Info
        ##Remove-NutanixFilesData -Shares $VSI_Test_Nutanix_Files_Shares -Mode Validate
    }
}
#endregion Nutanix Files Pre Flight Checks

#region Nutanix Snapshot Pre Flight Checks
if ($NTNXInfra.Testinfra.HypervisorType -eq "AHV") {
    $cleansed_snapshot_name = $VSI_Target_ImagesToTest.ParentVM -replace ".template",""
    Get-NutanixSnapshot -SnapshotName $cleansed_snapshot_name -HypervisorType $NTNXInfra.Testinfra.HypervisorType
}
if ($NTNXInfra.Testinfra.HypervisorType -eq "ESXi") {

    if ($VSI_Target_ImagesToTest.ParentVM -match '^([^\\]+)\.') { $cleansed_vm_name = $matches[1] }
    if ($VSI_Target_ImagesToTest.ParentVM -match '\\([^\\]+)\.snapshot$') { $cleansed_snapshot_name = $matches[1] }

    Get-NutanixSnapshot -VM $cleansed_vm_name -SnapshotName $cleansed_snapshot_name -HypervisorType $NTNXInfra.Testinfra.HypervisorType
}

#endregion Nutanix Snapshot Pre Flight Checks

#endregion Validation

#region Execute Test
#----------------------------------------------------------------------------------------------------------------------------
#Set the multiplier for the Workloadtype. This adjusts the required MHz per user setting.
ForEach ($ImageToTest in $VSI_Target_ImagesToTest) {
    $null = Set-VSIConfigurationVariables -ImageConfiguration $ImageToTest
#}
    #region Validate Workload Profiles
    #----------------------------------------------------------------------------------------------------------------------------
    if ($VSI_Target_Workload -notin $Validated_Workload_Profiles ) {
        Write-Log -Message "Worker Profile: $($VSI_Target_Workload) is not a valid profile for testing. Please check config file" -Level Error
        Break #Temporary! Replace with #Exit 1
    }
    if ($VSI_Target_Workload -eq "Task Worker") {
        $LEWorkload = "TW"
        $WLmultiplier = 0.8
    }
    if ($VSI_Target_Workload -eq "Knowledge Worker") {
        $LEWorkload = "KW"
        $WLmultiplier = 1.1
    }
    Write-Log -Message "LE Worker Profile is: $($VSI_Target_Workload) and the Workload is set to: $($LEWorkload)" -Level Info
    #endregion Validate Workload Profiles

    #region Setup testname
    #----------------------------------------------------------------------------------------------------------------------------
    Write-Log -Message "Setting up Test Details" -Level Info
    $NTNXid = (New-Guid).Guid.SubString(1, 6)
    $NTNXTestname = "$($NTNXid)_$($VSI_Target_NodeCount)n_A$($NTNXInfra.Testinfra.AOSversion)_$($NTNXInfra.Testinfra.HypervisorType)_$($VSI_Target_NumberOfVMS)V_$($VSI_Target_NumberOfSessions)U_$LEWorkload"
    Write-Log -Message "Testname configured: $($NTNXTestname)" -Level Info
    #endregion Setup testname

    #region Setup Test Dashboard Data
    #----------------------------------------------------------------------------------------------------------------------------
    $CurrentTotalPhase = 1
    $TotalPhases = (([int]$NTNXInfra.Target.ImageIterations * $RunPhases) + $PreRunPhases)

    # Build Test Dashboard Objects

    for ($i = 0; $i -le $VSI_Target_ImageIterations; $i++) {
        if ($i -eq 0) { $Phases = $TotalPhases } else { $Phases = $RunPhases }
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Planned" 
            CurrentPhase   = "0" 
            CurrentMessage = "Scheduled Test Run" 
            TotalPhase     = "$($Phases)"
        }
        $null = Set-TestData @params
        $params = $null
    }

    #endregion Setup Test Dashboard Data

    #region Set affinity
    #----------------------------------------------------------------------------------------------------------------------------

    # Update Test Dashboard
    $params = @{
        ConfigFile     = $NTNXInfra
        TestName       = $NTNXTestname 
        RunNumber      = "0" 
        InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
        InfluxBucket   = $InfluxTestDashBucket 
        Status         = "Running" 
        CurrentPhase   = $CurrentTotalPhase 
        CurrentMessage = "Setting Affinity Rules" 
        TotalPhase     = "$($TotalPhases)"
    }
    $null = Set-TestData @params
    $params = $null
    $CurrentTotalPhase++

    if ($VSI_Target_NodeCount -eq "1") {
        $NTNXInfra.Testinfra.SetAffinity = $true
    }
    else {
        $NTNXInfra.Testinfra.SetAffinity = $false
    }
    Write-Log -Message "Nutanix Host Affinity is set to: $($NTNXInfra.Testinfra.SetAffinity)" -Level Info
    #endregion Set affinity

    $NTNXInfra.Target.ImagesToTest = $ImageToTest

    #region Slack update
    #----------------------------------------------------------------------------------------------------------------------------
    Write-Log -Message "Updating Slack" -Level Info
    $SlackMessage = "New Login Enterprise test started by $VSI_Target_CVM_admin on Cluster $($NTNXInfra.TestInfra.ClusterName). Testname: $($NTNXTestname)."
    Update-VSISlack -Message $SlackMessage -Slack $($NTNXInfra.Testinfra.Slack)
    #endregion Slack update

    #region Citrix validation
    #----------------------------------------------------------------------------------------------------------------------------

    if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
        Write-Log -Message "Validating Citrix" -Level Info

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Validating Citrix Connectivity" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        Connect-VSICTX -DDC $VSI_Target_DDC
    }
    #endregion Citrix validation

    #region Horizon validation
    #----------------------------------------------------------------------------------------------------------------------------
    if ($Type -eq "Horizon") {
        Write-Log -Message "Validating Horizon" -Level Info

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Validating Horizon Connectivity" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        #placeholder for Horizon
        $params = @{
            Server          = $VSI_Target_ConnectionServer 
            User            = $VSI_Target_ConnectionServerUser 
            Password        = $VSI_Target_ConnectionServerUserPassword 
            vCenterServer   = $VSI_Target_vCenterServer 
            vCenterUserName = $VSI_Target_vCenterUsername 
            vCenterPassword = $VSI_Target_vCenterPassword
        }
        Connect-VSIHVConnectionServer @params
        $Params = $Null
    }
    #endregion Horizon validation

    #region LE Test Check
    #----------------------------------------------------------------------------------------------------------------------------

    # Update Test Dashboard
    $params = @{
        ConfigFile     = $NTNXInfra
        TestName       = $NTNXTestname 
        RunNumber      = "0" 
        InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
        InfluxBucket   = $InfluxTestDashBucket 
        Status         = "Running" 
        CurrentPhase   = $CurrentTotalPhase 
        CurrentMessage = "Getting/Completing Existing LE Tests" 
        TotalPhase     = "$($TotalPhases)"
    }
    $null = Set-TestData @params
    $params = $null
    $CurrentTotalPhase++

    Write-Log -Message "Polling LE for tests" -Level Info
    $Test = Get-LETests | Where-Object { $_.name -eq $VSI_Test_Name }
    Wait-LeTest -testId $Test.Id
    #endregion LE Test Check

    #region LE Users
    #----------------------------------------------------------------------------------------------------------------------------

    # Update Test Dashboard
    if (($SkipLEUsers)) { $Message = "Skipping Login Enterprise User Creation" } else { $Message = "Creating Login Enterprise Users" }
    $params = @{
        ConfigFile     = $NTNXInfra
        TestName       = $NTNXTestname 
        RunNumber      = "0" 
        InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
        InfluxBucket   = $InfluxTestDashBucket 
        Status         = "Running" 
        CurrentPhase   = $CurrentTotalPhase 
        CurrentMessage = "$($Message)" 
        TotalPhase     = "$($TotalPhases)"
    }
    $null = Set-TestData @params
    $params = $null
    $CurrentTotalPhase++

    if (!($SkipLEUsers)) {
        # Create the accounts and accountgroup in LE
        Write-Log -Message "Creating Accounts and Groups in LE" -Level Info
        $LEaccounts = New-LEAccounts -Username $VSI_Users_BaseName -Password $VSI_Users_Password -Domain $VSI_Users_NetBios -NumberOfDigits $VSI_Users_NumberOfDigits -NumberOfAccounts $VSI_Target_NumberOfSessions
        New-LEAccountGroup -Name $VSI_Users_GroupName -Description "Created by automation toolkit" -MemberIds $LEaccounts | Out-Null
    }
    #endregion LE Users

    #region AD Users
    #----------------------------------------------------------------------------------------------------------------------------

    # Update Test Dashboard
    if (($SkipADUsers)) { $Message = "Skipping AD User Creation" } else { $Message = "Creating AD Users" }
    $params = @{
        ConfigFile     = $NTNXInfra
        TestName       = $NTNXTestname 
        RunNumber      = "0" 
        InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
        InfluxBucket   = $InfluxTestDashBucket 
        Status         = "Running" 
        CurrentPhase   = $CurrentTotalPhase 
        CurrentMessage = "$($Message)" 
        TotalPhase     = "$($TotalPhases)"
    }
    $null = Set-TestData @params
    $params = $null
    $CurrentTotalPhase++

    if (!($SkipADUsers)) {
        # OUs will be created if they don't exist, will also create a group with the $Basename in the same OU
        # This variant for when you're running this from a domain joined machine and your current user has rights to create AD resources
        if ([string]::isNullOrEmpty($VSI_Domain_LDAPUsername)) {
            $params = @{
                BaseName       = $VSI_Users_BaseName
                Amount         = $VSI_Target_NumberOfSessions
                Password       = $VSI_Users_Password
                NumberOfDigits = $VSI_Users_NumberOfDigits
                DomainLDAPPath = $VSI_Domain_LDAPPath
                OU             = $VSI_Users_OU
                ApplianceURL   = $VSI_LoginEnterprise_ApplianceURL
            }
            New-VSIADUsers @params
        }
        else {
            # Alternative for when invoking the toolkit from a machine that's not part of the domain/ user that does not have the appropriate rights to create users
            $params = @{
                BaseName       = $VSI_Users_Basename
                Amount         = $VSI_Target_NumberOfSessions
                Password       = $VSI_Users_Password
                NumberOfDigits = $VSI_Users_NumberOfDigits
                DomainLDAPPath = $VSI_Domain_LDAPPath
                OU             = $VSI_Users_OU
                LDAPUsername   = $VSI_Domain_LDAPUsername
                LDAPPassword   = $VSI_Domain_LDAPPassword
                ApplianceURL   = $VSI_LoginEnterprise_ApplianceURL
            }
            New-VSIADUsers @params
        }
    }

    $Params = $null
    #endregion AD Users

    if ($Type -eq "Horizon") {
        if ($Force.IsPresent) {
            Write-Log -Message "Removing Horizon Desktop Pool due to force switch" -Level Info
            Remove-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName
        }
    }

    #region Iterate through runs
    #----------------------------------------------------------------------------------------------------------------------------
    for ($i = 1; $i -le $VSI_Target_ImageIterations; $i++) {

        $CurrentRunPhase = 1
        
        #region Update Slack
        #----------------------------------------------------------------------------------------------------------------------------
        $SlackMessage = "Testname: $($NTNXTestname) Run$i is started by $VSI_Target_CVM_admin on Cluster $($NTNXInfra.TestInfra.ClusterName)."
        Update-VSISlack -Message $SlackMessage -Slack $($NTNXInfra.Testinfra.Slack)

        #endregion Update Slack

        #region Get Nutanix Info
        #----------------------------------------------------------------------------------------------------------------------------

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Gathering Nutanix Information" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        $ContainerId = Get-NTNXStorageUUID -Storage $VSI_Target_CVM_storage
        $Hostuuid = Get-NTNXHostUUID -NTNXHost $VSI_Target_NTNXHost
        $IPMI_ip = Get-NTNXHostIPMI -NTNXHost $VSI_Target_NTNXHost
        
        if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
            ## Placeholder Block to capture the relevent settings below - will change with different tech
            $networkMap = @{ "0" = "XDHyp:\HostingUnits\" + $VSI_Target_HypervisorConnection + "\" + $VSI_Target_HypervisorNetwork + ".network" }
            $ParentVM = "XDHyp:\HostingUnits\$VSI_Target_HypervisorConnection\$VSI_Target_ParentVM"
        }
        
        #endregion Get Nutanix Info

        #region Configure Desktop Pool
        #----------------------------------------------------------------------------------------------------------------------------

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Creating $($Type) Desktop Pool" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
            ## Placeholder Block to capture the relevent settings below - will change with different tech
            $params = @{
                ParentVM             = $ParentVM
                HypervisorConnection = $VSI_Target_HypervisorConnection
                HypervisorType       = $NTNXInfra.Testinfra.HypervisorType
                Networkmap           = $networkMap
                CpuCount             = $VSI_Target_NumCPUs
                CoresCount           = $VSI_Target_NumCores
                MemoryGB             = $VSI_Target_MemoryGB
                ContainerID          = $ContainerId
                NamingPattern        = $VSI_Target_NamingPattern
                OU                   = $VSI_Target_ADContainer
                DomainName           = $VSI_Target_DomainName
                SessionsSupport      = $VSI_Target_SessionsSupport
                DesktopPoolName      = $VSI_Target_DesktopPoolName
                ZoneName             = $VSI_Target_ZoneName
                Force                = $Force.IsPresent ## Command line required this -Force:$Force.IsPresent note the :
                EntitledGroup        = $VSI_Users_BaseName
                SkipImagePrep        = $VSI_Target_SkipImagePrep
                FunctionalLevel      = $VSI_Target_FunctionalLevel
                CloneType            = $VSI_Target_CloneType
                DDC                  = $VSI_Target_DDC
            }
            $CreatePool = Set-VSICTXDesktopPoolNTNX @params
    
            $NTNXInfra.Testinfra.MaxAbsoluteActiveActions = $CreatePool.MaxAbsoluteActiveActions
            $NTNXInfra.Testinfra.MaxAbsoluteNewActionsPerMinute = $CreatePool.MaxAbsoluteNewActionsPerMinute
            $NTNXInfra.Testinfra.MaxPercentageActiveActions = $CreatePool.MaxPercentageActiveActions
        }


        if ($Type -eq "Horizon") {
            #Need to check with Sven here - which config do we use Horizon-NTNX.ps1 or NorizonView.Ps1?
            $params = @{
                Name                      = $VSI_Target_DesktopPoolName
                ParentVM                  = $VSI_Target_ParentVM
                VMSnapshot                = $VSI_Target_Snapshot
                VMFolder                  = $VSI_Target_VMFolder
                HostOrCluster             = $VSI_Target_Cluster
                ResourcePool              = $VSI_Target_ResourcePool
                ReplicaDatastore          = $VSI_Target_ReplicaDatastore
                InstantCloneDatastores    = $VSI_Target_InstantCloneDatastores
                NamingPattern             = $VSI_Target_NamingPattern
                NetBiosName               = $VSI_Target_DomainName
                ADContainer               = $VSI_Target_ADContainer
                EntitledGroups            = $VSI_Target_Entitlements
                vTPM                      = $VSI_Target_vTPM
                Protocol                  = $VSI_Target_SessionCfg
                RefreshOsDiskAfterLogoff  = $VSI_Target_RefreshOSDiskAfterLogoff
                UserAssignment            = $VSI_Target_UserAssignment
                PoolType                  = $VSI_Target_CloneType
                UseViewStorageAccelerator = $VSI_Target_UseViewStorageAccelerator
                enableGRIDvGPUs           = $VSI_Target_enableGRIDvGPUs
            }
            Set-VSIHVDesktopPool @params
            $Params = $null
        }

        #endregion Configure Desktop Pool

        #region Configure Folder Details for output
        #----------------------------------------------------------------------------------------------------------------------------
        $FolderName = "$($NTNXTestname)_Run$($i)"
        $OutputFolder = "$ScriptRoot\results\$FolderName"
        #endregion Configure Folder Details for output

        #region Start monitoring Boot phase
        #----------------------------------------------------------------------------------------------------------------------------

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Booting $($Type) Desktops" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        $params = @{
            OutputFolder                 = $OutputFolder 
            DurationInMinutes            = "Boot" 
            RampupInMinutes              = $VSI_Target_RampupInMinutes 
            Hostuuid                     = $Hostuuid 
            IPMI_ip                      = $IPMI_ip 
            Path                         = $Scriptroot 
            NTNXCounterConfigurationFile = $ReportConfigFile 
            AsJob                        = $true
        }
        $monitoringJob = Start-VSINTNXMonitoring @Params

        $params = $null

        if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
            #Placeholder block to capture the below settings
            $params = @{
                DesktopPoolName = $VSI_Target_DesktopPoolName
                NumberofVMs     = $VSI_Target_NumberOfVMS
                PowerOnVMs      = $VSI_Target_PowerOnVMs
                DDC             = $VSI_Target_DDC
                HypervisorType  = $NTNXInfra.Testinfra.HypervisorType
                Affinity        = $NTNXInfra.Testinfra.SetAffinity
                ClusterIP       = $NTNXInfra.Target.CVM
                CVMSSHPassword  = $NTNXInfra.Target.CVMsshpassword
                VMnameprefix    = $NTNXInfra.Target.NamingPattern
                CloneType       = $VSI_Target_CloneType
                Hosts           = $NTNXInfra.Testinfra.Hostip
                Type            = $Type
            }
            $Boot = Enable-VSICTXDesktopPool @params
    
            $Params = $null
        }

        if ($Type -eq "Horizon") {
            # Need to check with Sven on this
            if ($VSI_Target_PoolType -eq "RDSH") {
                $Boot = Enable-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName -VMAmount $VSI_Target_NumberOfVMs -Increment $VSI_Target_VMPoolIncrement -RDSH
            }
            elseif ($VSI_Target_ProvisioningMode -eq "AllMachinesUpFront") {
                $Boot = Enable-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName -VMAmount $VSI_Target_NumberOfVMs -Increment $VSI_Target_VMPoolIncrement -AllMachinesUpFront
            }
            else {
                $Boot = Enable-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName -VMAmount $VSI_Target_NumberOfVMs -NumberOfSpareVMs $VSI_Target_NumberOfSpareVMs
            }
        }

        $NTNXInfra.Testinfra.BootStart = $Boot.bootstart
        $NTNXInfra.Testinfra.Boottime = $Boot.boottime
        #endregion Start monitoring Boot phase

        #region Get Build Tattoo Information and update variable with new values
        #----------------------------------------------------------------------------------------------------------------------------
        if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
            $BrokerVMs = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $VSI_Target_DesktopPoolName -MaxRecordCount $MaxRecordCount
            $RegisteredVMs = ($BrokerVMS | Where-Object { $_.RegistrationState -eq "Registered" })
            $MasterImageDNS = $RegisteredVMs[0].DNSName
        }
        
        if ($Type -eq "Horizon") {
            $MasterImageDNS = $boot.firstvmname
        }

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Getting Image Tattoo" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        try {
            Write-Log -Message "Getting Image Tattoo" -Level Info
            $Tattoo = Invoke-Command -Computer $MasterImageDNS { Get-ItemProperty HKLM:\Software\BuildTatoo } -ErrorAction Stop 
            $NTNXInfra.Target.ImagesToTest.TargetOS = $Tattoo.OSName
            $NTNXInfra.Target.ImagesToTest.TargetOSVersion = $Tattoo.OSVersion
            $NTNXInfra.Target.ImagesToTest.OfficeVersion = $Tattoo.OfficeName
            $NTNXInfra.Target.ImagesToTest.ToolsGuestVersion = $Tattoo.GuestToolsVersion
            $NTNXInfra.Target.ImagesToTest.OptimizerVendor = $Tattoo.Optimizer
            $NTNXInfra.Target.ImagesToTest.OptimizationsVersion = $Tattoo.OptimizerVersion
            $NTNXInfra.Target.ImagesToTest.DesktopBrokerAgentVersion = $Tattoo.VdaVersion
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break #Temporary! Replace with #Exit 1
        }
        
        #endregion Get Build Tattoo Information and update variable with new values

        #region Set number of sessions per launcher
        #----------------------------------------------------------------------------------------------------------------------------

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Rebooting Login Enterprise Launchers" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        if ($($VSI_Target_SessionCfg.ToLower()) -eq "ica") {
            $SessionsperLauncher = 20
        }
        else {
            $SessionsperLauncher = 12
        }
        if (-not ($SkipLaunchers)) {
            $NumberOfLaunchers = [System.Math]::Ceiling($VSI_Target_NumberOfSessions / $SessionsperLauncher)
            # Wait for all launchers to be registered in LE
            Wait-LELaunchers -Amount $NumberOfLaunchers -NamingPattern $VSI_Launchers_NamingPattern
            # Create/update launchergroup with the launchers
            Set-LELauncherGroup -LauncherGroupName $VSI_Launchers_GroupName -NamingPattern $VSI_Launchers_NamingPattern
        }
        #endregion Set number of sessions per launcher

        #region Update the test params/create test if not exist
        #----------------------------------------------------------------------------------------------------------------------------

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Updating Login Enterprise Test Details" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
            ## Placeholder Block to capture the relevent settings below - will change with different tech
            $Params = @{
                TestName          = $VSI_Test_Name
                SessionAmount     = $VSI_Target_NumberOfSessions
                RampupInMinutes   = $VSI_Target_RampupInMinutes
                DurationInMinutes = $VSI_Target_DurationInMinutes
                LauncherGroupName = $VSI_Launchers_GroupName
                AccountGroupName  = $VSI_Users_GroupName
                ConnectorName     = "Citrix Storefront"
                ConnectorParams   = @{serverURL = $VSI_Target_StorefrontURL; resource = $VSI_Target_DesktopPoolName }
                Workload          = $VSI_Target_Workload
            }
            $testId = Set-LELoadTest @Params
            $params = $null
        }
        
        #endregion Update the test params/create test if not exist

        #region Wait for VM's to have settled down
        #----------------------------------------------------------------------------------------------------------------------------
        if (-not ($SkipWaitForIdleVMs)) {
            Write-Log -Message "Waiting 60 seconds for VMs to become idle" -Level Info
            Start-Sleep -Seconds 60
        }
        #endregion Wait for VM's to have settled down

        #region Stop and cleanup monitoring job Boot phase
        #----------------------------------------------------------------------------------------------------------------------------
        $monitoringJob | Stop-Job
        $monitoringJob | Remove-Job
        #endregion Stop and cleanup monitoring job Boot phase

        #region Set RDA Source and Destination files and clean out source files if they still exist
        #----------------------------------------------------------------------------------------------------------------------------
        $RDADestination = "$OutputFolder\RDA.csv"
        $RDASource = Join-Path -Path "$($NTNXInfra.TestInfra.RDAPath)" -ChildPath "$($VSI_Users_BaseName)0001.csv"
        if (Test-Path -Path $RDASource) {
            Write-Log -Message "Removing RDA Source File $($RDASource)" -Level Info
            Remove-Item -Path $RDASource -ErrorAction SilentlyContinue
        }
        else {
            Write-Log -Message "RDA Source File $($RDASource) does not exist" -Level Info
        }
        #endregion Set RDA Source and Destination files and clean out source files if they still exist

        #region VM Idle state
        #----------------------------------------------------------------------------------------------------------------------------

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Waiting $($VSI_Target_MinutesToWaitAfterIdleVMs) Minutes Before Test" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        Write-Log -Message "Waiting for $VSI_Target_MinutesToWaitAfterIdleVMs minutes before starting test" -Level Info
        Start-sleep -Seconds $($VSI_Target_MinutesToWaitAfterIdleVMs * 60)
        #endregion VM Idle state

        #region Nutanix Curator Stop
        #----------------------------------------------------------------------------------------------------------------------------

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Stopping Nutanix Curator" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        Write-Log -Message "Stopping Nutanix Curator Service" -Level Info
        Set-NTNXcurator -ClusterIP $NTNXInfra.Target.CVM -CVMSSHPassword $NTNXInfra.Target.CVMsshpassword -Action "stop"
        #endregion Nutanix Curator Stop

        #region Start the test
        #----------------------------------------------------------------------------------------------------------------------------

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Starting Test Run $($i)" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        Write-Log -Message "Starting Test $($testId)" -Level Info
        Start-LETest -testId $testId -Comment "$FolderName-$VSI_Target_Comment"
        $TestRun = Get-LETestRuns -testId $testId | Select-Object -Last 1
        #endregion Start the test

        #region Start monitoring
        #----------------------------------------------------------------------------------------------------------------------------

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Starting Login Enterprise Test Monitor Run $($i)" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        $Params = @{
            OutputFolder                 = $OutputFolder 
            DurationInMinutes            = $VSI_Target_DurationInMinutes 
            RampupInMinutes              = $VSI_Target_RampupInMinutes 
            Hostuuid                     = $Hostuuid 
            IPMI_ip                      = $IPMI_ip 
            Path                         = $Scriptroot 
            NTNXCounterConfigurationFile = $ReportConfigFile 
            AsJob                        = $true
        }
        $monitoringJob = Start-VSINTNXMonitoring @params
        $Params = $null

        # Update Test Dashboard
        if ($VSI_Target_Files -ne "") { $Message = "Starting Nutanix Files Monitor Run $($i)" } else { $Message = "Skipping Nutanix Files Monitoring" }
        Write-Log -Message "$($Message)" -Level Info
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "$Message" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        if ($VSI_Target_Files -ne "") {
            $Params = @{
                OutputFolder                 = $OutputFolder 
                DurationInMinutes            = $VSI_Target_DurationInMinutes 
                RampupInMinutes              = $VSI_Target_RampupInMinutes 
                Path                         = $Scriptroot 
                NTNXCounterConfigurationFile = $ReportConfigFile 
                AsJob                        = $true
            }
            $monitoringFilesJob = Start-NTNXFilesMonitoring @Params
            $Params = $null
        }

        # Update Test Dashboard
        if ($VSI_Target_NetScaler -ne "") { $Message = "Starting Citrix NetScaler Monitor Run $($i)" } else { $Message = "Skipping Citrix NetScaler Monitoring" }
        Write-Log -Message "$($Message)" -Level Info
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "$Message" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        if ($VSI_Target_NetScaler -ne "") {
            $Params = @{
                OutputFolder      = $OutputFolder 
                DurationInMinutes = $VSI_Target_DurationInMinutes 
                RampupInMinutes   = $VSI_Target_RampupInMinutes 
                Path              = $Scriptroot 
                AsJob             = $true
            }
            $monitoringNSJob = Start-NTNXNSMonitoring @params
            $Params = $null
        }
        #endregion Start monitoring

        #region Wait for test to finish
        #----------------------------------------------------------------------------------------------------------------------------

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Waiting For Test Run $($i) To Complete" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        # Update Test Dashboard
        $Waitparams = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Waiting for Test to Complete" 
            TotalPhase     = "$($RunPhases)"
        }

        Wait-LETest -testId $testId -waitParams $Waitparams
        #endregion Wait for test to finish

        #region Cleanup monitoring job
        #----------------------------------------------------------------------------------------------------------------------------
        $monitoringJob | Wait-Job
        $monitoringJob | Remove-Job
        if ($VSI_Target_Files -ne "") {
            $monitoringFilesJob | Wait-Job
            $monitoringFilesJob | Remove-Job
        }
        if ($VSI_Target_NetScaler -ne "") {
            $monitoringNSJob | Wait-Job
            $monitoringNSJob | Remove-Job
        }
        #endregion Cleanup monitoring job

        #region Nutanix Curator Start
        #----------------------------------------------------------------------------------------------------------------------------

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Starting Nutanix Curator" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        Write-Log -Message "Starting Nutanix Curator Service" -Level Info
        Set-NTNXcurator -ClusterIP $NTNXInfra.Target.CVM -CVMSSHPassword $NTNXInfra.Target.CVMsshpassword -Action "start"
        #endregion Nutanix Curator Start

        #region Write config to OutputFolder
        #----------------------------------------------------------------------------------------------------------------------------

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Exporting Test Data from Login Enterprise" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        $NTNXInfra.Testinfra.VMCPUCount = [Int]$VSI_Target_NumCPUs * [Int]$VSI_Target_NumCores
        $NTNXInfra.Testinfra.Testname = $FolderName
        $NTNXInfra | ConvertTo-Json -Depth 20 | Set-Content -Path $OutputFolder\Testconfig.json -Force
        Write-Log -Message "Exporting LE Measurements to output folder" -Level Info
        Export-LEMeasurements -Folder $OutputFolder -TestRun $TestRun -DurationInMinutes $VSI_Target_DurationInMinutes
        #endregion Write config to OutputFolder

        #region Check for RDA File and if exists then move it to the output folder
        #----------------------------------------------------------------------------------------------------------------------------
        if (Test-Path -Path $RDASource) {
            Write-Log -Message "Exporting RDA Data to output folder" -Level Info
            $csvData = get-content $RDASource | ConvertFrom-String -Delimiter "," -PropertyNames Timestamp, screenResolutionid, encoderid, movingImageCompressionConfigurationid, preferredColorDepthid, videoCodecid, VideoCodecUseid, VideoCodecTextOptimizationid, VideoCodecColorspaceid, VideoCodecTypeid, HardwareEncodeEnabledid, VisualQualityid, FramesperSecondid, RDHSMaxFPS, currentCPU, currentRAM, totalCPU, currentFps, totalFps, currentRTT, NetworkLatency, NetworkLoss, CurrentBandwidthEDT, totalBandwidthusageEDT, averageBandwidthusageEDT, currentavailableEDTBandwidth, EDTInUseId, currentBandwithoutput, currentLatency, currentavailableBandwidth, totalBandwidthusage, averageBandwidthUsage, averageBandwidthAvailable, GPUusage, GPUmemoryusage, GPUmemoryInUse, GPUvideoEncoderusage, GPUvideoDecoderusage, GPUtotalUsage, GPUVideoEncoderSessions, GPUVideoEncoderAverageFPS, GPUVideoEncoderLatency | Select -Skip 1
            $csvData | Export-Csv -Path $RDADestination -NoTypeInformation
            Remove-Item -Path $RDASource -ErrorAction SilentlyContinue
        }
        #endregion Check for RDA File and if exists then move it to the output folder

        #region Cleanup Nutanix Files Data
        #----------------------------------------------------------------------------------------------------------------------------

        # Update Test Dashboard
        if ($VSI_Target_Files -ne "") { $Message = "Starting Nutanix Files Data Clean" } else { $Message = "Skipping Nutanix Files Data Clean" }
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "$Message" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        if ($VSI_Target_Files -ne "") {
            if ($null -ne $VSI_Test_Nutanix_Files_Shares -and $VSI_Test_Delete_Files_Data -eq $true) { #Need to update the above messaging to reflect these detetion rules
                Write-Log -Message "Processing Nutanix Files Data Removal" -Level Info
                # TODO: Need to Validate this configuation
                ##Remove-NutanixFilesData -Shares $VSI_Test_Nutanix_Files_Shares -Mode Execute
            }
        }
        #endregion Cleanup Nutanix Files Data

        #region Upload Data to Influx
        #----------------------------------------------------------------------------------------------------------------------------

        # Update Test Dashboard
        if ($NTNXInfra.Test.UploadResults) { $Message = "Uploading Data to InfluxDB" } else { $Message = "Skipping InfluxDB Data Upload" }
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "$Message" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        if ($NTNXInfra.Test.UploadResults) {
            Write-Log -Message "Uploading Test Run Data to Influx" -Level Info
            
            $TestDetail = $NTNXInfra.TestInfra.TestName -Split '_Run'
            $Run = $TestDetail[1]

            # Get the boot files and start time
            $Files = Get-ChildItem "$($OutputFolder)\Boot\*.csv"
            $Started = $($NTNXInfra.TestInfra.Bootstart)

            # Build the Boot Bucket Name
            If ($($NTNXInfra.Test.BucketName) -eq "LoginDocuments") {
                $BucketName = "BootBucket"
            }
            Else {
                $BucketName = "BootBucketRegression"
            }

            # Loop through the boot files and process each one
            foreach ($File in $Files) {
                if (($File.Name -like "host raw*") -or ($File.Name -like "cluster raw*")) {
                    Write-Log -Message "Uploading $($File.name) to Influx" -Level Info
                    if (Start-InfluxUpload -influxDbUrl $NTNXInfra.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $NTNXInfra.Testinfra.InfluxToken -File $File -Started $Started -BucketName $BucketName) {
                        Write-Log -Message "Finished uploading Boot File $($File.Name) to Influx" -Level Info
                    }
                    else {
                        Write-Log -Message "Error uploading $($File.name) to Influx" -Level Warn
                    }
                }
                else {
                    Write-Log -Message "Skipped uploading Boot File $($File.Name) to Influx" -Level Info
                }
            }

            # Get the test run files and start time
            $Files = Get-ChildItem "$($OutputFolder)\*.csv"
            $vsiresult = Import-CSV "$($OutputFolder)\VSI-results.csv"
            $Started = $vsiresult.started
            $BucketName = $($NTNXInfra.Test.BucketName)

            # Loop through the test run data files and process each one
            foreach ($File in $Files) {
                if (($File.Name -like "Raw Timer Results*") -or ($File.Name -like "Raw Login Times*") -or ($File.Name -like "NetScaler Raw*") -or ($File.Name -like "host raw*") -or ($File.Name -like "files raw*") -or ($File.Name -like "cluster raw*") -or ($File.Name -like "raw appmeasurements*") -or ($File.Name -like "EUX-Score*") -or ($File.Name -like "EUX-timer-score*") -or ($File.Name -like "RDA*")) {
                    Write-Log -Message "Uploading $($File.name) to Influx" -Level Info
                    if (Start-InfluxUpload -influxDbUrl $NTNXInfra.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $NTNXInfra.Testinfra.InfluxToken -File $File -Started $Started -BucketName $BucketName) {
                        Write-Log -Message "Finished uploading File $($File.Name) to Influx" -Level Info
                    }
                    else {
                        Write-Log -Message "Error uploading $($File.name) to Influx" -Level Warn
                    }
                }
                else {
                    Write-Log -Message "Skipped uploading File $($File.Name) to Influx" -Level Info
                }
            }

        }
        else {
            Write-Log -Message "Skipping uploading Test Run Data to Influx" -Level Info
        }

        #endregion Upload Data to Influx

        $Testresult = import-csv "$OutputFolder\VSI-results.csv"
        $Appsuccessrate = $Testresult."Apps success" / $Testresult."Apps total" * 100

        #region Slack update
        #----------------------------------------------------------------------------------------------------------------------------
        $SlackMessage = "Testname: $($NTNXTestname) Run $i is finished on Cluster $($NTNXInfra.TestInfra.ClusterName). $($Testresult.activesessionCount) sessions active of $($Testresult."login total") total sessions. EUXscore: $($Testresult."EUX score") - VSImax: $($Testresult.vsiMax). App Success rate: $($Appsuccessrate.tostring("#.###"))"
        Update-VSISlack -Message $SlackMessage -Slack $($NTNXInfra.Testinfra.Slack)

        $FileName = Get-VSIGraphs -TestConfig $NTNXInfra -OutputFolder $OutputFolder -RunNumber $i -TestName $NTNXTestname

        if (Test-Path -path $Filename) {
            $Params = @{
                ImageURL     = $FileName 
                SlackToken   = $NTNXInfra.Testinfra.SlackToken 
                SlackChannel = $NTNXInfra.Testinfra.SlackChannel 
                SlackTitle   = "$($NTNXInfra.Target.ImagesToTest[0].Comment)_Run$($i)" 
                SlackComment = "CPU and EUX score of $($NTNXInfra.Target.ImagesToTest[0].Comment)_Run$($i)"
            }
            Update-VSISlackImage @params
            $Params = $null
        }
        else {
            Write-Log -Message "Image Failed to download and won't be uploaded to Slack. Check Logs for detail." -Level Warn
        }
        #endregion Slack update

        #region Finish Test Run
        #----------------------------------------------------------------------------------------------------------------------------

        # Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Completed" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Test Run $($i) Complete" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Finished Test Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++

        #endregion Finish Test Run

    }
    #endregion Iterate through runs

    #region Analyze Run results
    #----------------------------------------------------------------------------------------------------------------------------
    $null = Get-VSIResults -TestName $NTNXTestname -Path $ScriptRoot
    #endregion Analyze Run results

    #region Slack update
    #----------------------------------------------------------------------------------------------------------------------------
    Update-VSISlackresults -TestName $NTNXTestname -Path $ScriptRoot
    $OutputFolder = "$($ScriptRoot)\testresults\$($NTNXTestname)"
    $FileName = Get-VSIGraphs -TestConfig $NTNXInfra -OutputFolder $OutputFolder -TestName $NTNXTestname
    if (Test-Path -path $Filename) {
        $Params = @{
            ImageURL     = $FileName 
            SlackToken   = $NTNXInfra.Testinfra.SlackToken 
            SlackChannel = $NTNXInfra.Testinfra.SlackChannel 
            SlackTitle   = "$($NTNXInfra.Target.ImagesToTest[0].Comment)" 
            SlackComment = "CPU and EUX scores of $($NTNXInfra.Target.ImagesToTest[0].Comment) - All Runs"
        }
        Update-VSISlackImage @params
        $Params = $Null
    }
    else {
        Write-Log -Message "Image Failed to download and won't be uploaded to Slack. Check Logs for detail." -Level Warn
    }
    #endregion Slack update
}
#endregion Execute Test

# Update Test Dashboard
$params = @{
    ConfigFile     = $NTNXInfra
    TestName       = $NTNXTestname 
    RunNumber      = "0" 
    InfluxUri      = $NTNXInfra.TestInfra.InfluxDBurl 
    InfluxBucket   = $InfluxTestDashBucket 
    Status         = "Completed" 
    CurrentPhase   = $CurrentTotalPhase 
    CurrentMessage = "Test Complete" 
    TotalPhase     = "$($TotalPhases)"
}
$null = Set-TestData @params
$params = $null

#endregion Execute

Write-Log -Message "Script Finished" -Level Info
Break #Temporary! Replace with #Exit 0