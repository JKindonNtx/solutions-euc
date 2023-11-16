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
- Consolidate different configuration options into single script - DaaS, CVAD, Horizon, Parallels etc.
- Validate behaviour on anything with a -VALIDATE switch currently in the Write-Log function - odd behaviour
- Validate what should be in JSON, vs Param vs Variables
- Consider any other snapins - if only citrix, move the PowerShell check to the Citrix Type only.
- Fixup the Params in this script for Config File etc
- Consider Template JSON output based on -Planning Switch
- Switch setup -> API / Influx DB LE1 = 
    - Common -> JSON based?
    - CVAD -> Validate only the appropriate JSON config for CVAD
    - DaaS
    - Horizon -> 
    - NetScaler
- Query Inlfux for running tests against LE appliance
- Remember to replace BREAK with Exit 1! Temporarily using Break

------------------------------------------------------------------------------------------
### REVIEW NOTES - WORK IN PROGRESS - REMOVE ONCE VALIDATED
------------------------------------------------------
| Item | Requester | Reviewer | Date |
| Review Horizon Input Logic - Search for "$Mode -eq "Horizon"" | James | Sven | 16.11.2023 |
| Move HV Helper and HV Functions into new framework (review functions for logging etc) | James | James/Sven/Dave | 16.11.2023 |
| Review Files Auth Validation Logic - Search for "Invoke-NutanixFilesAuthCheck" | James | Dave | 16.11.2023 |
| Review LE Switching Logic and best Placement - search for "$placeholder_var_LEAppliance" | James | Dave/Sven | 16.11.2023 |
| Review Output Logic - Search for "Report Output here on relevent variables" | James | Dave/Sven | 16.11.2023 |
| Review Current JSON File - do we need values that are now auto calculated? | James | Sven | 16.11.2023 |
------------------------------------------------------

-----------------------------------------------------------------------------------------

#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = "C:\DevOps\solutions-euc\engineering\login-enterprise\Config-CitrixOnPrem-FSLogix.jsonc",

    [Parameter(Mandatory = $false)]
    [string]$ReportConfigFile = ".\ReportConfigurationNTNX.jsonc",

    [Parameter(Mandatory = $false)]
    [ValidateSet("CitrixVAD", "CitrixDaaS", "Horizon", "RAS")]
    [string]$Type

    #[Parameter(Mandatory = $false)]
    #[switch]$Force,

    #[Parameter(Mandatory = $false)]
    #[switch]$SkipWaitForIdleVMs,

    #[Parameter(Mandatory = $false)]
    #[switch]$SkipPDFExport,

    #[Parameter(Mandatory = $false)]
    #[switch]$SkipADUsers,

    #[Parameter(Mandatory = $false)]
    #[switch]$SkipLEUsers,

    #[Parameter(Mandatory = $false)]
    #[switch]$SkipLaunchers

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
$VSI_Target_RampupInMinutes = 48 ##// This needs to move to JSON
$MaxRecordCount = 5000 ##// This needs to move to Variables
$InfluxTestDashBucket = "Tests" ##// This needs to move to Variables
#endregion Variables

#Region Execute
# ============================================================================
# Execute
# ============================================================================



#region Nutanix Module Import
#----------------------------------------------------------------------------------------------------------------------------
$var_ModuleName = "Nutanix.LE"
Write-Host "$([char]0x1b)[96m[$([char]0x1b)[97m$(Get-Date)$([char]0x1b)[96m]$([char]0x1b)[97m INFO: Trying to import $var_ModuleName module"
try {
    Import-Module "$PSScriptRoot\$var_ModuleName.psd1" -Force -ErrorAction Stop
    Write-Log -Message "Successfully imported $var_ModuleName Module" -Level Info
}
catch {
    Write-Host "$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: Failed to import $var_ModuleName module. Exit script"
    Write-Host "$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: $_"
    Break #Temporary! Replace with #Exit 1
}
#endregion Nutanix Module Import

#region Validation
#----------------------------------------------------------------------------------------------------------------------------
Write-Log -Message "Configuration File is:        $($ConfigFile)" -Level Validation
Write-Log -Message "Report Configuration File is: $($ReportConfigFile)" -Level Validation
Write-Log -Message "Test Type is:                 $($Type)" -Level Validation
#endregion Validation

#region PowerShell Versions
#----------------------------------------------------------------------------------------------------------------------------
if ($PSVersionTable.PSVersion.Major -lt 5) { 
    Write-Log -Message "You must upgrade to PowerShell 5.x to run this script" -Level Warn
    Break #Temporary! Replace with #Exit 1
}

if ($PSVersionTable.PSVersion.Major -gt 6) { 
    Write-Log -Message "You cannot use PowerShell $($PSVersionTable.PSVersion.Major) with Citrix snapins. Please revert to PowerShell 5.x" -Level Warn
    Break #Temporary! Replace with #Exit 1
}
#endregion PowerShell Versions

##//TODO: Consider any other snapins - if only citrix, move the above check to the Citrix Type only.

#region Citrix Snapin Import
#----------------------------------------------------------------------------------------------------------------------------
if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
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

#region remove existing SSH Keys
#----------------------------------------------------------------------------------------------------------------------------
$Temp_Module = (Get-Module -ListAvailable *) | Where-Object { $_.Name -eq "Posh-SSH" }
if ($Null -ne $Temp_Module) {
    Write-Log -Message "Module Posh-SSH Found. Clearing existing SSH Keys if present" -Level Info
    Get-SSHTrustedHost | Remove-SSHTrustedHost
} 
else {
    Write-Log -Message "Failed to find Posh-SSH Module. Attempting to Install" -Level Info
    try {
        Install-Module -Name Posh-SSH -Force -ErrorAction Stop
        Write-Log -Message "Successfully installed Posh-SSH Module" -Level Info
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break #Temporary! Replace with #Exit 1
    }
}
$Temp_Module = $null
#endregion remove existing SSH Keys

#region variable setting
#----------------------------------------------------------------------------------------------------------------------------
Set-VSIConfigurationVariables -ConfigurationFile $ConfigFile

# Fix trailing slash issue
$VSI_LoginEnterprise_ApplianceURL = $VSI_LoginEnterprise_ApplianceURL.TrimEnd("/")
# Populates the $global:LE_URL
Connect-LEAppliance -Url $VSI_LoginEnterprise_ApplianceURL -Token $VSI_LoginEnterprise_ApplianceToken

#region Config File
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
$NTNXInfra = Get-NTNXinfo -Config $config
#endregion Get Nutanix Infra

#endregion variable setting

#region Handle Automated LE Settings Mapping - Check with Sven/Dave on how/what where we should store this info for reference - JSON or PowerShell root script/variables?
#----------------------------------------------------------------------------------------------------------------------------
$placeholder_var_LEAppliance = "LE1" #// This needs to be killed - is here for testing only, would likely live in JSON
if ($placeholder_var_LEAppliance -eq "LE1") {
    $config.LoginEnterprise.ApplianceURL = "https://WS-LE1.wsperf.nutanix.com"
    $config.LoginEnterprise.ApplianceToken = "pQYtAZu_o2JnVUqCZwoLvRAAai1zwfd3G8Na9yaNBrw"
    $config.Launchers.GroupName = "LE1-Launchers"
    $config.Launchers.NamingPattern = "LE1-202309-"
    $config.Users.BaseName = "VSILE1"
    $Config.Users.NumberOfDigits = "" #// Should this be a PowerShell set Variable rather than a JSON config? Is it every going to change?
}
if ($placeholder_var_LEAppliance -eq "LE2") {
    $config.LoginEnterprise.ApplianceURL = "https://WS-LE2.wsperf.nutanix.com"
    $config.LoginEnterprise.ApplianceToken = ""
    $config.Launchers.GroupName = "LE2-Launchers"
    $config.Launchers.NamingPattern = "LE2-202309-"
    $config.Users.BaseName = "VSILE2"
    $Config.Users.NumberOfDigits = "" #// Should this be a PowerShell set Variable rather than a JSON config? Is it every going to change?
}
#endregion Handle Automated LE Settings Mapping 

#region Validation
#----------------------------------------------------------------------------------------------------------------------------
##// Report Output here on relevent variables- Dave wants a Snazzy Header
foreach ($Item in $Config) {
    foreach ($SectionName in $Item.PSObject.Properties.Name) {
        Write-Log -Message "Section $sectionName contains the following defined values:" -Level Validation
        $properties = @()
        # Access the properties within each section
        foreach ($property in $Item.$sectionName.PSObject.Properties) {
            if ($null -ne $property.value -and $property.value -ne "") {
                $properties += [PSCustomObject]@{
                    Name  = $property.Name
                    Value = $property.Value
                }
            }
        }
        # Output properties in a tabular format
        [System.Console]::ForegroundColor = [System.ConsoleColor]::Cyan
        $properties | Format-Table -AutoSize -HideTableHeaders
        [System.Console]::ResetColor()
    }
} #// How to handle nested Array (ImagesToTest)

##// Write out a prompt here post validation work - make sure all is good before going
$answer = read-host "Test details correct for test? yes or no? "
if ($answer -ne "yes" -and $answer -ne "y") { 
    Write-Log -Message "Input not confirmed. Exit" -Level Info
    Break #Temporary! Replace with #Exit 0
}
else {
    Write-Log -Message "Input confirmed" -Level Info
}

#Nutanix Files Pre Flight Checks
if ($VSI_Target_Files -ne "") {
    Write-Log -Message "Validating Nutanix Files Authentication" -Level Info
    Invoke-NutanixFilesAuthCheck
}

#endregion Validation

#region Execute Test
#Set the multiplier for the Workloadtype. This adjusts the required MHz per user setting.
ForEach ($ImageToTest in $VSI_Target_ImagesToTest) {
    Set-VSIConfigurationVariables -ImageConfiguration $ImageToTest -ConfigurationFile $ConfigFile

    #region Setup testname
    Write-Log -Message "Setting up Test Details" -Level Info
    $NTNXid = (New-Guid).Guid.SubString(1,6)
    $NTNXTestname = "$($NTNXid)_$($VSI_Target_NodeCount)n_A$($NTNXInfra.Testinfra.AOSversion)_$($NTNXInfra.Testinfra.HypervisorType)_$($VSI_Target_NumberOfVMS)V_$($VSI_Target_NumberOfSessions)U_$LEWorkload"
    #endregion Setup testname

    #region Set affinity
    Set-TestData -ConfigFile $ConfigFile -TestName $NTNXTestname -RunNumber "N/A" -InfluxUri $NTNXInfra.TestInfra.InfluxDBurl -InfluxBucket $InfluxTestDashBucket -Status "Running" -CurrentPhase "1" -CurrentMessage "Setting Affinity"
    if ($VSI_Target_NodeCount -eq "1") {
        $NTNXInfra.Testinfra.SetAffinity = $true
    }
    else {
        $NTNXInfra.Testinfra.SetAffinity = $false
    }
    Write-Log -Message "Nutanix Host Affinity is set to: $($NTNXInfra.Testinfra.SetAffinity)" -Level Info
    #endregion Set affinity

    #region Validate Workload Profiles
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

    #region Handle AutoCalc
    If ($VSI_Target_AutocalcVMs) {
        If ($VSI_Target_Max) {
            $VSI_VSImax = 1
        }
        Else { $VSI_VSImax = 0.8 }
        $TotalCores = $NTNXInfra.Testinfra.CPUCores * $VSI_Target_NodeCount
        $TotalGHz = $TotalCores * $NTNXInfra.Testinfra.CPUSpeed * 1000
        $vCPUsperVM = $VSI_Target_NumCPUs * $VSI_Target_NumCores
        $GHzperVM = 600 * $WLmultiplier
        # Set the vCPU multiplier. This affects the number of VMs per node.
        $vCPUMultiplier = "1.$vCPUsperVM"
        #$TotalMem = [Math]::Round($NTNXInfra.Testinfra.MemoryGB * 0.92, 0, [MidpointRounding]::AwayFromZero) * $VSI_Target_NodeCount
        $TotalMem = $VSI_Target_NodeCount * (($($NTNXInfra.Testinfra.MemoryGB) - 32) * 0.94)
        $MemperVM = $VSI_Target_MemoryGB
        if ($($VSI_Target_SessionsSupport.ToLower()) -notin $Validated_OS_Types) {
            Write-Log -Message "OS Type is: $($VSI_Target_SessionsSupport) and is not a valid type for testing. Please check config file" -Level Error
        }
        if ($($VSI_Target_SessionsSupport.ToLower()) -eq "multisession") {
            $VSI_Target_NumberOfVMS = [Math]::Round(($TotalCores - (4 * $VSI_Target_NodeCount)) / $vCPUsperVM * 2, 0, [MidpointRounding]::AwayFromZero)
            $VSI_Target_PowerOnVMs = $VSI_Target_NumberOfVMS
            if ($TotalMem -le ($VSI_Target_NumberOfVMS * $MemperVM)) {
                $VSI_Target_NumberOfVMS = [Math]::Round($TotalMem / $MemperVM, 0, [MidpointRounding]::AwayFromZero)
                $VSI_Target_PowerOnVMs = $VSI_Target_NumberOfVMS
            }
            $RDSHperVM = [Math]::Round(18 / $WLmultiplier, 0, [MidpointRounding]::AwayFromZero)
            $VSI_Target_NumberOfSessions = [Math]::Round($VSI_Target_NumberOfVMS * $RDSHperVM * $VSI_VSImax, 0, [MidpointRounding]::AwayFromZero)
        }
        if ($($VSI_Target_SessionsSupport.ToLower()) -eq "singlesession") {
            $VSI_Target_NumberOfVMS = [Math]::Round(($TotalGHz / ($GHzperVM * $vCPUMultiplier) * $VSI_VSImax), 0, [MidpointRounding]::AwayFromZero)
            $VSI_Target_PowerOnVMs = $VSI_Target_NumberOfVMS
            if ($TotalMem -le ($VSI_Target_NumberOfVMS * $MemperVM)) {
                $VSI_Target_NumberOfVMS = [Math]::Round($TotalMem / $MemperVM, 0, [MidpointRounding]::AwayFromZero)
                $VSI_Target_PowerOnVMs = $VSI_Target_NumberOfVMS
            }
            $VSI_Target_NumberOfSessions = $VSI_Target_NumberOfVMS
        }
        ($NTNXInfra.Target.ImagesToTest | Where-Object { $_.Comment -eq $VSI_Target_Comment }).NumberOfVMs = $VSI_Target_NumberOfVMS
        ($NTNXInfra.Target.ImagesToTest | Where-Object { $_.Comment -eq $VSI_Target_Comment }).PowerOnVMs = $VSI_Target_PowerOnVMs
        ($NTNXInfra.Target.ImagesToTest | Where-Object { $_.Comment -eq $VSI_Target_Comment }).NumberOfSessions = $VSI_Target_NumberOfSessions
        Write-Log -Message "AutoCalc is enabled and the number of VMs is set to $VSI_Target_NumberOfVMS and the number of sessions to $VSI_Target_NumberOfSessions on $VSI_Target_NodeCount Node(s)" -Level Info
    }
    #endregion Handle AutoCalc

    $NTNXInfra.Target.ImagesToTest = $ImageToTest

    #region Slack update
    Write-Log -Message "Updating Slack" -Level Info
    $SlackMessage = "New Login Enterprise test started by $VSI_Target_CVM_admin on Cluster $($NTNXInfra.TestInfra.ClusterName). Testname: $($NTNXTestname)."
    Update-VSISlack -Message $SlackMessage -Slack $($NTNXInfra.Testinfra.Slack)
    #endregion Slack update

    #region Citrix validation
    if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
        Write-Log -Message "Validating Citrix" -Level Info
        Connect-VSICTX -DDC $VSI_Target_DDC
    }
    #endregion Citrix validation

    #region LE Test Check
    Write-Log -Message "Polling LE for tests" -Level Info
    $Test = Get-LETests | Where-Object { $_.name -eq $VSI_Test_Name }
    Wait-LeTest -testId $Test.Id
    #endregion LE Test Check

    #region LE Users
    if (-not ($SkipLEUsers)) {
        # Create the accounts and accountgroup in LE
        Write-Log -Message "Creating Accounts and Groups in LE" -Level Info
        $LEaccounts = New-LEAccounts -Username $VSI_Users_BaseName -Password $VSI_Users_Password -Domain $VSI_Users_NetBios -NumberOfDigits $VSI_Users_NumberOfDigits -NumberOfAccounts $VSI_Target_NumberOfSessions
        New-LEAccountGroup -Name $VSI_Users_GroupName -Description "Created by automation toolkit" -MemberIds $LEaccounts | Out-Null
    }
    #endregion LE Users

    #region AD Users
    if (-not ($SkipADUsers)) {
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
        } else {
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

    #region Iterate through runs
    for ($i = 1; $i -le $VSI_Target_ImageIterations; $i++) {
        # Will only create the pool if it does not exist
        
        #region Update Slack
        $SlackMessage = "Testname: $($NTNXTestname) Run$i is started by $VSI_Target_CVM_admin on Cluster $($NTNXInfra.TestInfra.ClusterName)."
        Update-VSISlack -Message $SlackMessage -Slack $($NTNXInfra.Testinfra.Slack)

        $ContainerId = Get-NTNXStorageUUID -Storage $VSI_Target_CVM_storage
        $Hostuuid = Get-NTNXHostUUID -NTNXHost $VSI_Target_NTNXHost
        $IPMI_ip = Get-NTNXHostIPMI -NTNXHost $VSI_Target_NTNXHost
        if ($Mode -eq "CitrixVAD" -or $Mode -eq "CitrixDaaS") {
            ## Placeholder Block to capture the relevent settings below - will change with different tech
        }
        $networkMap = @{ "0" = "XDHyp:\HostingUnits\" + $VSI_Target_HypervisorConnection +"\"+ $VSI_Target_HypervisorNetwork +".network" }
        $ParentVM = "XDHyp:\HostingUnits\$VSI_Target_HypervisorConnection\$VSI_Target_ParentVM"
        #endregion Update Slack

        #region Configure Citrix Desktop Pool
        if ($Mode -eq "CitrixVAD" -or $Mode -eq "CitrixDaaS") {
            ## Placeholder Block to capture the relevent settings below - will change with different tech
        }
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

        if ($Mode -eq "Horizon") { #Need to check with Sven here - which config do we use Horizon-NTNX.ps1 or NorizonView.Ps1?
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

        #endregion Configure Citrix Desktop Pool

        #region Configure Folder Details for output
        $FolderName = "$($NTNXTestname)_Run$($i)"
        $OutputFolder = "$ScriptRoot\results\$FolderName"
        #endregion Configure Folder Details for output

        #region Start monitoring Boot phase
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

        if ($Mode -eq "CitrixVAD" -or $Mode -eq "CitrixDaaS") {
            #Placeholder block to capture the below settings
        }
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
        }
        $Boot = Enable-VSICTXDesktopPool @params

        $Params = $null

        if ($Mode -eq "Horizon") { # Need to check with Sven on this
            if ($VSI_Target_PoolType -eq "RDSH") {
                $Boot = Enable-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName -VMAmount $VSI_Target_NumberOfVMs -Increment $VSI_Target_VMPoolIncrement -RDSH
            } elseif ($VSI_Target_ProvisioningMode -eq "AllMachinesUpFront") {
                $Boot = Enable-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName -VMAmount $VSI_Target_NumberOfVMs -Increment $VSI_Target_VMPoolIncrement -AllMachinesUpFront
            } else {
                $Boot = Enable-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName -VMAmount $VSI_Target_NumberOfVMs -NumberOfSpareVMs $VSI_Target_NumberOfSpareVMs
            }
        }

        $NTNXInfra.Testinfra.BootStart = $Boot.bootstart
        $NTNXInfra.Testinfra.Boottime = $Boot.boottime
        #endregion Start monitoring Boot phase

        #region Get Build Tattoo Information and update variable with new values
        if ($Mode -eq "CitrixVAD" -or $Mode -eq "CitrixDaaS") {
            ## Placeholder Block to capture the relevent settings below - will change with different tech
        }
        $BrokerVMs = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $VSI_Target_DesktopPoolName -MaxRecordCount $MaxRecordCount
        $RegisteredVMs = ($BrokerVMS | Where-Object { $_.RegistrationState -eq "Registered" })
        $MasterImageDNS = $RegisteredVMs[0].DNSName
        try {
            $Tattoo = Invoke-Command -Computer $MasterImageDNS { Get-ItemProperty HKLM:\Software\BuildTatoo } -ErrorAction Stop 
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break #Temporary! Replace with #Exit 1
        }
        $NTNXInfra.Target.ImagesToTest.TargetOS = $Tattoo.OSName
        $NTNXInfra.Target.ImagesToTest.TargetOSVersion = $Tattoo.OSVersion
        $NTNXInfra.Target.ImagesToTest.OfficeVersion = $Tattoo.OfficeName
        $NTNXInfra.Target.ImagesToTest.ToolsGuestVersion = $Tattoo.GuestToolsVersion
        $NTNXInfra.Target.ImagesToTest.OptimizerVendor = $Tattoo.Optimizer
        $NTNXInfra.Target.ImagesToTest.OptimizationsVersion = $Tattoo.OptimizerVersion
        $NTNXInfra.Target.ImagesToTest.DesktopBrokerAgentVersion = $Tattoo.VdaVersion
        #endregion Get Build Tattoo Information and update variable with new values

        #region Set number of sessions per launcher
        if ($($VSI_Target_SessionCfg.ToLower()) -eq "ica") {
            $SessionsperLauncher = 20
        } else {
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
        if ($Mode -eq "CitrixVAD" -or $Mode -eq "CitrixDaaS") {
            ## Placeholder Block to capture the relevent settings below - will change with different tech
        }
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
        #endregion Update the test params/create test if not exist

        #region Wait for VM's to have settled down
        if (-not ($SkipWaitForIdleVMs)) {
            Write-Log -Message "Waiting 60 seconds for VMs to become idle" -Level Info
            Start-Sleep -Seconds 60
        }
        #endregion Wait for VM's to have settled down

        #region Stop and cleanup monitoring job Boot phase
        $monitoringJob | Stop-Job | Remove-Job
        #endregion Stop and cleanup monitoring job Boot phase

        #region Set RDA Source and Destination files and clean out source files if they still exist
        $RDADestination = "$OutputFolder\RDA.csv"
        $RDASource = Join-Path -Path "$($NTNXInfra.TestInfra.RDAPath)" -ChildPath "$($VSI_Users_BaseName)0001.csv"
        if(Test-Path -Path $RDASource){
            Write-Log -Message "Removing RDA Source File $($RDASource)" -Level Info
            Remove-Item -Path $RDASource -ErrorAction SilentlyContinue
        } else {
            Write-Log -Message "RDA Source File $($RDASource) does not exist" -Level Info
        }
        #endregion Set RDA Source and Destination files and clean out source files if they still exist

        #region VM Idle state
        Write-Log -Message "Waiting for $VSI_Target_MinutesToWaitAfterIdleVMs minutes before starting test" -Level Info
        Start-sleep -Seconds $($VSI_Target_MinutesToWaitAfterIdleVMs * 60)
        #endregion VM Idle state

        #region Nutanix Curator Stop
        Set-NTNXcurator -ClusterIP $NTNXInfra.Target.CVM -CVMSSHPassword $NTNXInfra.Target.CVMsshpassword -Action "stop"
        #endregion Nutanix Curator Stop

        #region Start the test
        Start-LETest -testId $testId -Comment "$FolderName-$VSI_Target_Comment"
        $TestRun = Get-LETestRuns -testId $testId | Select-Object -Last 1
        #endregion Start the test

        #region Start monitoring
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
        Wait-LETest -testId $testId
        #endregion Wait for test to finish

        #region Cleanup monitoring job
        $monitoringJob | Wait-Job | Remove-Job
        if ($VSI_Target_Files -ne "") {
            $monitoringFilesJob | Wait-Job | Remove-Job
        }
        if ($VSI_Target_NetScaler -ne "") {
            $monitoringNSJob | Wait-Job | Remove-Job
        }
        #endregion Cleanup monitoring job

        #region Nutanix Curator Start
        Set-NTNXcurator -ClusterIP $NTNXInfra.Target.CVM -CVMSSHPassword $NTNXInfra.Target.CVMsshpassword -Action "start"
        #endregion Nutanix Curator Start

        #region Write config to OutputFolder
        $NTNXInfra.Testinfra.VMCPUCount = [Int]$VSI_Target_NumCPUs * [Int]$VSI_Target_NumCores
        $NTNXInfra.Testinfra.Testname = $FolderName
        $NTNXInfra | ConvertTo-Json -Depth 20 | Set-Content -Path $OutputFolder\Testconfig.json -Force
        Write-Log -Message "Exporting LE Measurements to output folder" -Level Info
        Export-LEMeasurements -Folder $OutputFolder -TestRun $TestRun -DurationInMinutes $VSI_Target_DurationInMinutes
        #endregion Write config to OutputFolder

        #region Check for RDA File and if exists then move it to the output folder
        if(Test-Path -Path $RDASource){
            $csvData = get-content $RDASource | ConvertFrom-String -Delimiter "," -PropertyNames Timestamp,screenResolutionid,encoderid,movingImageCompressionConfigurationid,preferredColorDepthid,videoCodecid,VideoCodecUseid,VideoCodecTextOptimizationid,VideoCodecColorspaceid,VideoCodecTypeid,HardwareEncodeEnabledid,VisualQualityid,FramesperSecondid,RDHSMaxFPS,currentCPU,currentRAM,totalCPU,currentFps,totalFps,currentRTT,NetworkLatency,NetworkLoss,CurrentBandwidthEDT,totalBandwidthusageEDT,averageBandwidthusageEDT,currentavailableEDTBandwidth,EDTInUseId,currentBandwithoutput,currentLatency,currentavailableBandwidth,totalBandwidthusage,averageBandwidthUsage,averageBandwidthAvailable,GPUusage,GPUmemoryusage,GPUmemoryInUse,GPUvideoEncoderusage,GPUvideoDecoderusage,GPUtotalUsage,GPUVideoEncoderSessions,GPUVideoEncoderAverageFPS,GPUVideoEncoderLatency | Select -Skip 1
            $csvData | Export-Csv -Path $RDADestination -NoTypeInformation
            Remove-Item -Path $RDASource -ErrorAction SilentlyContinue
        }
        #endregion Check for RDA File and if exists then move it to the output folder

        #region Upload Data to Influx

        $CurrentPhase = "15"
        
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
                    $null = Set-TestData -ConfigFile "$($OutputFolder)\Testconfig.json" -TestName $($NTNXInfra.TestInfra.TestName) -RunNumber $Run -InfluxUri $NTNXInfra.TestInfra.InfluxDBurl -InfluxBucket "Tests" -Status "Running" -CurrentPhase $CurrentPhase -CurrentMessage "Uploading Boot File $($File.name) to Influx"
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
                    $UploadResult = Start-InfluxUpload -influxDbUrl $NTNXInfra.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $NTNXInfra.Testinfra.InfluxToken -File $File -Started $Started -BucketName $BucketName
                    if ($UploadResult.Return -eq $true) {
                        Write-Log -Message "Finished uploading File $($File.Name) to Influx" -Level Info -Update
                        $UploadStatus = "Finished"
                    }
                    else {
                        if ($UploadResult.TagValidated -eq $false) {
                            Write-Log -Message "Error with empty tag value - check json test result file" -Level Warn
                            $UploadStatus = "Empty Tag Value"
                        }
                        else {
                            Write-Log -Message "Error uploading $($File.name) to Influx" -Level Warn
                            $UploadStatus = "Errored"
                        }
                    }
                }
                else {
                    Write-Log -Message "Skipped uploading File $($File.Name) to Influx" -Level Info
                }
                $null = Set-TestData -ConfigFile "$($OutputFolder)\Testconfig.json" -TestName $($NTNXInfra.TestInfra.TestName) -RunNumber $Run -InfluxUri $NTNXInfra.TestInfra.InfluxDBurl -InfluxBucket "Tests" -Status "Running" -CurrentPhase $CurrentPhase -CurrentMessage "Uploading $($File.name) to Influx - Status: $($UploadStatus)"
            }

        }
        else {
            Write-Log -Message "Skipping uploading Test Run Data to Influx" -Level Info
        }

        $null = Set-TestData -ConfigFile "$($OutputFolder)\Testconfig.json" -TestName $($NTNXInfra.TestInfra.TestName) -RunNumber $Run -InfluxUri $NTNXInfra.TestInfra.InfluxDBurl -InfluxBucket "Tests" -Status "Running" -CurrentPhase $CurrentPhase -CurrentMessage "Finished Region - Upload Data to Influx"

        #endregion Upload Data to Influx

        $Testresult = import-csv "$OutputFolder\VSI-results.csv"
        $Appsuccessrate = $Testresult."Apps success"/$Testresult."Apps total" *100

        #region Slack update
        $SlackMessage = "Testname: $($NTNXTestname) Run $i is finished on Cluster $($NTNXInfra.TestInfra.ClusterName). $($Testresult.activesessionCount) sessions active of $($Testresult."login total") total sessions. EUXscore: $($Testresult."EUX score") - VSImax: $($Testresult.vsiMax). App Success rate: $($Appsuccessrate.tostring("#.###"))"
        Update-VSISlack -Message $SlackMessage -Slack $($NTNXInfra.Testinfra.Slack)

        $FileName = Get-VSIGraphs -TestConfig $NTNXInfra -OutputFolder $OutputFolder -RunNumber $i -TestName $NTNXTestname

        if(Test-Path -path $Filename) {
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
        #endregion Slack update

    }
    #endregion Iterate through runs

    $Region = 11
    #region Analyze Run results
    Get-VSIResults -TestName $NTNXTestname -Path $ScriptRoot
    #endregion Analyze Run results

    $Region = 12
    #region Slack update
    Update-VSISlackresults -TestName $NTNXTestname -Path $ScriptRoot
    $OutputFolder = "$($ScriptRoot)\testresults\$($NTNXTestname)"
    $FileName = Get-VSIGraphs -TestConfig $NTNXInfra -OutputFolder $OutputFolder -TestName $NTNXTestname
    if(Test-Path -path $Filename) {
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
    #endregion Slack update
}
#endregion Execute Test

#endregion Execute

Write-Log -Message "Script Finished" -Level Info
Break #Temporary! Replace with #Exit 0