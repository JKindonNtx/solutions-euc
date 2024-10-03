<##
.SYNOPSIS
.DESCRIPTION
.PARAMETER ConfigFile
Mandatory. The JSON file containing the test configuration
.PARAMETER ReportConfigFile
Mandatory.
.PARAMETER Type
Mandatory. Specify the type of test to be run, CitrixVAD, CitrixDaaS, Horizon, RAS, RDP
.PARAMETER LEConfigFile
Mandatory. Config file that holds the Login Enterprise Appliance Information.
.PARAMETER SkipWaitForIdleVMs
Configured in the test configuration file. Can be overriden by this parameter. Do not wait for VM's to become Idle before starting test.
.PARAMETER SkipADUsers
Configured in the test configuration file. Can be overriden by this parameter. Do not recreate the Active Directory user accounts.
.PARAMETER SkipLEUsers
Configured in the test configuration file. Can be overriden by this parameter. Do not recreate the Login Enterprise accounts.
.PARAMETER SkipLaunchers
Configured in the test configuration file. Can be overriden by this parameter.
.PARAMETER LEAppliance
Configured in the test configuration file. Can be overriden by this parameter. The Login Enterprise Appliance. LE1, LE2, LE3, LE4 etc.
.PARAMETER SkipPDFExport
Configured in the test configuration file. Can be overriden by this parameter.
.PARAMETER Force
Optional. Forces the recreation of the Horizon desktop pool.
.PARAMETER ValidateOnly
.Optional Allows the ability to Validate without and exectution of testing.
.PARAMETER AzureMode
.Optional. Ignores Nutanix Considerations.
.NOTES
#---------- 
# Variables and Config object Map

| Config Object | Description |
| :--- | :--- |
| $Config | The JSON object that holds the test configuration. Use this as the primary source of static information. This is imported from our test configurations and cleansed. |
| $NTNXInfra | The JSON object that holds the Nutanix Infrastructure details. Pulls data directly from Nutanix and updates items set to $null in the original $Config object |

| Variable Prefix | Description |
| :--- | :--- |
| $VSI_* | Used to specify VSI specific variables - for test configurations etc. at the LE layer. Pulled from the $Config Object |
| $ImageSpec_* | Used for image specific variables. Set at the beginning of each run. Pulled from the $Config.Target.ImagesToTest Array |

#----------
#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigFile = "C:\DevOps\solutions-euc\engineering\login-enterprise\ExampleConfig-Test-Template.jsonc",

    [Parameter(Mandatory = $true)]
    [string]$LEConfigFile = "C:\DevOps\solutions-euc\engineering\login-enterprise\ExampleConfig-LoginEnterpriseGlobal.jsonc",

    [Parameter(Mandatory = $true)]
    [ValidateSet("CitrixVAD", "CitrixDaaS", "Horizon", "RAS", "RDP", "Omnissa")]
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
    [String]$LEAppliance,
    
    [Parameter(Mandatory = $false)]
    [switch]$ValidateOnly,

    [Parameter(Mandatory = $false)]
    [switch]$AzureMode

)
#endregion Params

##Testing
#$ConfigFile = "C:\DevOps\solutions-euc\engineering\login-enterprise\Config-W11-PVS-AMD-AHV-BPG-DIAG.jsonc"
#$LEConfigFile = "C:\DevOps\solutions-euc\engineering\login-enterprise\Config-LoginEnterpriseGlobal.jsonc"
#$Type = "CitrixVAD"
##Testing

#region Variables
# ============================================================================
# Variables
# ============================================================================

If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }

#endregion Variables

#Region Execute
# ============================================================================
# Execute
# ============================================================================

# Set a global variable to track the last message output to the console in an attempt to keep console output clean with write-log function.
$global:LastMessageEndedWithNewLine = $false
# Set a gloval variable for the temp log file. This is used to log all output to a file via the Write-Log function. The file will be created if it does not exist and moved at the end of the test. It will be renamed if it does exist.
$global:LogOutputTempFile = "$env:LOCALAPPDATA\SolutionsEngineering\TestLogs\Test.log"
if (Test-Path $global:LogOutputTempFile) { Rename-Item -Path $global:LogOutputTempFile -NewName "$global:LogOutputTempFile.$((Get-Date).ToString('yyyyMMdd-HHmmss'))" -Force }

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
    Exit 1
}
#endregion Nutanix Module Import

#region Param Output
#----------------------------------------------------------------------------------------------------------------------------
Write-Log -Message "Configuration File is:        $($ConfigFile)" -Level Validation
Write-Log -Message "LE Configuration File is:     $($LEConfigFile)" -Level Validation
Write-Log -Message "Test Type is:                 $($Type)" -Level Validation
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
                    Exit 1
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
                Exit 1
            }
            
        }
        else {
            Write-Log -Message "Module: VMware.Hv.Helper not Found" -Level Error
            Exit 1
        }
    }
    catch {
        Write-Log -Message "Failed to Import Modules" -Level Error
        Write-Log -Message $_ -Level Info
        Exit 1
    }
}
#endregion VMWare Module Import

#region remove existing SSH Keys 
#----------------------------------------------------------------------------------------------------------------------------
if (-not $AzureMode.IsPresent) {
    # This is not an Azure configuration
    Write-Log -Message "Searching all modules for Posh-SSH" -Level Info
    $Temp_Module = (Get-Module -ListAvailable *) | Where-Object { $_.Name -eq "Posh-SSH" }

    if ($Null -ne $Temp_Module -and $Temp_Module.Version -contains "2.3.0") {
        Write-Log -Message "Module Posh-SSH Found. Clearing existing SSH Keys if present" -Level Info
        Get-SSHTrustedHost | Remove-SSHTrustedHost
    } 
    else {
        Write-Log -Message "Failed to find appropriate Posh-SSH Module. Attempting to Install" -Level Info
        try {
            Install-Module -Name Posh-SSH -RequiredVersion 2.3.0 -Force -Scope CurrentUser -ErrorAction Stop
            Write-Log -Message "Successfully installed Posh-SSH Module" -Level Info
            Get-SSHTrustedHost | Remove-SSHTrustedHost
        }
        catch {
            Write-Log -Message $_ -Level Error
            Exit 1
        }
    }
    $Temp_Module = $null
}
#endregion remove existing SSH Keys

#region Validate JSON

if (Get-ValidJSON -ConfigFile $ConfigFile -Type $Type) {
    Write-Log -Message "Config file $($ConfigFile) has been validated for appropriate value selection" -Level Info
} 
else {
    Write-Log -Message "Config File $($ConfigFile) contains invalid options. Please review logfile and configfile." -Level Warn
    Exit 1
}

#endregion Validate JSON

#region variable setting
#----------------------------------------------------------------------------------------------------------------------------
Set-VSIConfigurationVariables -ConfigurationFile $ConfigFile
#endregion variable setting

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

#region LE Appliance

#Define the LE appliance detail
if ($Config.Test.LEAppliance -eq "MANDATORY_TO_DEFINE" -and (!$LEAppliance)) {
    # Neither Option is OK due to ValidateSet on the LEAppliance Param
    Write-Log -Message "You must define an LE appliance either in the $($ConfigFile) file or via the Script Parameter" -Level Error
    Exit 1
} 
elseif ($Config.Test.LEAppliance -eq "MANDATORY_TO_DEFINE" -and $LEAppliance) {
    #Set LEAppliance based on Param
    $LEAppliance = $LEAppliance
} 
else {
    #Use the valid value from the Config JSON
    $LEAppliance = $Config.Test.LEAppliance
}

if ($null -ne $LEAppliance) {
    Set-VSIConfigurationVariablesLEGlobal -ConfigurationFile $LEConfigFile -LEAppliance $LEAppliance
}
else {
    Write-Log -Message "Missing LE Appliance Detail. Please check config file." -Level Warn
    Exit 1
}

# Fix trailing slash issue
$VSI_LoginEnterprise_ApplianceURL = $VSI_LoginEnterprise_ApplianceURL.TrimEnd("/")

Connect-LEAppliance -Url $VSI_LoginEnterprise_ApplianceURL -Token $VSI_LoginEnterprise_ApplianceToken

#endregion LE Appliance

#region Observer validation
if (-not $AzureMode.IsPresent) {
    # This is not an Azure configuration
        if ($Config.Test.StartObserverMonitoring -eq $true -or $Config.Target.files_prometheus -eq $true) {
        #Test to see if the variable exists or not
        if ($null -eq $VSI_Prometheus_IP -or $null -eq $VSI_Prometheus_sshuser -or $null -eq $VSI_Prometheus_sshpassword) {
            Write-Log -Message "You must define the Prometheus IP, SSH User and SSH Password to enable Observer Monitoring in the LoginEnterpriseGlobal.jsonc file" -Level Error
            Exit 1
        }
    }
}
#endregion Observer validation

#region Advanced Diagnostics - perf_collect - validation
if (-not $AzureMode.IsPresent) {
    #This is not an Azure test
    if ($Config.psobject.Properties.Name -contains "AdvancedDiagnostics") {
        if ($Config.AdvancedDiagnostics.EnableCollectPerf -eq $true) {
            # Download the file using Receive-WinSCPItem. Must use the 6.3.2.0 version of the WinSCP module - nothing newer
            $requiredVersion = [version]"6.3.2.0"
            if ((Get-Module -ListAvailable -Name WinSCP).version -gt $requiredVersion) {
                Write-Log -Message "WinSCP module version is newer than the required version. Downloading of data file will not be possible." -Level Warn
            } else {
                # Check if WinSCP module is installed
                if (-not (Get-Module -ListAvailable -Name WinSCP | Where-Object { $_.Version -eq $requiredVersion })) {
                    Write-Log -Message "WinSCP module not found. Installing WinSCP module." -Level Info
                    try {
                        Install-Module -Name WinSCP -Force -RequiredVersion $requiredVersion -ErrorAction Stop
                        Import-Module -Name WinSCP -RequiredVersion $requiredVersion -Force -ErrorAction Stop
                    }
                    catch {
                        Write-Log -Message "Failed to install correct WinSCP module. Download of collect_perf output will fail." -Level Warn
                    }
                }
            }
        }
    }
}
#endregion Advanced Diagnostics - perf_collect - validation

#region data download and upload validation

if ($Config.Test.SkipLEMetricsDownload -eq $true -and $Config.Test.Uploadresults -eq $true) {
    #You can't skip a download and enable an upload
    Write-Log -Message "You cannot skip LE metric download (SkipLEMetricsDownload) and enable Influx upload (Uploadresults). This is not a valid test configuration." -Level Error
    Exit 1
}
if ($Config.Test.Uploadresults -eq $false) { 
    #You can't skip a download and enable an upload
    Write-Log -Message "You are executing a test with no Influx Data upload (Uploadresults: false). There will be no grafana or influx reporting for this test." -Level Info
    $answer = read-host "Test details correct for test? yes or no?"
    if ($answer -ne "yes" -and $answer -ne "y") { 
        Write-Log -Message "Input not confirmed. Exit" -Level Info
        Exit 0
    }
    else {
        Write-Log -Message "Input confirmed" -Level Info
    }
}
#endregion data download and upload validation

#region Get Nutanix Infra
#----------------------------------------------------------------------------------------------------------------------------
if (-not $AzureMode.IsPresent) {
    # This is not an Azure configuration
    $NTNXInfra = Get-NTNXinfo -Config $config
    $HostCVMIPs = Get-NTNXCVMIPs -Config $config
    $HostIPs = Get-NTNXHostIPs -Config $config
    if ($Config.Target.Files -ne "") {
        Write-Log -Message "Getting Nutanix Files Info" -Level Info
        $NTNXInfra = Get-NTNXFilesinfo -Config $NTNXInfra
    }
} else {
    $NTNXInfra = $config
}

#endregion Get Nutanix Infra

#region Citrix Snapin Import
#----------------------------------------------------------------------------------------------------------------------------
if (($Type -eq "CitrixVAD") -or ($Type -eq "CitrixDaaS")) {
    if ($Config.Target.OrchestrationMethod -eq "Snapin") {
        if ($PSVersionTable.PSVersion.Major -gt 6) { 
            Write-Log -Message "You cannot use PowerShell $($PSVersionTable.PSVersion.Major) with Citrix snapins. Please revert to PowerShell 5.x" -Level Warn
            Exit 1
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
            Exit 1
        }
    }
    elseif ($Config.Target.OrchestrationMethod -eq "API") {
        Write-Log -Message "Executing Citrix Orchestration using API method" -Level Info
    }
    else {
        Write-Log -Message "Invalid option specified for Orchestration Method. You must define either API or Snapin" -Level Warn
        Exit 1
    }
}
#endregion Citrix Snapin Import

#region Script behaviour from file (params)
#----------------------------------------------------------------------------------------------------------------------------

## Allow the script to override JSON values via parameter
if ($SkipADUsers.IsPresent) { $SkipADUsers = $true } else { $SkipADUsers = $Config.Test.SkipADUsers }
if ($SkipLEUsers.IsPresent) { $SkipLEUsers = $true } else { $SkipLEUsers = $Config.Test.SkipLEUsers }
if ($SkipLaunchers.IsPresent) { $SkipLaunchers = $true } else { $SkipLaunchers = $Config.Test.SkipLaunchers }
if ($SkipPDFExport.IsPresent) { $SkipPDFExport = $true } else { $SkipPDFExport = $Config.Test.SkipPDFExport }
if ($SkipWaitForIdleVMs.IsPresent) { $SkipWaitForIdleVMs = $true } else { $SkipWaitForIdleVMs = $Config.Test.SkipWaitForIdleVMs }

#$VSI_Target_RampupInMinutes = $Config.Test.Target_RampupInMinutes #Might not be needed now
$InfluxTestDashBucket = $Config.Test.InfluxTestDashBucket # Used for neatness later on.

if ($Type -eq "CitrixVAD" -or "CitrixDaaS"){
    if ($Config.Target.OrchestrationMethod -eq "Snapin"){
        $Global:MaxRecordCount = $Config.Target.MaxRecordCount
    }
    $Global:DDC = $Config.Target.DDC
}

#endregion Script behaviour from file (params)

#region Validation
#----------------------------------------------------------------------------------------------------------------------------

#region Mandatory JSON Value Output
$Mandatory_Undedfined_Config_Entries = Get-Variable -Name VSI* | where-Object {$_.Value -match "MANDATORY_TO_DEFINE"}
##//JK: Check for Mandatory Undefined Values with the new Variable names!

if ($null -ne $Mandatory_Undedfined_Config_Entries) {
    Write-Log -Message "There are $(($Mandatory_Undedfined_Config_Entries | Measure-Object).Count) Undefined values that must be specified" -Level Warn
    foreach ($Item in $Mandatory_Undedfined_Config_Entries) {
        Write-Log -Message "Setting: $($Item.Name) must be set. Current value: $($Item.Value)" -Level Warn
    }
}

if (($Mandatory_Undedfined_Config_Entries | Measure-Object).Count -gt 0) {
    ##// Write out a prompt here post validation work - make sure all is good before going
    $answer = read-host "Test details correct for test? yes (y) or no? "
    if ($answer -ne "yes" -and $answer -ne "y") { 
        Write-Log -Message "Input not confirmed. Exit" -Level Info
        Exit 0
    }
    else {
        Write-Log -Message "Input confirmed" -Level Info
    }
}

if ($Type -eq "RDP") {
    if ([string]::IsNullOrEmpty[$Config.Target.RDP_Hosts]) {
        Write-Log -Message "Test type is RDP. You must define the RDP Hosts in the JSON File" -Level Warn
        Exit 1
    }
    else {
        Write-Log -Message "There are $(($Config.Target.RDP_Hosts | Measure-Object).Count) RDP Hosts defined for test configuration" -Level Info
    }

    if ([string]::IsNullOrEmpty[$Config.Domain.LDAPUsername] -or [string]::IsNullOrEmpty[$Config.Domain.LDAPPassword]) {
        Write-Log -Message "Test type is RDP. You must define an LDAP Username and Password to be able to execute tasks against the remote Hosts." -Level Warn
        Exit 1
    }
}
#endregion Mandatory JSON Value Output

#region Nutanix Files Pre Flight Checks
#----------------------------------------------------------------------------------------------------------------------------
if ($Config.Target.Files -ne "") {
    Write-Log -Message "Validating Nutanix Files Authentication" -Level Info
    
    Invoke-NutanixFilesAuthCheck

    if ($null -ne $Config.Test.Nutanix_Files_Shares -and $Config.Test.Delete_Files_Data -eq $true) {
        ##TODO Need to validate this
        Write-Log -Message "Processing Nutanix Files Data Removal Validation" -Level Info
        Remove-NutanixFilesData -Shares $Config.Test.Nutanix_Files_Shares -Mode Validate
    }
}
#endregion Nutanix Files Pre Flight Checks

#region Citrix API Authentication Setup
if ($Type -eq "CitrixVAD" -or "CitrixDaaS"){
    if ($Config.Target.OrchestrationMethod -eq "API") {
        if ([string]::IsNullOrEmpty[$Config.Domain.LDAPUsername] -or [string]::IsNullOrEmpty[$Config.Domain.LDAPPassword]) {
            Write-Log -Message "You must define an LDAP Username and Password to be able to execute tasks using the API method" -Level Warn
            Exit 1
        }
        if ($Type -eq "CitrixVAD"){
            # Convert Username and Password to base64. This is used to talk to Citrix API
            $AdminCredential = "$($Config.Domain.LDAPUsername):$($Config.Domain.LDAPPassword)"
            $Bytes = [System.Text.Encoding]::UTF8.GetBytes($AdminCredential)
            $Global:EncodedAdminCredential = [Convert]::ToBase64String($Bytes)
        }
        elseif ($Type -eq "CitrixDaaS"){
            $Global:CustomerID = $Config.CitrixDaaS.CustomerID
            $Global:ClientID = $Config.CitrixDaaS.ClientID
            $Global:ClientSecret = $Config.CitrixDaaS.ClientSecret
            $Global:Region = $Config.CitrixDaaS.Region
            #------------------------------------------------------------
            # Set Cloud API URL based on Region
            #------------------------------------------------------------
            switch ($Global:Region) {
                'AP-S' { 
                    $Global:CloudUrl = "api-ap-s.cloud.com"
                }
                'EU' {
                    $Global:CloudUrl = "api-eu.cloud.com"
                }
                'US' {
                    $Global:CloudUrl = "api-us.cloud.com"
                }
                'JP' {
                    $Global:CloudUrl = "api.citrixcloud.jp"
                }
            }
        }
        # Convert Username and Password to base64. This is used for Active Directory Operations. 
        # Currently the same username and password as the Citrix Auth account. Sent in API headers.
        $DomainAdminCredential = "$($Config.Domain.LDAPUsername):$($Config.Domain.LDAPPassword)"
        $Bytes = [System.Text.Encoding]::UTF8.GetBytes($DomainAdminCredential)
        $Global:DomainAdminCredential = [Convert]::ToBase64String($Bytes)
    }
}
#endregion Citrix API Authentication Setup

#region Citrix Site Access Pre Flight Checks
if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
    if ($Config.Target.OrchestrationMethod -eq "Snapin") {
        Write-Log -Message "Handling Citrix Credentials and Validating Citrix On Prem Site" -Level Info
        $params = @{
            DDC                    = $Config.Target.DDC 
            HostingConnection      = $Config.Target.HypervisorConnection
            Zone                   = $Config.Target.ZoneName 
        }
        $cvad_environment_details = Get-CVADSiteDetail @params
        $params = $null
    }
    elseif ($Config.Target.OrchestrationMethod -eq "API") {
        if ($Type -eq "CitrixVAD") {
            # pull relevant validation detail into $cvad_environment_details
            Write-Log -Message "Handling Citrix Credentials and Validating Citrix On Prem Site" -Level Info
            $params = @{
                DDC                    = $Config.Target.DDC 
                HostingConnection      = $Config.Target.HostingConnectionRootName
                Zone                   = $Config.Target.ZoneName 
                EncodedAdminCredential = $EncodedAdminCredential 
                DomainAdminCredential  = $DomainAdminCredential
            }
            $cvad_environment_details = Get-CVADSiteDetailAPI @params
            $params = $null
        }
        elseif ($Type -eq "CitrixDaaS"){
            # pull relevant validation detail into $daaas_environment_details
            Write-Log -Message "Handling Citrix Credentials and Validating Citrix DaaS Access" -Level Info
            $params = @{
                CloudUrl              = $CloudUrl 
                HostingConnection     = $Config.Target.HostingConnectionRootName
                Zone                  = $Config.Target.ZoneName
                CustomerID            = $Config.CitrixDaaS.CustomerID
                ClientID              = $Config.CitrixDaaS.ClientID
                ClientSecret          = $Config.CitrixDaaS.ClientSecret
                DomainAdminCredential = $DomainAdminCredential
            }
            $daas_environment_details = Get-DaaSSiteDetailAPI @params
            $params = $null
        }
    }
}
#endregion Citrix Site Access Pre Flight Checks

#region Nutanix Snapshot Pre Flight Checks
if (-not $AzureMode.IsPresent) {
    # This is not an Azure configuration
    if (($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") -and $Config.Target.CloneType -eq "MCS" -and $NTNXInfra.Testinfra.HypervisorType -eq "AHV") {
        # A purely AHV Test
        if ($Config.Target.OrchestrationMethod -eq "Snapin") {
            #Legacy PowerShell Approach
            foreach ($ParentVM in $Config.Target.ImagesToTest.ParentVM) {
                $cleansed_snapshot_name = $ParentVM -replace ".template","" 
                $params = @{
                    SnapshotName   = $cleansed_snapshot_name 
                    HypervisorType = $NTNXInfra.Testinfra.HypervisorType 
                    Type           = $Type
                    Config         = $Config
                }
                Get-NutanixSnapshot @params
                $params = $null
            }
        }
        elseif ($Config.Target.OrchestrationMethod  -eq "API") {
            #Need to set the XDHyp Path for Snapshot Validation
            foreach ($ParentVM in $Config.Target.ImagesToTest.ParentVM) {
                $snapshot_path = "XDHyp:\Connections\$($Config.Target.HostingConnectionRootName)\$($ParentVM)"

                if ($Type -eq "CitrixVAD") {
                    $params = @{
                        DDC                    = $Config.Target.DDC
                        HypervisorConnection   = $config.Target.HostingConnectionRootName
                        Snapshot               = $snapshot_path
                        EncodedAdminCredential = $EncodedAdminCredential 
                        DomainAdminCredential  = $DomainAdminCredential
                    }
                    Get-CVADImageSnapshotAPI @params
                    $params = $null
                }
                elseif ($Type -eq "CitrixDaaS"){
                    $params = @{
                        CloudUrl              = $CloudUrl 
                        HypervisorConnection  = $Config.Target.HostingConnectionRootName 
                        Snapshot              = $snapshot_path
                        ClientID              = $Config.CitrixDaaS.ClientID 
                        ClientSecret          = $Config.CitrixDaaS.ClientSecret 
                        CustomerID            = $Config.CitrixDaaS.CustomerID 
                        DomainAdminCredential = $DomainAdminCredential
                    }
                    Get-DaaSImageSnapshotAPI @params
                    $params = $null
                }
            } 
        }
    }
    elseif (($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") -and $Config.Target.CloneType -eq "PVS" -and $NTNXInfra.Testinfra.HypervisorType -eq "AHV") {
        Write-Log -Message "This is a Provisioning Services test. No snapshot validation required." -Level Info
    }

    if (($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") -and $Config.Target.CloneType -eq "MCS" -and $NTNXInfra.Testinfra.HypervisorType -eq "ESXi") {
        if ($Config.Target.OrchestrationMethod  -eq "Snapin") {
            # A Citrix on ESXi test
            foreach ($ParentVM in $Config.Target.ImagesToTest.ParentVM) {
                $params = @{
                    VM                = $ParentVM
                    HostingConnection = $Config.Target.HypervisorConnection 
                    HypervisorType    = $NTNXInfra.Testinfra.HypervisorType 
                    Type              = $Type 
                    DDC               = $Config.Target.DDC 
                    SnapshotName      = $ParentVM
                    Config            = $Config
                }
                Get-NutanixSnapshot @params
                $params = $null
            }
        }
        elseif ($Config.Target.OrchestrationMethod  -eq "API") {
            #Need to set the XDHyp Path for Snapshot Validation
            foreach ($ParentVM in $Config.Target.ImagesToTest.ParentVM) {
                $snapshot_path = "XDHyp:\Connections\$($Config.Target.HostingConnectionRootName)\$($Config.Target.vSphereDataCenter).datacenter\$($Config.Target.vSphere_Cluster).cluster\$($ParentVM)"


                if ($Type -eq "CitrixVAD") {
                    $params = @{
                        DDC                    = $Config.Target.DDC
                        HypervisorConnection   = $config.Target.HostingConnectionRootName
                        Snapshot               = $snapshot_path
                        EncodedAdminCredential = $EncodedAdminCredential 
                        DomainAdminCredential  = $DomainAdminCredential
                    }
                    Get-CVADImageSnapshotAPI @params
                    $params = $null
                }
                elseif ($Type -eq "CitrixDaaS"){
                    $params = @{
                        CloudUrl              = $CloudUrl 
                        HypervisorConnection  = $config.Target.HostingConnectionRootName
                        Snapshot              = $snapshot_path
                        ClientID              = $Config.CitrixDaaS.ClientID 
                        ClientSecret          = $Config.CitrixDaaS.ClientSecret 
                        CustomerID            = $Config.CitrixDaaS.CustomerID 
                        DomainAdminCredential = $DomainAdminCredential
                    }
                    Get-DaaSImageSnapshotAPI @params
                    $params = $null
                }
            }
        }
    }
    elseif (($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") -and $Config.Target.CloneType -eq "PVS" -and $NTNXInfra.Testinfra.HypervisorType -eq "ESXi") {
        Write-Log -Message "This is a Provisioning Services test. No snapshot validation required." -Level Info
    }

    if ($Type -eq "Horizon") {
        # A Horizon test
        foreach ($ParentVM in $Config.Target.ImagesToTest.ParentVM) {
            if ($ParentVM -match '^([^\\]+)\.') { $cleansed_vm_name = $matches[1] }
            if ($ParentVM -match '\\([^\\]+)\.snapshot$') { $cleansed_snapshot_name = $matches[1] }
            $params = @{
                VM             = $cleansed_vm_name 
                SnapshotName   = $cleansed_snapshot_name 
                HypervisorType = $NTNXInfra.Testinfra.HypervisorType 
                Type           = $Type
                Config         = $Config
            }
            Get-NutanixSnapshot @params
            $params = $null
        }
    }
    
    If ($Type -eq "Omnissa") {
        # This is a placeholder for Omnissa Specific Tests
        if ($Config.Target.OmnissaProvisioningMode -eq "Manual") {
            Write-Log -Message "This is a Omnissa Manual Pool test. No snapshot validation required." -Level Info
        } else {
            # Placeholder to validate VM Template for Omnissa Automated Pool
        }
    }    
}

#endregion Nutanix Snapshot Pre Flight Checks

#region Validate vSphere and ESXi Host Access if required
if (-not $AzureMode.IsPresent) {
    # This is not an Azure configuration
    if ($config.Target.HypervisorType -eq "ESXi" -and ($config.vSphere.RestartHostd -eq $true -or $config.Target.ForceAlignVMToHost -eq $true )) {
        $params = @{
            VCenter      = $Config.vSphere.vCenter 
            User         = $Config.vSphere.User 
            Password     = $Config.vSphere.Password 
            ClusterName  = $Config.vSphere.ClusterName 
            DataCenter   = $Config.vSphere.DataCenter 
            SshUsername  = $Config.vSphere.SshUsername 
            SshPassword  = $Config.vSphere.SshPassword
        }
        $vSphereValidated = Invoke-vSphereAccessCheck @params
        $params = $null
        

        if ($vSphereValidated -eq $true) {
            Write-Log -Message "vSphere vCenter and Host access validated successfully." -Level Info
        } else {
            Write-Log -Message "vSphere vCenter and Host access not validated successfully." -Level Warn
            Exit 1
        }
    }
}
#endregion Validate vSphere and ESXi Host Access if required

#region Validate Launcher Cluster Access if required
if ($Config.Target.Monitor_Launcher_Cluster_Performance -eq $true) {
    Write-Log -Message "Validating Launcher Cluster Details" -Level Info
    $params = @{
        TargetCVM         = $Config.Target.Launcher_Cluster_CVM
        TargetCVMAdmin    = $Config.Target.Launcher_Cluster_CVM_admin
        TargetCVMPassword = $Config.Target.Launcher_Cluster_CVM_password
    }
    $LauncherClusterHosts = Get-NTNXHostDetail @params

    if (-not [System.String]::IsNullOrEmpty($LauncherClusterHosts) -and $LauncherClusterHosts.Count -gt 0) {
        Write-Log -Message "Launcher Cluster Access validated successfully. Launcher Cluster has $($LauncherClusterHosts.Count) Hosts" -Level Info
    }
    else {
        Write-Log -message "Launcher Cluster Access not validated successfully. Exiting Script. Please check Launcher Cluster details in the test JSON file." -Level Warn
        Exit 1
    }
}
#endregion Validate Launcher Cluster Access if required

if ($ValidateOnly.IsPresent) {
    Write-Log -Message "Script is operating in a validation only mode. Exiting script before any form of execution occurs" -Level Info
    Exit 0
}
#endregion Validation

#region Start Infrastructure Monitoring
if ($Config.Test.StartInfrastructureMonitoring -eq $true -and $Config.Test.ServersToMonitor) {
    #// JK - I think we will have an issue with container based configurations here - need to fix the same as RDP DelProf Approach
    Write-Log -Message "Starting Infrastructure Monitoring" -Level Info
    Start-ServerMonitoring -ServersToMonitor $Config.Test.ServersToMonitor -Mode StartMonitoring -ServiceName "Telegraf"
}
#endregion Start Infrastructure Monitoring

#region Start Observer Monitoring
if (-not $AzureMode.IsPresent) {
    # This is not an Azure configuration
   # if ($Config.Test.StartObserverMonitoring -eq $true) {
    if ($Config.Test.StartObserverMonitoring -eq $true -or $Config.Target.files_prometheus -eq $true) {
        # Set hushlogin to get rid of first SSH text message
        Write-Log -Message "Set hushlogin on CVMs" -Level Info
        $params = @{
            ClusterIP      = $Config.Target.CVM
            CVMsshuser     = "nutanix"
            CVMsshpassword = $Config.Target.CVMsshpassword
        }
        $hushloginprocessed = Set-HushloginCVM @params
        $Params = $null

        Write-Log -Message "Starting Observer Monitoring" -Level Info
        $params = @{
           # clustername           = $Config.TestInfra.ClusterName
            Config                = $NTNXInfra
            CVMIPs                = $HostCVMIPs
            HostIPs               = $HostIPs
            CVMsshUser            = "nutanix"
            # CVMsshpassword        = $Config.Target.CVMsshpassword
            prometheusip          = $VSI_Prometheus_IP
            prometheussshuser     = $VSI_Prometheus_sshuser
            prometheussshpassword = $VSI_Prometheus_sshpassword 
            Status                = "Start"
        }
        $null = Set-CVMObserver @params
        $params = $null
    } 
    if ($Config.Target.files_prometheus -eq $true) {
        $params = @{
            Config                = $NTNXInfra
            Status                = "Start"
        }
        $null = Set-FilesPromMonitor @params
        $params = $null
    }
    if ($Config.Test.StartObserverMonitoring -eq $false -and $Config.Target.files_prometheus -eq $false) {
        Write-Log -Message "Make sure Observer Monitoring is stopped" -Level Info
        $params = @{
            prometheusip          = $VSI_Prometheus_IP
            prometheussshuser     = $VSI_Prometheus_sshuser
            prometheussshpassword = $VSI_Prometheus_sshpassword 
            Status                = "Stop"
        }
        $null = Set-CVMObserver @params
        $params = $null
    }
}
#endregion Start Observer Monitoring

#region Execute Test
#----------------------------------------------------------------------------------------------------------------------------
ForEach ($ImageToTest in $Config.Target.ImagesToTest) {
    #Outputs an ImageSpec_* Variable for each Item in the ImagesToTest Array
    $null = Set-VSIConfigurationVariables -ImageConfiguration $ImageToTest

    #region Define Workload Profiles
    #----------------------------------------------------------------------------------------------------------------------------
    #Set the multiplier for the Workloadtype. This adjusts the required MHz per user setting.
    if ($Config.Target.Workload -eq "Task Worker") {
        $LEWorkload = "TW"
        $WLmultiplier = 0.8
    }
    if ($Config.Target.Workload -eq "Knowledge Worker") {
        $LEWorkload = "KW"
        $WLmultiplier = 1.1
    }
    if ($Config.Target.Workload -eq "GPU Worker") {
        $LEWorkload = "GPU"
        $WLmultiplier = 1.0
    }
    Write-Log -Message "LE Worker Profile is: $($Config.Target.Workload) and the Workload is set to: $($LEWorkload)" -Level Info
    #endregion Define Workload Profiles

    #region Setup testname
    #----------------------------------------------------------------------------------------------------------------------------
    Write-Log -Message "Setting up Test Details" -Level Info
    $NTNXid = (New-Guid).Guid.SubString(1, 6)
    if (-not $AzureMode.IsPresent) {
        # This is not an Azure configuration
        $NTNXTestname = "$($NTNXid)_$($Config.Target.NodeCount)n_A$($NTNXInfra.Testinfra.AOSversion)_$($NTNXInfra.Testinfra.HypervisorType)_$($ImageSpec_NumberOfVMS)V_$($ImageSpec_NumberOfSessions)U_$LEWorkload"
    }    
    else {
        $NTNXTestname = "$($NTNXid)_Azure_$($ImageSpec_NumberOfVMS)V_$($ImageSpec_NumberOfSessions)U_$LEWorkload"
    }
    Write-Log -Message "Testname configured: $($NTNXTestname)" -Level Info
    #endregion Setup testname

    #region Setup Test Dashboard Data
    #----------------------------------------------------------------------------------------------------------------------------
    $CurrentTotalPhase = 1
    $TotalPhases = (([int]$Config.Target.ImageIterations * $RunPhases) + $PreRunPhases)

    # Build Test Dashboard Objects

    for ($i = 0; $i -le $Config.Target.ImageIterations; $i++) {
        if ($i -eq 0) { $Phases = $TotalPhases } else { $Phases = $RunPhases }
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
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

    #region Set affinity Config
    #----------------------------------------------------------------------------------------------------------------------------
    if (-not $AzureMode.IsPresent) {
        # This is not an Azure configuration
        $Message = "Setting Affinity Rules"
    }    
    else {
        $Message = "Skipping Setting Affinity Rules"
    }

    #region Update Test Dashboard
    $params = @{
        ConfigFile     = $NTNXInfra
        TestName       = $NTNXTestname 
        RunNumber      = "0" 
        InfluxUri      = $Config.TestInfra.InfluxDBurl 
        InfluxBucket   = $InfluxTestDashBucket 
        Status         = "Running" 
        CurrentPhase   = $CurrentTotalPhase 
        CurrentMessage = $Message
        TotalPhase     = "$($TotalPhases)"
    }
    $null = Set-TestData @params
    $params = $null
    $CurrentTotalPhase++
    #endregion Update Test Dashboard

    if (-not $AzureMode.IsPresent) {
        # This is not an Azure configuration
        if ($Config.Target.NodeCount -eq "1") {
            $NTNXInfra.Testinfra.SetAffinity = $true
        }
        else {
            $NTNXInfra.Testinfra.SetAffinity = $false
        }
        Write-Log -Message "Nutanix Host Affinity is set to: $($NTNXInfra.Testinfra.SetAffinity)" -Level Info
    }
    #endregion Set affinity Config

    $NTNXInfra.Target.ImagesToTest = $ImageToTest

    #region Slack update
    #----------------------------------------------------------------------------------------------------------------------------
    Write-Log -Message "Updating Slack" -Level Info
    if (-not $AzureMode.IsPresent) {
        # This is not an Azure configuration
        $SlackMessage = "New Login Enterprise test started by $($Config.Target.CVM_admin) on Cluster $($NTNXInfra.TestInfra.ClusterName). Testname: $($NTNXTestname)."
    }     
    else {
        $SlackMessage = "New Login Enterprise test started by $($Config.Target.CVM_admin) on Azure VM. Testname: $($NTNXTestname)."
    }
    Update-VSISlack -Message $SlackMessage -Slack $($NTNXInfra.Testinfra.Slack)
    #endregion Slack update

    #region Citrix validation
    #----------------------------------------------------------------------------------------------------------------------------

    if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
        Write-Log -Message "Validating Citrix" -Level Info

        #region Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Validating Citrix Connectivity" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        if ($Config.Target.OrchestrationMethod -eq "Snapin") {
            #Legacy PowerShell Approach
            Connect-VSICTX -DDC $Config.Target.DDC
            $NTNXInfra.Target.DesktopBrokerVersion = (Get-BrokerController -AdminAddress $Config.Target.DDC).ControllerVersion[0]
        }
        elseif ($Config.Target.OrchestrationMethod -eq "API") {
            #API Approach
            if ($Type -eq "CitrixVAD"){
                # pull relevant validation detail into $cvad_environment_details
                Write-Log -Message "Handling Citrix Credentials and Validating Citrix On Prem Site" -Level Info
                $params = @{
                    DDC                    = $Config.Target.DDC 
                    HostingConnection      = $Config.Target.HostingConnectionRootName 
                    EncodedAdminCredential = $EncodedAdminCredential 
                    DomainAdminCredential  = $DomainAdminCredential
                }
                $cvad_environment_details = Get-CVADSiteDetailAPI @params
                $params = $null

                $NTNXInfra.Target.DesktopBrokerVersion = $cvad_environment_details.cvad_site.ProductVersion
            }
            elseif ($Type -eq "CitrixDaaS"){
                # pull relevant validation detail into $daas_environment_details
                Write-Log -Message "Handling Citrix Credentials and Validating Citrix DaaS Access" -Level Info
                $params = @{
                    CloudUrl              = $CloudUrl 
                    HostingConnection     = $Config.Target.HostingConnectionRootName 
                    CustomerID            = $Config.CitrixDaaS.CustomerID
                    ClientID              = $Config.CitrixDaaS.ClientID
                    ClientSecret          = $Config.CitrixDaaS.ClientSecret
                    DomainAdminCredential = $DomainAdminCredential
                }
                $daas_environment_details = Get-DaaSSiteDetailAPI @params
                $params = $null

                $NTNXInfra.Target.DesktopBrokerVersion = $daas_environment_details.daas_site.ProductVersion
            }
        }
    }
    #endregion Citrix validation

    #region Horizon validation
    #----------------------------------------------------------------------------------------------------------------------------
    if ($Type -eq "Horizon") {
        Write-Log -Message "Validating Horizon" -Level Info

        #region Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Validating Horizon Connectivity" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        # Horizon
        $params = @{
            Server          = $Config.Target.ConnectionServer 
            User            = $Config.Target.ConnectionServerUser 
            Password        = $Config.Target.ConnectionServerUserPassword 
            vCenterServer   = $Config.Target.vCenterServer 
            vCenterUserName = $Config.Target.vCenterUsername 
            vCenterPassword = $Config.Target.vCenterPassword
        }
        Connect-VSIHVConnectionServer @params
        $Params = $Null
    }
    #endregion Horizon validation

    #region RDP validation
    #----------------------------------------------------------------------------------------------------------------------------
    if ($Type -eq "RDP") {
        Write-Log -Message "Validating RDP Hosts" -Level Info
        #region Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Validating RDP Host Connectivity" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        foreach ($RDP_Host in $Config.Target.RDP_Hosts) {
            try {
                Write-Log -Message "Validating RDP Connectivity to $($RDP_Host)" -Level Info
                if ($IsWindows){
                    $Test_Host_Connection = Test-NetConnection -ComputerName ($RDP_Host + "." + $Config.Target.DomainName) -port 3389 -ErrorAction Stop
                }
                elseif ($IsLinux){
                    $Test_Host_Connection = Test-Connection -ComputerName ($RDP_Host + "." + $Config.Target.DomainName) -TcpPort 3389 -ErrorAction Stop
                }
                
                Write-Log -Message "Successfully connected to $($RDP_Host)" -Level Info
            }
            catch {
                Write-Log -Message "Failed to connect to host $($RDP_Host)" -Level Error
                Exit 1
            }
        }
    }
    #endregion RDP validation

    #region Omnissa validation
    #----------------------------------------------------------------------------------------------------------------------------
    if ($Type -eq "Omnissa") {
        Write-Log -Message "Validating Omnissa" -Level Info

        #region Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Validating Omnissa Connectivity" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        # Placeholder for any future Omnissa specific validation steps
    }
    #endregion Omnissa validation

    #region LE Test Check
    #----------------------------------------------------------------------------------------------------------------------------

    #region Update Test Dashboard
    $params = @{
        ConfigFile     = $NTNXInfra
        TestName       = $NTNXTestname 
        RunNumber      = "0" 
        InfluxUri      = $Config.TestInfra.InfluxDBurl 
        InfluxBucket   = $InfluxTestDashBucket 
        Status         = "Running" 
        CurrentPhase   = $CurrentTotalPhase 
        CurrentMessage = "Getting/Completing Existing LE Tests" 
        TotalPhase     = "$($TotalPhases)"
    }
    $null = Set-TestData @params
    $params = $null
    $CurrentTotalPhase++
    #endregion Update Test Dashboard

    Write-Log -Message "Polling LE for tests" -Level Info
    $Test = Get-LETests | Where-Object { $_.name -eq $VSI_Test_Name }
    Wait-LeTest -testId $Test.Id
    #endregion LE Test Check

    #region LE Users
    #----------------------------------------------------------------------------------------------------------------------------

    #region Update Test Dashboard
    if (($SkipLEUsers)) { $Message = "Skipping Login Enterprise User Creation" } else { $Message = "Creating Login Enterprise Users" }
    $params = @{
        ConfigFile     = $NTNXInfra
        TestName       = $NTNXTestname 
        RunNumber      = "0" 
        InfluxUri      = $Config.TestInfra.InfluxDBurl 
        InfluxBucket   = $InfluxTestDashBucket 
        Status         = "Running" 
        CurrentPhase   = $CurrentTotalPhase 
        CurrentMessage = "$($Message)" 
        TotalPhase     = "$($TotalPhases)"
    }
    $null = Set-TestData @params
    $params = $null
    $CurrentTotalPhase++
    #endregion Update Test Dashboard

    if (!($SkipLEUsers)) {
        # Create the accounts and accountgroup in LE
        Write-Log -Message "Creating Accounts and Groups in LE" -Level Info
        $LEaccounts = New-LEAccounts -Username $VSI_Users_BaseName -Password $VSI_Users_Password -Domain $VSI_Users_NetBios -NumberOfDigits $VSI_Users_NumberOfDigits -NumberOfAccounts $ImageSpec_NumberOfSessions
        New-LEAccountGroup -Name $VSI_Users_GroupName -Description "Created by automation toolkit" -MemberIds $LEaccounts | Out-Null
    }
    #endregion LE Users

    #region AD Users
    #----------------------------------------------------------------------------------------------------------------------------

    #region Update Test Dashboard
    if (($SkipADUsers)) { $Message = "Skipping AD User Creation" } else { $Message = "Creating AD Users" }
    $params = @{
        ConfigFile     = $NTNXInfra
        TestName       = $NTNXTestname 
        RunNumber      = "0" 
        InfluxUri      = $Config.TestInfra.InfluxDBurl 
        InfluxBucket   = $InfluxTestDashBucket 
        Status         = "Running" 
        CurrentPhase   = $CurrentTotalPhase 
        CurrentMessage = "$($Message)" 
        TotalPhase     = "$($TotalPhases)"
    }
    $null = Set-TestData @params
    $params = $null
    $CurrentTotalPhase++
    #endregion Update Test Dashboard

    if (!($SkipADUsers)) {
        # OUs will be created if they don't exist, will also create a group with the $Basename in the same OU
        # This variant for when you're running this from a domain joined machine and your current user has rights to create AD resources
        if ([string]::isNullOrEmpty($VSI_Domain_LDAPUsername)) {
            $params = @{
                BaseName       = $VSI_Users_BaseName
                Amount         = $ImageSpec_NumberOfSessions #$VSI_Target_NumberOfSessions
                Password       = $VSI_Users_Password
                NumberOfDigits = $VSI_Users_NumberOfDigits
                DomainLDAPPath = $Config.Domain.LDAPPath
                OU             = $VSI_Users_OU
                ApplianceURL   = $VSI_LoginEnterprise_ApplianceURL
            }
            New-VSIADUsers @params
        }        
        else {
            # Alternative for when invoking the toolkit from a machine that's not part of the domain/ user that does not have the appropriate rights to create users
            $params = @{
                BaseName       = $VSI_Users_Basename
                Amount         = $ImageSpec_NumberOfSessions #$VSI_Target_NumberOfSessions
                Password       = $VSI_Users_Password
                NumberOfDigits = $VSI_Users_NumberOfDigits
                DomainLDAPPath = $Config.Domain.LDAPPath
                OU             = $VSI_Users_OU
                LDAPUsername   = $Config.Domain.LDAPUsername
                LDAPPassword   = $Config.Domain.LDAPPassword
                ApplianceURL   = $VSI_LoginEnterprise_ApplianceURL
            }
            New-VSIADUsers @params
        }
    }

    $Params = $null
    #endregion AD Users

    #region Force Desktop Pool recreation
    if ($Type -eq "Horizon") {
        if ($Force.IsPresent) {
            Write-Log -Message "Removing Horizon Desktop Pool due to force switch" -Level Info
            Remove-VSIHVDesktopPool -Name $Config.Target.DesktopPoolName
        }
    }
    #endregion Force Desktop Pool recreation

    #region Iterate through runs
    #----------------------------------------------------------------------------------------------------------------------------
    for ($i = 1; $i -le $Config.Target.ImageIterations; $i++) {

        $CurrentRunPhase = 1
        
        #region Update Slack
        #----------------------------------------------------------------------------------------------------------------------------
        if (-not $AzureMode.IsPresent) {
            # This is not an Azure configuration
            $SlackMessage = "Testname: $($NTNXTestname) Run$i is started by $($Config.Target.CVM_admin) on Cluster $($NTNXInfra.TestInfra.ClusterName)."
        } else {
            $SlackMessage = "Testname: $($NTNXTestname) Run$i is started by $($Config.Target.CVM_admin) on Azure"
        }
        Update-VSISlack -Message $SlackMessage -Slack $($NTNXInfra.Testinfra.Slack)

        #endregion Update Slack

        #region Get Nutanix Info
        #----------------------------------------------------------------------------------------------------------------------------

        #region Update Test Dashboard
        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            $Message = "Gathering Nutanix Information" 
        } else { 
            $Message = "Skipping Gathering Nutanix Information" 
        }

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = $Message
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            $ContainerId = Get-NTNXStorageUUID -Storage $Config.Target.CVM_storage
            $Hostuuid = Get-NTNXHostUUID -NTNXHost $Config.Target.NTNXHost
            $IPMI_ip = Get-NTNXHostIPMI -NTNXHost $Config.Target.NTNXHost
        }

        # We are going to monitor the files cluster performance metrics
        if ($Config.Target.Monitor_Files_Cluster_Performance -eq $true) {
            # Getting details from Nutanix Files Cluster hosting Files
            $Hostuuid_files_cluster = Get-NTNXHostUUID -NTNXHost $Config.Target.Files_Cluster_Host -TargetCVM $Config.Target.Files_Cluster_CVM -TargetCVMAdmin $VSI_Target_Files_Cluster_CVM_admin -TargetCVMPassword $VSI_Target_Files_Cluster_CVM_password
            $IPMI_ip_files_cluster = Get-NTNXHostIPMI -NTNXHost $Config.Target.Files_Cluster_Host -TargetCVM $Config.Target.Files_Cluster_CVM -TargetCVMAdmin $VSI_Target_Files_Cluster_CVM_admin -TargetCVMPassword $VSI_Target_Files_Cluster_CVM_password
            # The above $VSI_ variables get parsed and reset - they are set as variables in the config file
        }

        # We are going to monitor the launcher cluster performance metrics
        if ($Config.Target.Monitor_Launcher_Cluster_Performance -eq $true) {
            # Getting details from Nutanix Cluster hosting launchers
            $Hostuuid_launcher_cluster = Get-NTNXHostUUID -NTNXHost $Config.Target.Launcher_Cluster_Host -TargetCVM $Config.Target.Launcher_Cluster_CVM -TargetCVMAdmin $Config.Target.Launcher_Cluster_CVM_admin -TargetCVMPassword $Config.Target.Launcher_Cluster_CVM_password
            $IPMI_ip_launcher_cluster = Get-NTNXHostIPMI -NTNXHost $Config.Target.Launcher_Cluster_Host -TargetCVM $Config.Target.Launcher_Cluster_CVM -TargetCVMAdmin $Config.Target.Launcher_Cluster_CVM_admin -TargetCVMPassword $Config.Target.Launcher_Cluster_CVM_password
        }

        #endregion Get Nutanix Info

        #region Configure Desktop Pool
        #----------------------------------------------------------------------------------------------------------------------------

        #region Update Test Dashboard
        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            if (($Type -eq "Omnissa") -and ($config.Target.OmnissaProvisioningMode -eq "Manual")) {
                $Message = "Skipping Creating $($Type) Manual Desktop Pool" 
            } else {
                $Message = "Creating $($Type) Desktop Pool" 
            }
        }        
        else { 
            $Message = "Skipping Creating $($Type) Desktop Pool" 
        }

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = $Message
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {

            if ($Config.Target.OrchestrationMethod -eq "Snapin") {
                #Legacy Snapin Approach
                $networkMap = @{ "0" = "XDHyp:\HostingUnits\" + $Config.Target.HypervisorConnection + "\" + $Config.Target.HypervisorNetwork + ".network" }
                $ParentVM = "XDHyp:\HostingUnits\$($Config.Target.HypervisorConnection)\$ImageSpec_ParentVM" 
            }
            elseif ($Config.Target.OrchestrationMethod -eq "API") {
                #API Approach
                #$networkMap = "XDHyp:\HostingUnits\$($VSI_Target_HypervisorConnection + "_")$VSI_Target_HypervisorNetwork\$VSI_Target_HypervisorNetwork.network" #// JK no idea how this worked in prior testing, this network map needs to be looked at.
                
                if ($NTNXInfra.TestInfra.HypervisorType -eq "AHV") {
                    $ParentVM = "XDHyp:\Connections\$($Config.Target.HostingConnectionRootName)\$($ImageSpec_ParentVM)"
                    #Network = XDHyp:\Connections\DRMHX665KB-A\VLAN164.network
                    $networkMap = "XDHyp:\Connections\$($Config.Target.HostingConnectionRootName)\$($Config.Target.HypervisorNetwork).network"
                    $VSI_Target_HypervisorConnection = $Config.Target.HostingConnectionRootName
                }
                elseif ($NTNXInfra.TestInfra.HypervisorType -eq "ESXi") {
                    $ParentVM = "XDHyp:\Connections\$($Config.Target.HostingConnectionRootName)\$($Config.Target.vSphereDataCenter).datacenter\$($Config.Target.vSphere_Cluster).cluster\$($ImageSpec_ParentVM)"
                    #Network = XDHyp:\Connections\Shared-vCenter\EUC-Solutions.datacenter\DRMNX9KB-A.cluster\dvs_VLAN164.network
                    $networkMap = "XDHyp:\Connections\$($Config.Target.HostingConnectionRootName)\$($Config.Target.vSphereDataCenter).datacenter\$($Config.Target.vSphere_Cluster).cluster\$($Config.Target.HypervisorNetwork).network"
                    $VSI_Target_HypervisorConnection = $Config.Target.HostingConnectionRootName
                }
            }
            # Set param block for Handling Catalog and Delivery Group Creation. This is the same param block regardless of CVAD/DaaS or Snapin/API
            $params = @{
                ParentVM             = $ParentVM
                HypervisorConnection = $VSI_Target_HypervisorConnection #//JK will this work - need to re-test this
                HypervisorType       = $NTNXInfra.Testinfra.HypervisorType
                Networkmap           = $networkMap
                CpuCount             = $ImageSpec_NumCPUs #$VSI_Target_NumCPUs
                CoresCount           = $ImageSpec_NumCores #$VSI_Target_NumCores
                MemoryGB             = $ImageSpec_MemoryGB #$VSI_Target_MemoryGB
                ContainerID          = $ContainerId
                NamingPattern        = $Config.Target.NamingPattern #$VSI_Target_NamingPattern
                OU                   = $Config.Target.ADContainer #$VSI_Target_ADContainer
                DomainName           = $Config.Target.DomainName #$VSI_Target_DomainName
                SessionsSupport      = $Config.Target.SessionsSupport #$VSI_Target_SessionsSupport
                DesktopPoolName      = $Config.Target.DesktopPoolName #$VSI_Target_DesktopPoolName
                ZoneName             = $Config.Target.ZoneName #$VSI_Target_ZoneName
                Force                = $Force.IsPresent
                EntitledGroup        = $VSI_Users_BaseName
                SkipImagePrep        = $Config.Target.SkipImagePrep #$VSI_Target_SkipImagePrep
                FunctionalLevel      = $Config.Target.FunctionalLevel #$VSI_Target_FunctionalLevel
                CloneType            = $Config.Target.CloneType #$VSI_Target_CloneType
            }

            if ($Config.Target.OrchestrationMethod -eq "Snapin") {
                #Legacy Snapin Approach
                $CreatePool = Set-VSICTXDesktopPoolNTNX @params -DDC $Config.Target.DDC
                $NTNXInfra.Testinfra.MaxAbsoluteActiveActions = $CreatePool.MaxAbsoluteActiveActions
                $NTNXInfra.Testinfra.MaxAbsoluteNewActionsPerMinute = $CreatePool.MaxAbsoluteNewActionsPerMinute
                $NTNXInfra.Testinfra.MaxPercentageActiveActions = $CreatePool.MaxPercentageActiveActions
            }
            elseif ($Config.Target.OrchestrationMethod -eq "API") {
                #API Approach
                if ($Type -eq "CitrixVAD") {
                    $cvad_params = @{
                        DDC                    = $Config.Target.DDC
                        DomainAdminCredential  = $DomainAdminCredential 
                        EncodedAdminCredential = $EncodedAdminCredential
                    }
                    $CreatePool = Set-CVADDesktopPoolAPI @params @cvad_params
                    $cvad_params = $null
                    
                    # Values pulled via validation phase and set in $cvad_environment_details
                    $NTNXInfra.Testinfra.MaxAbsoluteActiveActions = $cvad_environment_details.hosting_connection_detail.MaxAbsoluteActiveActions 
                    $NTNXInfra.Testinfra.MaxAbsoluteNewActionsPerMinute = $cvad_environment_details.hosting_connection_detail.MaxAbsoluteNewActionsPerMinute
                    $NTNXInfra.Testinfra.MaxPercentageActiveActions = $cvad_environment_details.hosting_connection_detail.MaxPowerActionsPercentageOfMachines
                    Write-Log -Message "Successfully set hosting MaxAbsoluteActiveActions: $($cvad_environment_details.hosting_connection_detail.MaxAbsoluteActiveActions) / MaxAbsoluteNewActionsPerMinute: $($cvad_environment_details.hosting_connection_detail.MaxAbsoluteNewActionsPerMinute) / MaxPercentageActiveActions: $($cvad_environment_details.hosting_connection_detail.MaxPowerActionsPercentageOfMachines)" -Level Info
                }
                elseif ($Type -eq "CitrixDaaS") {
                    $daas_params = @{
                        CloudUrl               = $CloudUrl 
                        CustomerID             = $Config.CitrixDaaS.CustomerID 
                        ClientID               = $Config.CitrixDaaS.ClientID 
                        ClientSecret           = $Config.CitrixDaaS.ClientSecret 
                        EncodedAdminCredential = $EncodedAdminCredential
                    }

                    $CreatePool = Set-DaaSDesktopPoolAPI @params @daas_params
                    $daas_params = $null

                    # Values pulled via validation phase and set in $daas_environment_details
                    $NTNXInfra.Testinfra.MaxAbsoluteActiveActions = $daas_environment_details.hosting_connection_detail.MaxAbsoluteActiveActions
                    $NTNXInfra.Testinfra.MaxAbsoluteNewActionsPerMinute = $daas_environment_details.hosting_connection_detail.MaxAbsoluteNewActionsPerMinute
                    $NTNXInfra.Testinfra.MaxPercentageActiveActions = $daas_environment_details.hosting_connection_detail.MaxPowerActionsPercentageOfMachines
                    Write-Log -Message "Successfully set hosting MaxAbsoluteActiveActions: $($daas_environment_details.hosting_connection_detail.MaxAbsoluteActiveActions) / MaxAbsoluteNewActionsPerMinute: $($daas_environment_details.hosting_connection_detail.MaxAbsoluteNewActionsPerMinute) / MaxPercentageActiveActions: $($daas_environment_details.hosting_connection_detail.MaxPowerActionsPercentageOfMachines)" -Level Info
                }
            }

            $params = $null
        }

        if ($Type -eq "Horizon") {
            #Need to check with Sven here - which config do we use Horizon-NTNX.ps1 or NorizonView.Ps1?
            $params = @{
                Name                      = $Config.Target.DesktopPoolName #$VSI_Target_DesktopPoolName
                ParentVM                  = $ImageSpec_ParentVM #$VSI_Target_ParentVM
                VMSnapshot                = $VSI_Target_Snapshot
                VMFolder                  = $Config.Target.VMFolder #$VSI_Target_VMFolder
                HostOrCluster             = $Config.Target.Cluster #$VSI_Target_Cluster
                ResourcePool              = $Config.Target.ResourcePool #$VSI_Target_ResourcePool
                ReplicaDatastore          = $Config.Target.ReplicaDatastore #$VSI_Target_ReplicaDatastore
                InstantCloneDatastores    = $Config.Target.InstantCloneDatastores #$VSI_Target_InstantCloneDatastores
                NamingPattern             = $Config.Target.NamingPattern #$VSI_Target_NamingPattern
                NetBiosName               = $Config.Target.DomainName #$VSI_Target_DomainName
                ADContainer               = $Config.Target.ADContainer #$VSI_Target_ADContainer
                EntitledGroups            = $Config.Target.Entitlements #$VSI_Target_Entitlements
                vTPM                      = $ImageSpec_vTPM #$VSI_Target_vTPM
                Protocol                  = $Config.Target.SessionCfg #$VSI_Target_SessionCfg
                RefreshOsDiskAfterLogoff  = $Config.Target.RefreshOsDiskAfterLogoff #$VSI_Target_RefreshOSDiskAfterLogoff
                UserAssignment            = $Config.Target.UserAssignment #$VSI_Target_UserAssignment
                PoolType                  = $Config.Target.CloneType #$VSI_Target_CloneType
                UseViewStorageAccelerator = $Config.Target.UseViewStorageAccelerator #$VSI_Target_UseViewStorageAccelerator
                enableGRIDvGPUs           = $Config.Target.enableGRIDvGPUs #$VSI_Target_enableGRIDvGPUs
            }
            Set-VSIHVDesktopPool @params
            $Params = $null
        }

        if ($Type -eq "RDP") {
            if ($Config.Target.RDP_DelProf -eq $true) {
                # Delete the profiles between each run
                $ClearProfiles = $true
            }
            else {
                # reboot the host, but do not delete profiles
                $ClearProfiles = $false
            }

            $params = @{
                Hosts         = $Config.Target.RDP_Hosts #$VSI_Target_RDP_Hosts
                DomainName    = $Config.Target.DomainName #$VSI_Target_DomainName 
                MaxIterations = 4 
                SleepTime     = 30 
                RebootHosts   = $true
                ClearProfiles = $ClearProfiles
                UserName      = $Config.Domain.LDAPUsername #$VSI_Domain_LDAPUsername 
                Password      = $Config.Domain.LDAPPassword #$VSI_Domain_LDAPPassword
            }

            $CleanHosts = Reset-RDPHosts @params
            $params = $null
            
            if ($CleanHosts -eq $true) {
                Write-Log -Message "All RDP Hosts prepared for Test Run" -Level Info
            }
            else {
                Write-Log -Message "Failures Found when preparing RDP Hosts." -Level Warn
                Exit 1
            }
        }

        if ($Type -eq "Omnissa") {
            if ($config.Target.OmnissaProvisioningMode -eq "Manual") {
                # Placeholder for integrating Set-OmnissaManualPool function to potentially create the manual pool as part of the test run
                # Would rely on either running in a container for Ansible
                $Message = "Skipping Creating $($Type) Manual Desktop Pool" 
            } else {
                # Placeholder for creating an automated Omnissa Desktop Pool 
            }
        }

        #endregion Configure Desktop Pool

        #region Configure Folder Details for output
        #----------------------------------------------------------------------------------------------------------------------------
        $FolderName = "$($NTNXTestname)_Run$($i)"
        $OutputFolder = "$ScriptRoot\results\$FolderName"
        
        try {
            Write-Log -Message "Creating output directory $($OutputFolder)" -Level Info
            if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -ErrorAction Stop | Out-Null }
        }
        catch {
            Write-Log -Message $_ -Level Error
            Exit 1
        }

        #endregion Configure Folder Details for output

        #region Start monitoring Boot phase
        #----------------------------------------------------------------------------------------------------------------------------

        #region Update Test Dashboard
        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            $Message = "Booting $($Type) Desktops" 
        } else { 
            $Message = "Skipping Booting $($Type) Desktops" 
        }

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = $Message
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            $params = @{
                OutputFolder                 = $OutputFolder 
                DurationInMinutes            = "Boot" 
                RampupInMinutes              = $Config.Test.Target_RampupInMinutes #$VSI_Target_RampupInMinutes 
                Hostuuid                     = $Hostuuid 
                IPMI_ip                      = $IPMI_ip 
                Path                         = $Scriptroot
                AsJob                        = $true
            }
            $monitoringJob = Start-VSINTNXMonitoring @Params
            
            $params = $null
        }

        if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
            if ($config.Target.OrchestrationMethod -eq "Snapin") {
                #Legacy Snapin Approach
                $params = @{
                    DesktopPoolName            = $Config.Target.DesktopPoolName #$VSI_Target_DesktopPoolName
                    NumberofVMs                = $ImageSpec_NumberOfVMS #$VSI_Target_NumberOfVMS
                    PowerOnVMs                 = $ImageSpec_PowerOnVMs #$VSI_Target_PowerOnVMs
                    DDC                        = $Config.Target.DDC #$VSI_Target_DDC
                    HypervisorType             = $NTNXInfra.Testinfra.HypervisorType
                    Affinity                   = $NTNXInfra.Testinfra.SetAffinity
                    ClusterIP                  = $Config.Target.CVM #$NTNXInfra.Target.CVM
                    CVMSSHPassword             = $Config.Target.CVMsshpassword #$NTNXInfra.Target.CVMsshpassword
                    VMnameprefix               = $Config.Target.NamingPattern #$NTNXInfra.Target.NamingPattern
                    CloneType                  = $Config.Target.CloneType #$VSI_Target_CloneType
                    Hosts                      = $NTNXInfra.Testinfra.Hostip
                    Type                       = $Type
                    ForceAlignVMToHost         = $Config.Target.ForceAlignVMToHost #$NTNXInfra.Target.ForceAlignVMToHost
                    EnforceHostMaintenanceMode = $Config.Target.EnforceHostMaintenanceMode #$NTNXInfra.Target.EnforceHostMaintenanceMode
                    TargetCVMAdmin             = $Config.Target.CVM_admin #$VSI_Target_CVM_admin
                    TargetCVMPassword          = $Config.Target.CVM_password #$VSI_Target_CVM_password
                    Run                        = $i 
                    MaxRecordCount             = $Config.Target.MaxRecordCount #$VSI_Target_MaxRecordCount
                    HostCount                  = $Config.Target.NodeCount #$VSI_Target_NodeCount
                }

                if ($NTNXInfra.Target.HypervisorType -eq "AHV") {
                    $Boot = Enable-VSICTXDesktopPool @params
                }
                if ($NTNXInfra.Target.HypervisorType -eq "ESXi") {
                    # Params for vSphere DRS Group configuration
                    $vsphere_boot_params = @{
                        VCenter          = $Config.vSphere.vCenter
                        User             = $Config.vSphere.User
                        Password         = $Config.vSphere.Password
                        ClusterName      = $Config.vSphere.ClusterName
                        DataCenter       = $Config.vSphere.DataCenter
                    }
                    $Boot = Enable-VSICTXDesktopPool @params @vsphere_boot_params
                    $sphere_boot_params = $null
                }
                
                $Params = $null
            }
            elseif ($config.Target.OrchestrationMethod -eq "API") {
                #API Approach
                $params = @{
                    DesktopPoolName            = $Config.Target.DesktopPoolName #$VSI_Target_DesktopPoolName
                    NumberofVMs                = $ImageSpec_NumberOfVMS #$VSI_Target_NumberOfVMS
                    PowerOnVMs                 = $ImageSpec_PowerOnVMs #$VSI_Target_PowerOnVMs
                    DDC                        = $Config.Target.DDC #$VSI_Target_DDC
                    HypervisorType             = $NTNXInfra.Testinfra.HypervisorType
                    Affinity                   = $NTNXInfra.Testinfra.SetAffinity
                    ClusterIP                  = $Config.Target.CVM
                    CVMSSHPassword             = $Config.Target.CVMsshpassword
                    VMnameprefix               = $Config.Target.NamingPattern
                    DomainName                 = $Config.Target.DomainName #$VSI_Target_DomainName
                    OU                         = $Config.Target.ADContainer #$VSI_Target_ADContainer
                    CloneType                  = $Config.Target.CloneType #$VSI_Target_CloneType
                    Hosts                      = $NTNXInfra.Testinfra.Hostip
                    Type                       = $Type
                    ForceAlignVMToHost         = $Config.Target.ForceAlignVMToHost
                    EnforceHostMaintenanceMode = $Config.Target.EnforceHostMaintenanceMode
                    TargetCVMAdmin             = $Config.Target.CVM_admin #$VSI_Target_CVM_admin
                    TargetCVMPassword          = $Config.Target.CVM_password #$VSI_Target_CVM_password
                    Run                        = $i
                    MaxRecordCount             = $Config.Target.MaxRecordCount #$VSI_Target_MaxRecordCount
                    HostCount                  = $Config.Target.NodeCount #$VSI_Target_NodeCount
                    EncodedAdminCredential     = $EncodedAdminCredential
                    DomainAdminCredential      = $DomainAdminCredential
                }
                if ($Type -eq "CitrixVAD"){

                    $Boot = Enable-CVADDesktopPoolAPI @Params
                    #// JK - Need to handly the vSphere boot affinity additions - should be the same for API as it was for Snapin.
                }
                elseif ($Type -eq "CitrixDaaS") {
                    #//JK need to write this - Enable-DaaSDesktopPoolAPI
                }
            }

        }

        if ($Type -eq "Horizon") {
            if ($VSI_Target_PoolType -eq "RDSH") {
                $Boot = Enable-VSIHVDesktopPool -Name $Config.Target.DesktopPoolName -VMAmount $ImageSpec_NumberOfVMS -Increment $Config.Target.VMPoolIncrement -RDSH
            }
            elseif ($Config.Target.ProvisioningMode -eq "AllMachinesUpFront") {
                $Boot = Enable-VSIHVDesktopPool -Name $Config.Target.DesktopPoolName -VMAmount $ImageSpec_NumberOfVMS -Increment $Config.Target.VMPoolIncrement -AllMachinesUpFront
            }
            else {
                $Boot = Enable-VSIHVDesktopPool -Name $Config.Target.DesktopPoolName -VMAmount $ImageSpec_NumberOfVMS -NumberOfSpareVMs $Config.Target.NumberOfSpareVMs
            }
        }

        if ($Type -eq "Omnissa") {
            $params = @{
                ApiEndpoint         = $VSI_Target_OmnissaConnectionServer
                UserName            = $VSI_Target_OmnissaApiUserName
                Password            = $VSI_Target_OmnissaApiPassword
                Domain              = $VSI_Target_OmnissaApiDomain
                CloneType           = $VSI_Target_OmnissaProvisioningMode
                PoolName            = $VSI_Target_DesktopPoolName
                TargetCVM           = $config.Target.CVM
                TargetCVMAdmin      = $VSI_Target_CVM_admin
                TargetCVMPassword   = $VSI_Target_CVM_password
                Affinity            = $config.Testinfra.SetAffinity
                HypervisorType      = $VSI_Target_HypervisorType
                ForceAlignVMToHost  = $config.Target.ForceAlignVMToHost
                VMnameprefix        = $config.Target.NamingPattern
                Hosts               = $config.Testinfra.Hostip
                Run                 = $i
                CVMSSHPassword      = $config.Target.CVMsshpassword
                OU                  = $config.Target.ADContainer
                VmwareVCenter       = $config.vSphere.VCenter
                VMwareUser          = $config.vSphere.User
                VMwarePassword      = $config.vSphere.Password
                NodeCount           = $config.Target.NodeCount
            }
            $Boot = Enable-OmnissaPool @params
        }

        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            $NTNXInfra.Testinfra.BootStart = $Boot.bootstart
            $NTNXInfra.Testinfra.Boottime = $Boot.boottime
        }
        #endregion Start monitoring Boot phase

        #region Get Build Tattoo Information and update variable with new values
        #----------------------------------------------------------------------------------------------------------------------------
        if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
            if ($Config.Target.OrchestrationMethod -eq "SnapIn") {
                #Legacy Snapin Approach
                $BrokerVMs = Get-BrokerMachine -AdminAddress $Config.Target.DDC -DesktopGroupName $Config.Target.DesktopPoolName -MaxRecordCount $Config.Target.MaxRecordCount
            }
            elseif ($config.Target.OrchestrationMethod -eq "API") {
                if ($Type -eq "CitrixVAD") {
                    $params = @{
                        DDC                    = $Config.Target.DDC
                        DesktopPoolName        = $Config.Target.DesktopPoolName
                        EncodedAdminCredential = $EncodedAdminCredential
                        DomainAdminCredential  = $DomainAdminCredential
                    }
                    $BrokerVMs = Get-CVADBrokerMachinesAPI @params
                    $params = $null
                }
                elseif ($Type -eq "CitrixDaaS") {
                    $params = @{
                        CloudUrl              = $CloudUrl
                        DesktopPoolName       = $Config.Target.DesktopPoolName
                        CustomerID            = $Contig.CitrixDaaS.CustomerID
                        ClientID              = $Config.CitrixDaaS.ClientID
                        ClientSecret          = $Config.CitrixDaaS.ClientSecret
                        DomainAdminCredential = $DomainAdminCredential
                    }

                    $BrokerVMs = Get-DaaSBrokerMachinesAPI @params
                    $params = $null
                }
            }
            $RegisteredVMs = ($BrokerVMS | Where-Object { $_.RegistrationState -eq "Registered" })
            $MasterImageDNS = $RegisteredVMs[0].DNSName
        }
        
        if ($Type -eq "Horizon") {
            $MasterImageDNS = $boot.firstvmname
        }

        if ($Type -eq "RDP") {
            $MasterImageDNS = ($Config.Target.RDP_Hosts | Select-Object -First 1) + "." + $Config.Target.DomainName
        }

        if ($Type -eq "Omnissa") {
            $params = @{
                ApiEndpoint = $Config.Target.OmnissaConnectionServer
                UserName    = $Config.Target.OmnissaApiUserName
                Password    = $Config.Target.OmnissaApiPassword
                Domain      = $Config.Target.OmnissaApiDomain
                PoolName    = $Config.Target.DesktopPoolName
            }
            $OmnissaPool = Get-OmnissaDesktopPools @params

            $params = @{
                ApiEndpoint = $Config.Target.OmnissaConnectionServer
                UserName    = $Config.Target.OmnissaApiUserName
                Password    = $Config.Target.OmnissaApiPassword
                Domain      = $Config.Target.OmnissaApiDomain
                PoolID      = $OmnissaPool.id
            }
            $OmnissaMachines = Get-OmnissaMachinesPool @params

            $MasterImageDNS = $OmnissaMachines[0].dns_name
        }

        #region Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
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
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        try {
            Write-Log -Message "Getting Image Tattoo" -Level Info
            if ($IsLinux) {
                $user = $Config.Domain.LDAPUsername #$VSI_Domain_LDAPUsername
                $pass = ConvertTo-SecureString $Config.Domain.LDAPPassword -AsPlainText -Force
                $credential = New-Object System.Management.Automation.PSCredential($user, $pass)

                $Tattoo = Invoke-Command -Computer $MasterImageDNS { Get-ItemProperty HKLM:\Software\BuildTattoo } -Credential $credential -Authentication Negotiate -ErrorAction Stop
            } 
            else {
                $Tattoo = Invoke-Command -Computer $MasterImageDNS { Get-ItemProperty HKLM:\Software\BuildTattoo } -ErrorAction Stop
            }
             
            $NTNXInfra.Target.ImagesToTest.TargetOS = $Tattoo.TargetOS
            $NTNXInfra.Target.ImagesToTest.TargetOSVersion = $Tattoo.TargetOSVersion
            $NTNXInfra.Target.ImagesToTest.OfficeVersion = $Tattoo.OfficeVersion
            $NTNXInfra.Target.ImagesToTest.ToolsGuestVersion = $Tattoo.ToolsGuestVersion
            $NTNXInfra.Target.ImagesToTest.OptimizerVendor = $Tattoo.OptimizerVendor
            $NTNXInfra.Target.ImagesToTest.OptimizationsVersion = $Tattoo.OptimizationsVersion
            $NTNXInfra.Target.ImagesToTest.DesktopBrokerAgentVersion = $Tattoo.DesktopBrokerAgentVersion
            if ($NTNXInfra.AzureGuestDetails.IsAzureVM -eq "true") {
                # If this is An Azure VM, we need to send these details in. They are set by the Tattoo job if the the machine is detected as an Azure VM. Else they are blank
                $NTNXInfra.AzureGuestDetails.VM_Name = $Tattoo.Azure_VM_Name
                $NTNXInfra.AzureGuestDetails.VM_Location = $Tattoo.Azure_VM_Location
                $NTNXInfra.AzureGuestDetails.VM_Offer = $Tattoo.Azure_VM_Offer
                $NTNXInfra.AzureGuestDetails.VM_secureBoot = $Tattoo.Azure_VM_secureBoot
                $NTNXInfra.AzureGuestDetails.VM_vTPM = $Tattoo.Azure_VM_vTPM
                $NTNXInfra.AzureGuestDetails.VM_Size = $Tattoo.Azure_VM_Size
                $NTNXInfra.AzureGuestDetails.VM_Credential_Guard = $Tattoo.Azure_VM_Credential_Guard
                $NTNXInfra.AzureGuestDetails.VM_Bios_Name = $Tattoo.Azure_VM_Bios_Name
                $NTNXInfra.AzureGuestDetails.VM_CPU_Name = $Tattoo.Azure_VM_CPU_Name
                $NTNXInfra.AzureGuestDetails.VM_CPU_Manufacturer = $Tattoo.Azure_VM_CPU_Manufacturer
                $NTNXInfra.AzureGuestDetails.VM_CPU_ClockSpeed = $Tattoo.Azure_VM_CPU_ClockSpeed
                $NTNXInfra.AzureGuestDetails.VM_CPU_Caption = $Tattoo.Azure_VM_CPU_Caption
                $NTNXInfra.AzureGuestDetails.VM_CPU_Cores = $Tattoo.Azure_VM_CPU_Cores
                $NTNXInfra.AzureGuestDetails.VM_CPU_LogicalProcs = $Tattoo.Azure_VM_CPU_LogicalProcs
                $NTNXInfra.AzureGuestDetails.VM_CPU_ThreadCount = $Tattoo.Azure_VM_CPU_ThreadCount
                $NTNXInfra.AzureGuestDetails.VM_Memory_Size = $Tattoo.Azure_VM_Memory_Size
                $NTNXInfra.AzureGuestDetails.VM_AcceleratedNetworking = $Tattoo.Azure_VM_AcceleratedNetworking
                $NTNXInfra.AzureGuestDetails.VM_pageFile = $Tattoo.Azure_VM_pageFile
                $NTNXInfra.AzureGuestDetails.OS_Type = $Tattoo.Azure_OS_Type
                $NTNXInfra.AzureGuestDetails.OS_Offer = $Tattoo.Azure_OS_Offer
                $NTNXInfra.AzureGuestDetails.OS_Deployed_Version = $Tattoo.Azure_OS_Deployed_Version
                $NTNXInfra.AzureGuestDetails.OS_Deployed_Sku = $Tattoo.Azure_OS_Deployed_Sku
                $NTNXInfra.AzureGuestDetails.OS_Running_Version = $Tattoo.Azure_OS_Running_Version
                $NTNXInfra.AzureGuestDetails.Disk_Type = $Tattoo.Azure_Disk_Type
                $NTNXInfra.AzureGuestDetails.Disk_Size = $Tattoo.Azure_Disk_Size
                $NTNXInfra.AzureGuestDetails.Disk_Caching = $Tattoo.Azure_Disk_Caching
                $NTNXInfra.AzureGuestDetails.Disk_Encryption = $Tattoo.Azure_Disk_Encryption
                $NTNXInfra.AzureGuestDetails.Disk_Write_Accelerator = $Tattoo.Azure_Disk_Write_Accelerator
                $NTNXInfra.AzureGuestDetails.Disk_TempDisk_Size = $Tattoo.Azure_Disk_TempDisk_Size
            }
        }
        catch {
            Write-Log -Message $_ -Level Error
            Exit 1
        }
        
        #endregion Get Build Tattoo Information and update variable with new values

        #region Set number of sessions per launcher
        #----------------------------------------------------------------------------------------------------------------------------
        #region Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
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
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        if ($($Config.Target.SessionCfg.ToLower()) -eq "ica") {
            $SessionsperLauncher = 20
        }
        elseif ($($Config.Target.SessionCfg.ToLower()) -eq "rdp") {
            $SessionsperLauncher = 20
        }
        else {
            $SessionsperLauncher = 12
        }

        if (-not ($SkipLaunchers)) {
            $NumberOfLaunchers = [System.Math]::Ceiling($ImageSpec_NumberOfSessions / $SessionsperLauncher)
            # Wait for all launchers to be registered in LE

            Wait-LELaunchers -Amount $NumberOfLaunchers -NamingPattern $VSI_Launchers_NamingPattern -RebootLaunchers $config.Test.RebootLaunchers # Looking to get the minimum number of required launchers, not the total number of launchers
            if ($config.Test.RebootLaunchers -eq $true) {
                Write-Log -Message "Waiting 60 seconds for additional Launchers to be ready" -Level Info
                Start-Sleep -Seconds 60
            }
            # Create/update launchergroup with the launchers
            Set-LELauncherGroup -LauncherGroupName $VSI_Launchers_GroupName -NamingPattern $VSI_Launchers_NamingPattern
        }
        #endregion Set number of sessions per launcher

        #region Update the test params/create test if not exist
        #----------------------------------------------------------------------------------------------------------------------------

        #region Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
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
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
            $Params = @{
                TestName            = $Config.Test.Name #$VSI_Test_Name
                SessionAmount       = $ImageSpec_NumberOfSessions #$VSI_Target_NumberOfSessions
                RampupInMinutes     = $Config.Test.Target_RampupInMinutes #$VSI_Target_RampupInMinutes
                DurationInMinutes   = $ImageSpec_DurationInMinutes #$VSI_Target_DurationInMinutes
                LauncherGroupName   = $VSI_Launchers_GroupName
                AccountGroupName    = $VSI_Users_GroupName
                SessionMetricGroup  = $VSI_Target_SessionMetricGroupName
                SessionMetricAmount = $VSI_Target_SessionMetricAmount
                ConnectorName       = "Citrix Storefront"
                ConnectorParams     = @{serverURL = $Config.Target.StorefrontURL; resource = $Config.Target.DesktopPoolName }
                Workload            = $VSI_Target_Workload
            }
            $testId = Set-LELoadTestv7 @Params
            $params = $null
        }

        if ($Type -eq "RDP") {
            # create the host list Array for the test configuration
            $HostList = @()
            foreach ($RDP_Host in $Config.Target.RDP_Hosts) {
                $Custom_RDP_Host = New-Object -TypeName PSObject -Property @{
                    endpoint = $(
                        if ($RDP_Host -notlike "*.$($Config.Target.DomainName)") {
                            $RDP_Host + "." + $Config.Target.DomainName
                        }
                        else {
                            $RDP_Host
                        }
                    )
                    enabled = $true
                }
                $HostList += $Custom_RDP_Host
            }

            $Params = @{
                TestName           = $Config.Test.Name #$VSI_Test_Name 
                SessionAmount      = $ImageSpec_NumberOfSessions #$VSI_Target_NumberOfSessions
                RampupInMinutes    = $Config.Test.Target_RampupInMinutes #$VSI_Target_RampupInMinutes
                DurationInMinutes  = $ImageSpec_DurationInMinutes#$VSI_Target_DurationInMinutes
                LauncherGroupName  = $VSI_Launchers_GroupName
                AccountGroupName   = $VSI_Users_GroupName
                SessionMetricGroup = $VSI_Target_SessionMetricGroupName
                ConnectorName      = "Microsoft RDS"
                ConnectorParams    = @{hostList = $HostList; suppressCertWarn = $true; displayResolution = ""; resource = $Config.Target.DesktopPoolName}
                Workload           = $VSI_Target_Workload
            }
            $testId = Set-LELoadTestv7 @Params
            $params = $null
        }

        if ($Type -eq "Omnissa") {

            $Params = @{
                TestName           = $Config.Test.Name #$VSI_Test_Name 
                SessionAmount      = $ImageSpec_NumberOfSessions #$VSI_Target_NumberOfSessions
                RampupInMinutes    = $Config.Test.Target_RampupInMinutes #$VSI_Target_RampupInMinutes
                DurationInMinutes  = $ImageSpec_DurationInMinutes #$VSI_Target_DurationInMinutes
                LauncherGroupName  = $VSI_Launchers_GroupName
                AccountGroupName   = $VSI_Users_GroupName
                SessionMetricGroup = $VSI_Target_SessionMetricGroupName
                ConnectorName      = "VMware Horizon View"
                ConnectorParams    = @{serverUrl = $Config.Target.OmnissaConnectionServer; resource = $Config.Target.DesktopPoolName }
                Workload           = $VSI_Target_Workload
            }
            $testId = Set-LELoadTestv7 @Params
            $params = $null
            
            $params = @{
                ApiEndpoint = $Config.Target.OmnissaConnectionServer
                UserName    = $Config.Target.OmnissaApiUserName
                Password    = $Config.Target.OmnissaApiPassword
                Domain      = $Config.Target.OmnissaApiDomain
                PoolName    = $Config.Target.DesktopPoolName
            }
            $CreatedPool = Get-OmnissaDesktopPools @params

            $params = @{
                ApiEndpoint = $Config.Target.OmnissaConnectionServer
                UserName    = $Config.Target.OmnissaApiUserName
                Password    = $Config.Target.OmnissaApiPassword
                Domain      = $Config.Target.OmnissaApiDomain
                GroupName   = $VSI_Users_GroupName
            }
            $OmnissaGroup = Get-OmnissaGroupSID @params

            $params = @{
                ApiEndpoint = $Config.Target.OmnissaConnectionServer
                UserName    = $Config.Target.OmnissaApiUserName
                Password    = $Config.Target.OmnissaApiPassword
                Domain      = $Config.Target.OmnissaApiDomain
                PoolId      = $CreatedPool.id
                GroupID     = $OmnissaGroup.id
            }
            $Entitlement = Set-OmnissaManualPoolEntitlement @params
        }
        
        #endregion Update the test params/create test if not exist

        #region Wait for VMs to have settled down
        #----------------------------------------------------------------------------------------------------------------------------
        if (-not ($SkipWaitForIdleVMs)) {
            Write-Log -Message "Waiting 60 seconds for VMs to become idle" -Level Info
            Start-Sleep -Seconds 60
        }
        #endregion Wait for VMs to have settled down

        #region Stop and cleanup monitoring job Boot phase
        #----------------------------------------------------------------------------------------------------------------------------
        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            $monitoringJob | Stop-Job
            $monitoringJob | Remove-Job
        }
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

        #region Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Waiting $($Config.Target.MinutesToWaitAfterIdleVMs) Minutes Before Test" 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        #region Restart ESXi HostD Service if set
        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            if ($NTNXInfra.Testinfra.HypervisorType -eq "ESXi" -and $Config.vSphere.RestartHostd -eq $true) {
                
                $params = @{
                    VCenter      = $Config.vSphere.vCenter
                    User         = $Config.vSphere.User 
                    Password     = $Config.vSphere.Password 
                    ClusterName  = $Config.vSphere.ClusterName 
                    DataCenter   = $Config.vSphere.DataCenter 
                    SshUsername  = $Config.vSphere.SshUsername 
                    SshPassword  = $Config.vSphere.SshPassword 
                }
                
                Invoke-ESXHostDRestart @params
                $Params = $null
            }
        }
        #endregion Restart ESXi HostD Service if set

        Write-Log -Message "Waiting for $($Config.Target.MinutesToWaitAfterIdleVMs) minutes before starting test" -Level Info
        Start-sleep -Seconds $($Config.Target.MinutesToWaitAfterIdleVMs * 60)
        #endregion VM Idle state

        #region Nutanix Curator Stop
        #----------------------------------------------------------------------------------------------------------------------------
        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            $Message = "Stopping Nutanix Curator" 
        } else {
            $Message = "Skipping Stopping Nutanix Curator" 
        }

        #region Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = $Message
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            Write-Log -Message "Stopping Nutanix Curator Service" -Level Info
            Set-NTNXcurator -ClusterIP $Config.Target.CVM -CVMSSHPassword $Config.Target.CVMsshpassword -Action "stop"
        }

        if ($Config.Target.Monitor_Files_Cluster_Performance -eq $true) {
            Write-Log -Message "Stopping Nutanix Curator Service on the Nutanix Files Cluster $($Config.Target.Files_Cluster_CVM)" -Level Info
            Set-NTNXcurator -ClusterIP $Config.Target.Files_Cluster_CVM -CVMSSHPassword $Config.Target.Files_Cluster_CVMsshpassword -Action "stop"
        }

        #endregion Nutanix Curator Stop

        #region Advanced Diagnostics - perf_collect - Start
        if (-not $AzureMode.IsPresent) {
            #This is not an Azure test
            if ($Config.psobject.Properties.Name -contains "AdvancedDiagnostics") {
                if ($Config.AdvancedDiagnostics.EnableCollectPerf -eq $true) {
                    Write-Log -Message "Advanced diagnostic performance logging is enabled (collect_perf). Job will be started." -Level Warn
                    $params = @{
                        ClusterIP       = $Config.Target.CVM
                        CVMSSHPassword  = $Config.Target.CVMsshpassword
                        Action          = "Start"
                        SampleInterval  = $Config.AdvancedDiagnostics.CollectPerfSampleInterval
                        SampleFrequency = $Config.AdvancedDiagnostics.CollectPerfSampleFrequency
                    }
                    Set-NTNXCollectPerf @params
                
                    $params = $null
                }
            }
        }
        #endregion Advanced Diagnostics - perf_collect - Start

        #region Start the test
        #----------------------------------------------------------------------------------------------------------------------------

        #region Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
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
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        Write-Log -Message "Starting Test $($testId)" -Level Info
        Start-LETest -testId $testId -Comment "$FolderName-$ImageSpec_Comment "
        $TestRun = Get-LETestRuns -testId $testId | Select-Object -Last 1
        #endregion Start the test

        #region Start monitoring
        #----------------------------------------------------------------------------------------------------------------------------

        #region Update Test Dashboard
        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            $Message = "Starting Login Enterprise Test Monitor Run $($i)" 
        }
        else {
            $Message = "Skipping Login Enterprise Test Monitor Run $($i)"
        }

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = $Message 
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            $Params = @{
                OutputFolder                 = $OutputFolder 
                DurationInMinutes            = $ImageSpec_DurationInMinutes
                RampupInMinutes              = $Config.Test.Target_RampupInMinutes
                Hostuuid                     = $Hostuuid 
                IPMI_ip                      = $IPMI_ip 
                Path                         = $Scriptroot 
                AsJob                        = $true
            }
            $monitoringJob = Start-VSINTNXMonitoring @params
            $Params = $null
        }

        #start Monitoring the Files Cluster Hosting Files
        if ($Config.Target.Monitor_Files_Cluster_Performance -eq $true) {
            $Params = @{
                OutputFolder                 = ($OutputFolder + "\" + "Files_Cluster")
                DurationInMinutes            = $ImageSpec_DurationInMinutes
                RampupInMinutes              = $Config.Test.Target_RampupInMinutes
                Hostuuid                     = $Hostuuid_files_cluster 
                IPMI_ip                      = $IPMI_ip_files_cluster 
                Path                         = $Scriptroot 
                TargetCVM                    = $Config.Target.Files_Cluster_CVM # override the default CVM Value
                TargetCVMAdmin               = $Config.Target.Files_Cluster_CVM_admin # override the default CVM Admin Account Value
                TargetCVMPassword            = $Config.Target.Files_Cluster_CVM_password # override the default CVM Password Value
                AsJob                        = $true
            }
            $monitoringJob_files = Start-VSINTNXMonitoring @params
            $Params = $null
        }

        #region Update Test Dashboard
        if ($Config.Target.Files -ne "") { $Message = "Starting Nutanix Files Monitor Run $($i)" } else { $Message = "Skipping Nutanix Files Monitoring" }
        Write-Log -Message "$($Message)" -Level Info
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
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
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        if ($Config.Target.Files -ne "") {
            $Params = @{
                OutputFolder                 = $OutputFolder 
                DurationInMinutes            = $ImageSpec_DurationInMinutes
                RampupInMinutes              = $Config.Test.Target_RampupInMinutes
                Path                         = $Scriptroot 
                AsJob                        = $true
            }
            $monitoringFilesJob = Start-NTNXFilesMonitoring @Params
            $Params = $null
        }

        #start Monitoring the Launcher Cluster
        if ($Config.Target.Monitor_Launcher_Cluster_Performance -eq $true) {
            $Params = @{
                OutputFolder                 = ($OutputFolder + "\" + "Launcher_Cluster")
                DurationInMinutes            = $ImageSpec_DurationInMinutes
                RampupInMinutes              = $Config.Test.Target_RampupInMinutes
                Hostuuid                     = $Hostuuid_launcher_cluster 
                IPMI_ip                      = $IPMI_ip_launcher_cluster 
                Path                         = $Scriptroot 
                TargetCVM                    = $Config.Target.Launcher_Cluster_CVM
                TargetCVMAdmin               = $Config.Target.Launcher_Cluster_CVM_admin
                TargetCVMPassword            = $Config.Target.Launcher_Cluster_CVM_password
                AsJob                        = $true
            }
            $monitoringJob_launcher_cluster = Start-VSINTNXMonitoring @params
            $Params = $null
        }

        #region Update Test Dashboard
        if ($Config.Target.NetScaler -ne "") { $Message = "Starting Citrix NetScaler Monitor Run $($i)" } else { $Message = "Skipping Citrix NetScaler Monitoring" }
        Write-Log -Message "$($Message)" -Level Info
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
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
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        if ($VSI_Target_NetScaler -ne "") {
            $Params = @{
                OutputFolder      = $OutputFolder 
                DurationInMinutes = $ImageSpec_DurationInMinutes #$VSI_Target_DurationInMinutes 
                RampupInMinutes   = $Config.Test.Target_RampupInMinutes #$VSI_Target_RampupInMinutes
                Path              = $Scriptroot 
                AsJob             = $true
            }
            $monitoringNSJob = Start-NTNXNSMonitoring @params
            $Params = $null
        }
        #endregion Start monitoring

        #region Wait for test to finish
        #----------------------------------------------------------------------------------------------------------------------------

        #region Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
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
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
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
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = "Waiting for Test to Complete" 
            TotalPhase     = "$($RunPhases)"
        }
        #endregion Update Test Dashboard

        Wait-LETest -testId $testId -waitParams $Waitparams
        #endregion Wait for test to finish

        #region Advanced Diagnostics - perf_collect - Stop
        if (-not $AzureMode.IsPresent) {
            #This is not an Azure test
            if ($Config.psobject.Properties.Name -contains "AdvancedDiagnostics") {
                if ($Config.AdvancedDiagnostics.EnableCollectPerf -eq $true) {
                    Write-Log -Message "Advanced diagnostic performance logging is enabled (collect_perf). Job will be stopped." -Level Info
                    $params = @{
                        ClusterIP             = $Config.Target.CVM
                        CVMSSHPassword        = $Config.Target.CVMsshpassword
                        Action                = "Stop"
                        OutputFolder          = $OutputFolder
                        DownloadCollectorFile = $true
                    }
                    Set-NTNXCollectPerf @params
                
                    $params = $null
                }
            }
        }
        #endregion Advanced Diagnostics - perf_collect - Stop

        #region Cleanup monitoring job
        #----------------------------------------------------------------------------------------------------------------------------
        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            $monitoringJob | Wait-Job | Out-Null
            $monitoringJob | Remove-Job | Out-Null
        }
        if ($Config.Target.Monitor_Files_Cluster_Performance -eq $true) {
            $monitoringJob_files | Wait-Job | Out-Null
            $monitoringJob_files | Remove-Job | Out-Null
        }
        if ($Config.Target.Files -ne "") {
            $monitoringFilesJob | Wait-Job | Out-Null
            $monitoringFilesJob | Remove-Job | Out-Null
        }
        if ($Config.Target.Monitor_Launcher_Cluster_Performance -eq $true) {
            $monitoringJob_launcher_cluster | Wait-Job | Out-Null
            $monitoringJob_launcher_cluster | Remove-Job | Out-Null
        }
        if ($Config.Target.NetScaler -ne "") {
            $monitoringNSJob | Wait-Job | Out-Null
            $monitoringNSJob | Remove-Job | Out-Null
        }
        #endregion Cleanup monitoring job

        #region Nutanix Curator Start
        #----------------------------------------------------------------------------------------------------------------------------

        #region Update Test Dashboard
        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            $Message = "Starting Nutanix Curator" 
        } else {
            $Message = "Skipping Starting Nutanix Curator" 
        }

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            CurrentMessage = $Message
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            Write-Log -Message "Starting Nutanix Curator Service" -Level Info
            Set-NTNXcurator -ClusterIP $Config.Target.CVM -CVMSSHPassword $Config.Target.CVMsshpassword -Action "start"
        }

        if ($Config.Target.Monitor_Files_Cluster_Performance -eq $true) {
            Write-Log -Message "Starting Nutanix Curator Service on the Nutanix Files Cluster $($Config.Target.Files_Cluster_CVM)" -Level Info
            Set-NTNXcurator -ClusterIP $Config.Target.Files_Cluster_CVM -CVMSSHPassword $Config.Target.Files_Cluster_CVMsshpassword -Action "start"
        }
        
        #endregion Nutanix Curator Start

        #region Write config to OutputFolder and Download LE Metrics
        #----------------------------------------------------------------------------------------------------------------------------

        if ($Config.Test.SkipLEMetricsDownload -eq $true) { $Message = "Skipping Exporting Test Data from Login Enterprise" } else { $Message = "Exporting Test Data from Login Enterprise" } 
        #region Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentRunPhase 
            #CurrentMessage = "Exporting Test Data from Login Enterprise" 
            CurrentMessage = $Message  
            TotalPhase     = "$($RunPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentRunPhase++

        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "0" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        if (-not $AzureMode.IsPresent) { 
            # This is not an Azure configuration
            $NTNXInfra.Testinfra.VMCPUCount = [Int]$ImageSpec_NumCPUs * [Int]$ImageSpec_NumCores
        }

        $NTNXInfra.Testinfra.Testname = $FolderName
        $NTNXInfra | ConvertTo-Json -Depth 20 | Set-Content -Path $OutputFolder\Testconfig.json -Force

        if ($Config.Test.SkipLEMetricsDownload -eq $true){ 
            Write-Log -Message "Skipping download of LE Metrics" -Level Info
        } else {
            Write-Log -Message "Exporting LE Measurements to output folder" -Level Info
            Export-LEMeasurements -Folder $OutputFolder -TestRun $TestRun -DurationInMinutes $ImageSpec_DurationInMinutes -SessionMetricsEnabled $ImageSpec_SessionMetricsEnabled
        }
        #endregion Write config to OutputFolder and Download LE Metrics

        #region download Telegraf data
        if ($Config.Test.ImportTelegrafData -eq $true) {
            # Download Telegraf boot data
            Write-Log -Message "Download Boot Telegraf data" -Level Info
            $params = @{
                TestStarttime       = $Boot.bootstart
                TestFinishtime      = (get-date $Boot.bootstart).AddSeconds($boot.boottime)
                Influxdburl         = $Config.Testinfra.InfluxDBurl
                OutputFolder        = "$($OutputFolder)\boot"
                Token               = $Config.Testinfra.InfluxToken
                TelegrafBucket      = $Config.Test.TelegrafBucket
            }
            $Telegrafdataprocessed = Get-Telegrafdata @params
            $Params = $null
            # Download Telegraf test data
            Write-Log -Message "Download Telegraf test data" -Level Info
            $vsiresult = Import-CSV "$($OutputFolder)\VSI-results.csv"
            $params = @{
                TestStarttime       = $vsiresult.started
                TestFinishtime      = $vsiresult.finished
                Influxdburl         = $Config.Testinfra.InfluxDBurl
                OutputFolder        = $OutputFolder
                Token               = $Config.Testinfra.InfluxToken
                TelegrafBucket      = $Config.Test.TelegrafBucket
            }
            $Telegrafdataprocessed = Get-Telegrafdata @params
            $Params = $null
        }
        #endregion download Telegraf data
        #region download Prometheus data
        if ($Config.Test.StartObserverMonitoring -eq $true -or $Config.Target.files_prometheus -eq $true) {
            if ($Config.TestInfra.HostGPUs -ne "None"){
                $GetGPU = $true
            }
            # Download Prometheus data
            Write-Log -Message "Download Prometheus data" -Level Info
            $vsiresult = Import-CSV "$($OutputFolder)\VSI-results.csv"
            $params = @{
                TestStarttime       = $vsiresult.started
                TestFinishtime      = $vsiresult.finished
                Prometheusip        = $VSI_Prometheus_IP
                OutputFolder        = $OutputFolder
                MainProm            = $Config.Test.StartObserverMonitoring
                GPU                 = $GetGPU
                Files               = $Config.Target.files_prometheus
            }
            $Prometheusdataprocessed = Get-Prometheusdata @params
            $Params = $null
        }
        #endregion download Prometheus data
        #region Check for RDA File and if exists then move it to the output folder
        #----------------------------------------------------------------------------------------------------------------------------
        if (Test-Path -Path $RDASource) {
            Write-Log -Message "[DATA EXPORT] Exporting RDA Data to output folder" -Level Info
            if ($Type -eq "Omnissa") {
                $csvData = get-content $RDASource | ConvertFrom-String -Delimiter "," -PropertyNames Timestamp, currentCPU, currentRAM, totalCPU, encoderid, videoCodecid, VideoCodecUseid, currentBandwithoutput, currentLatency, currentavailableBandwidth, currentFps, NetworkLoss, totalBandwidthusage, averageBandwidthUsage, GPUusage, GPUmemoryusage, GPUmemoryInUse, GPUvideoEncoderusage, GPUvideoDecoderusage, GPUtotalUsage, GPUVideoEncoderSessions, GPUVideoEncoderAverageFPS, GPUVideoEncoderLatency | Select -Skip 1
            } else {
                $csvData = get-content $RDASource | ConvertFrom-String -Delimiter "," -PropertyNames Timestamp, screenResolutionid, encoderid, movingImageCompressionConfigurationid, preferredColorDepthid, videoCodecid, VideoCodecUseid, VideoCodecTextOptimizationid, VideoCodecColorspaceid, VideoCodecTypeid, HardwareEncodeEnabledid, VisualQualityid, FramesperSecondid, RDHSMaxFPS, currentCPU, currentRAM, totalCPU, currentFps, totalFps, currentRTT, NetworkLatency, NetworkLoss, CurrentBandwidthEDT, totalBandwidthusageEDT, averageBandwidthusageEDT, currentavailableEDTBandwidth, EDTInUseId, currentBandwithoutput, currentLatency, currentavailableBandwidth, totalBandwidthusage, averageBandwidthUsage, averageBandwidthAvailable, GPUusage, GPUmemoryusage, GPUmemoryInUse, GPUvideoEncoderusage, GPUvideoDecoderusage, GPUtotalUsage, GPUVideoEncoderSessions, GPUVideoEncoderAverageFPS, GPUVideoEncoderLatency | Select -Skip 1
            }
            $csvData | Export-Csv -Path $RDADestination -NoTypeInformation
            Remove-Item -Path $RDASource -ErrorAction SilentlyContinue
        }
        #endregion Check for RDA File and if exists then move it to the output folder

        #region Cleanup Nutanix Files Data
        #----------------------------------------------------------------------------------------------------------------------------

        #region Update Test Dashboard
        if ($Config.Test.Delete_Files_Data -eq $true -and $null -ne $Config.Test.Nutanix_Files_Shares) { $Message = "Starting Nutanix Files Data Clean" } else { $Message = "Skipping Nutanix Files Data Clean" }
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
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
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        if ($VSI_Target_Files -ne "") {
            if ($null -ne $Config.Test.Nutanix_Files_Shares -and $Config.Test.Delete_Files_Data -eq $true) { #Need to update the above messaging to reflect these detetion rules
                Write-Log -Message "Processing Nutanix Files Data Removal" -Level Info
                # TODO: Need to Validate this configuation
                Remove-NutanixFilesData -Shares $Config.Test.Nutanix_Files_Shares -Mode Execute
            }
        }
        #endregion Cleanup Nutanix Files Data

        #region Upload Data to Influx
        #----------------------------------------------------------------------------------------------------------------------------

        #region Update Test Dashboard
        if ($Config.Test.Uploadresults) { $Message = "Uploading Data to InfluxDB" } else { $Message = "Skipping InfluxDB Data Upload" }
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
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
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Currently Executing Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        if ($Config.Test.UploadResults) {
            Write-Log -Message "Uploading Test Run Data to Influx" -Level Info
            
            $TestDetail = $NTNXInfra.TestInfra.TestName -Split '_Run'
            $Run = $TestDetail[1]

            
            #region upload boot phase Data to Influx
            # Get the boot files and start time
            if (-not $AzureMode.IsPresent) {
                Write-Log -Message "[DATA UPLOAD] Processing Boot phase data uploads" -Level Info 
                # This is not an Azure configuration
                $Files = Get-ChildItem "$($OutputFolder)\Boot\*.csv"
                # Build the Boot Bucket Name
                If ($($Config.Test.BucketName) -eq "LoginDocuments") {
                    $BucketName = "BootBucket"
                }
                Else {
                    $BucketName = "BootBucketRegression"
                }

                # Loop through the boot files and process each one
                foreach ($File in $Files) {
                    if (($File.Name -like "host raw*") -or ($File.Name -like "cluster raw*") -or ($File.Name -like "telegraf*")) {
                        Write-Log -Message "[DATA UPLOAD] Uploading $($File.name) to Influx" -Level Info
                        # start a time object to measure upload time
                        $DataUploadStopWatch = [system.Diagnostics.Stopwatch]::StartNew()
                        if (Start-InfluxUpload -influxDbUrl $Config.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $Config.Testinfra.InfluxToken -File $File -BucketName $BucketName) {
                            # Stop the timer
                            $DataUploadStopWatch.Stop()
                            $ElapsedTime = [math]::Round($DataUploadStopWatch.Elapsed.TotalSeconds, 2)
                            Write-Log -Message "[DATA UPLOAD] Took $($ElapsedTime) seconds to finish uploading Boot file $($File.Name) to Influx" -Level Info
                        }
                        else {
                            $DataUploadStopWatch.Stop()
                            Write-Log -Message "[DATA UPLOAD] Error uploading $($File.name) to Influx" -Level Warn
                        }
                    }
                    else {
                        Write-Log -Message "[DATA UPLOAD] Skipped uploading Boot file $($File.Name) to Influx" -Level Info
                    }
                }
            }
            #endregion upload boot phase Data to Influx

            #region upload full test data to Influx
            Write-Log -Message "[DATA UPLOAD] Processing full test data uploads" -Level Info 
            # Get the test run files and start time
            $Files = Get-ChildItem "$($OutputFolder)\*.csv"
            # Loop through the test run data files and process each one
            foreach ($File in $Files) {
                if (($File.Name -like "Raw Timer Results*") -or ($File.Name -like "Raw Login Times*") -or ($File.Name -like "NetScaler Raw*") -or ($File.Name -like "host raw*") -or ($File.Name -like "files raw*") -or ($File.Name -like "cluster raw*") -or ($File.Name -like "raw appmeasurements*") -or ($File.Name -like "EUX-Score*") -or ($File.Name -like "EUX-timer-score*") -or ($File.Name -like "RDA*") -or ($File.Name -like "VM Perf Metrics*") -or ($File.Name -like "Telegraf*") -or ($File.Name -like "Prom*")) {
                    Write-Log -Message "[DATA UPLOAD] Uploading $($File.name) to Influx" -Level Info
                    #Set Azure VM Value - If this is an Azure VM, we will be sending different tags in to Influx. If not, then it's business as usual.
                    if ($NTNXInfra.AzureGuestDetails.IsAzureVM -eq $true) { $IsAzureVM = $true } else { $IsAzureVM = $false }
                    if ($File.Name -like "Prom*") {
                        $BucketName = $($Config.TestInfra.PromBucketName)
                    } Else {
                        $BucketName = $($Config.Test.BucketName)
                    }
                    $DataUploadStopWatch = [system.Diagnostics.Stopwatch]::StartNew()
                    
                    if (Start-InfluxUpload -influxDbUrl $Config.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $Config.Testinfra.InfluxToken -File $File -BucketName $BucketName -IsAzureVM $IsAzureVM) {
                        $DataUploadStopWatch.Stop()
                        $ElapsedTime = [math]::Round($DataUploadStopWatch.Elapsed.TotalSeconds, 2)
                        Write-Log -Message "[DATA UPLOAD] Took $($ElapsedTime) seconds to finish uploading file $($File.Name) to Influx" -Level Info
                    }
                    else {
                        $DataUploadStopWatch.Stop()
                        Write-Log -Message "[DATA UPLOAD] Error uploading $($File.name) to Influx" -Level Warn
                    }
                }
                else {
                    Write-Log -Message "[DATA UPLOAD] Skipped uploading file $($File.Name) to Influx" -Level Info
                }
            }
            #endregion upload full test data to Influx

            #region Upload Files Hosting Data to Influx
            if ($Config.Target.Monitor_Files_Cluster_Performance -eq $true) {
                Write-Log -Message "[DATA UPLOAD] Uploading Files Cluster $($Config.Target.Files_Cluster_CVM) Metrics to Influx" -Level Info
            
                #alter the file names so we have uniqe influx data
                $Original_Files = Get-ChildItem "$($OutputFolder)\Files_Cluster\*.csv"
                foreach ($File in $Original_Files) {
                    try {
                        Rename-Item -Path $File.FullName -NewName ($File.BaseName + " FilesHosting" + $File.Extension) -ErrorAction Stop
                    }
                    catch {
                        Write-Log -Message $_ -Level Error
                    }
                }
            
                $Files = Get-ChildItem "$($OutputFolder)\Files_Cluster\*.csv"
            
                foreach ($File in $Files) {
                    # We only care about cluster raw data here
                    if (($File.Name -like "cluster raw*")) {
                        Write-Log -Message "[DATA UPLOAD] Uploading $($File.name) to Influx" -Level Info
                        $BucketName = $($Config.Test.BucketName)
                        $DataUploadStopWatch = [system.Diagnostics.Stopwatch]::StartNew()
                        if (Start-InfluxUpload -influxDbUrl $Config.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $Config.Testinfra.InfluxToken -File $File -BucketName $BucketName) {
                            $DataUploadStopWatch.Stop()
                            $ElapsedTime = [math]::Round($DataUploadStopWatch.Elapsed.TotalSeconds, 2)
                            Write-Log -Message "[DATA UPLOAD] Took $($ElapsedTime) seconds to finish uploading File $($File.Name) to Influx" -Level Info
                        }
                        else {
                            $DataUploadStopWatch.Stop()
                            Write-Log -Message "[DATA UPLOAD] Error uploading $($File.name) to Influx" -Level Warn
                        }
                    }
                    else {
                        Write-Log -Message "[DATA UPLOAD] Skipped uploading File $($File.Name) to Influx" -Level Info
                    }
                }
            }
            #endregion Upload Files Hosting Data to Influx
            
            #region Upload Launcher Cluster Data to Influx
            if ($Config.Target.Monitor_Launcher_Cluster_Performance -eq $true) {
                Write-Log -Message "[DATA UPLOAD] Uploading Launcher Cluster $($Config.Target.Launcher_Cluster_CVM) Metrics to Influx" -Level Info

                #alter the file names so we have uniqe influx data
                $Original_Files = Get-ChildItem "$($OutputFolder)\Launcher_Cluster\*.csv"
                foreach ($File in $Original_Files) {
                    try {
                        Rename-Item -Path $File.FullName -NewName ($File.BaseName + " LauncherHosting" + $File.Extension) -ErrorAction Stop
                    }
                    catch {
                        Write-Log -Message $_ -Level Error
                    }
                }

                $Files = Get-ChildItem "$($OutputFolder)\Launcher_Cluster\*.csv"

                foreach ($File in $Files) {
                    # We only care about cluster raw data here
                    if (($File.Name -like "cluster raw*")) {
                        Write-Log -Message "[DATA UPLOAD] Uploading $($File.name) to Influx" -Level Info
                        $DataUploadStopWatch = [system.Diagnostics.Stopwatch]::StartNew()
                        if (Start-InfluxUpload -influxDbUrl $Config.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $Config.Testinfra.InfluxToken -File $File -BucketName $BucketName) {
                            $DataUploadStopWatch.Stop()
                            $ElapsedTime = [math]::Round($DataUploadStopWatch.Elapsed.TotalSeconds, 2)
                            Write-Log -Message "[DATA UPLOAD] Took $($ElapsedTime) seconds to finish uploading File $($File.Name) to Influx" -Level Info
                        }
                        else {
                            $DataUploadStopWatch.Stop()
                            Write-Log -Message "[DATA UPLOAD] Error uploading $($File.name) to Influx" -Level Warn
                        }
                    }
                    else {
                        Write-Log -Message "[DATA UPLOAD] Skipped uploading File $($File.Name) to Influx" -Level Info
                    }
                }
            }
            #endregion Upload Launcher Cluster Data to Influx
        }
        else {
            Write-Log -Message "[DATA UPLOAD] Skipping uploading Test Run Data to Influx" -Level Info
        }

        #endregion Upload Data to Influx

        if ($Config.Test.SkipLEMetricsDownload -eq $true){ 
            Write-Log -Message "Skipped download of LE Metrics so no analysis occuring" -Level Info
        } 
        else {
            $Testresult = import-csv "$OutputFolder\VSI-results.csv"
            $Appsuccessrate = $Testresult."Apps success" / $Testresult."Apps total" * 100
        }

        #region Slack update
        #----------------------------------------------------------------------------------------------------------------------------
        if ($Config.Test.SkipLEMetricsDownload -eq $true){
            if (-not $AzureMode.IsPresent) { 
                # This is not an Azure configuration
                $SlackMessage = "Testname: $($NTNXTestname) Run $i is finished on Cluster $($NTNXInfra.TestInfra.ClusterName)."
            }
            else {
                $SlackMessage = "Testname: $($NTNXTestname) Run $i is finished on Azure."
            }
        } 
        else {
            if (-not $AzureMode.IsPresent) { 
                # This is not an Azure configuration
                $SlackMessage = "Testname: $($NTNXTestname) Run $i is finished on Cluster $($NTNXInfra.TestInfra.ClusterName). $($Testresult.activesessionCount) sessions active of $($Testresult."login total") total sessions. EUXscore: $($Testresult."EUX score") - VSImax: $($Testresult.vsiMax). App Success rate: $($Appsuccessrate.tostring("#.###"))"
            }
            else {
                $SlackMessage = "Testname: $($NTNXTestname) Run $i is finished on Azure. $($Testresult.activesessionCount) sessions active of $($Testresult."login total") total sessions. EUXscore: $($Testresult."EUX score") - VSImax: $($Testresult.vsiMax). App Success rate: $($Appsuccessrate.tostring("#.###"))"
            }
        }
        Update-VSISlack -Message $SlackMessage -Slack $($NTNXInfra.Testinfra.Slack)

        if ($Config.Test.SkipLEMetricsDownload -ne $true){
            if ( -not $AzureMode.IsPresent) {
                # This is not an Azure configuration
                $FileName = Get-VSIGraphs -TestConfig $NTNXInfra -OutputFolder $OutputFolder -RunNumber $i -TestName $NTNXTestname -TestResult $Testresult

                if (Test-Path -path $Filename) {
                    $Params = @{
                        ImageURL     = $FileName 
                        SlackToken   = $Config.Testinfra.SlackToken 
                        SlackChannel = $Config.Testinfra.SlackChannel 
                        SlackTitle   = "$($Config.Target.ImagesToTest[0].Comment)_Run$($i)" 
                        SlackComment = "CPU and EUX score of $($Config.Target.ImagesToTest[0].Comment)_Run$($i)"
                    }
                    Update-VSISlackImage @params
                    $Params = $null
                }
                else {
                    Write-Log -Message "Image Failed to download and won't be uploaded to Slack. Check Logs for detail." -Level Warn
                }
            }
        }
        #endregion Slack update

        #region Finish Test Run
        #----------------------------------------------------------------------------------------------------------------------------

        #region Update Test Dashboard
        $params = @{
            ConfigFile     = $NTNXInfra
            TestName       = $NTNXTestname 
            RunNumber      = "$($i)" 
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
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
            InfluxUri      = $Config.TestInfra.InfluxDBurl 
            InfluxBucket   = $InfluxTestDashBucket 
            Status         = "Running" 
            CurrentPhase   = $CurrentTotalPhase 
            CurrentMessage = "Finished Test Run $($i)" 
            TotalPhase     = "$($TotalPhases)"
        }
        $null = Set-TestData @params
        $params = $null
        $CurrentTotalPhase++
        #endregion Update Test Dashboard

        #endregion Finish Test Run

    }
    #endregion Iterate through runs

    #region Clear Affinity from VMs
    if (-not $AzureMode.IsPresent) { 
        if ($NTNXInfra.Target.HypervisorType -eq "AHV") {
            $params = @{
                ClusterIP = $Config.Target.CVM
                CVMsshpassword = $Config.Target.CVMsshpassword
                VMnameprefix = $Config.Target.NamingPattern
            }
            $ClearAffinityFromVMS = Set-AffinityClear @Params
            if ([string]::IsNullOrEmpty($ClearAffinityFromVMS)) {
                Write-Log -Message "Affinity was not removed from VMs. Please check cluster." -Level Warn
            }
            $params = $null
        }
        if ($NTNXInfra.Target.HypervisorType -eq "ESXi" -and $Config.Target.ForceAlignVMToHost -eq $true) {
            $params = @{
                VCenter     = $Config.vSphere.vCenter
                User        = $Config.vSphere.User
                Password    = $Config.Vsphere.Password
                ClusterName = $Config.vSphere.ClusterName
                DataCenter  = $Config.vSphere.DataCenter
            }
            
            Set-VMwareClusterAffinityClear @params
            $params = $null
        }
    }
    #endregion Clear Affinity from VMs

    #region Analyze Run results
    #----------------------------------------------------------------------------------------------------------------------------
    $null = Get-VSIResults -TestName $NTNXTestname -Path $ScriptRoot
    #endregion Analyze Run results

    #region Slack update
    #----------------------------------------------------------------------------------------------------------------------------
    Update-VSISlackresults -TestName $NTNXTestname -Path $ScriptRoot
    $OutputFolder = "$($ScriptRoot)\testresults\$($NTNXTestname)"

    if ($Config.Test.SkipLEMetricsDownload -ne $true){ 
        $FileName = Get-VSIGraphs -TestConfig $NTNXInfra -OutputFolder $OutputFolder -TestName $NTNXTestname -TestResult $Testresult
    
        if (Test-Path -path $Filename) {
            $Params = @{
                ImageURL     = $FileName 
                SlackToken   = $Config.Testinfra.SlackToken 
                SlackChannel = $Config.Testinfra.SlackChannel 
                SlackTitle   = "$($Config.Target.ImagesToTest[0].Comment)" 
                SlackComment = "CPU and EUX scores of $($Config.Target.ImagesToTest[0].Comment) - All Runs"
            }
            Update-VSISlackImage @params
            $Params = $Null
        }
        else {
            Write-Log -Message "Image Failed to download and won't be uploaded to Slack. Check Logs for detail." -Level Warn
        }
    }
    #endregion Slack update
}
#endregion Execute Test

#region Stop Infrastructure Monitoring
if ($Config.Test.StartInfrastructureMonitoring -eq $true -and $Config.Test.ServersToMonitor) {
    Write-Log -Message "Stopping Infrastructure Monitoring" -Level Info
    Start-ServerMonitoring -ServersToMonitor $Config.Test.ServersToMonitor -Mode StopMonitoring -ServiceName "Telegraf"
}
#endregion Stop Infrastructure Monitoring

#region Stop Observer Monitoring
if (-not $AzureMode.IsPresent) {
    # This is not an Azure configuration
    if ($Config.Test.StartObserverMonitoring -eq $true -or $Config.Target.files_prometheus -eq $true) {
        Write-Log -Message "Stopping Observer Monitoring" -Level Info
        $params = @{
            prometheusip          = $VSI_Prometheus_IP
            prometheussshuser     = $VSI_Prometheus_sshuser
            prometheussshpassword = $VSI_Prometheus_sshpassword 
            Status                = "Stop"
        }
        $null = Set-CVMObserver @params
        $params = $null
    } 
    if ($Config.Target.files_prometheus -eq $true) {
        $params = @{
            Config                = $NTNXInfra
            Status                = "Stop"
        }
        $null = Set-FilesPromMonitor @params
        $params = $null
    }
}
#endregion Stop Observer Monitoring

#region shutdown citrix machines after final run
if (-not $AzureMode.IsPresent) { 
    if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
        if ($Config.Target.OrchestrationMethod -eq "SnapIn") {
            $Params = @{
                DDC            = $Config.Target.DDC
                CatalogName    = $Config.Target.DesktopPoolName
                MaxRecordCount = $Config.Target.MaxRecordCount
            }
            $CitrixMachinesFinalShutdown = Invoke-CVADMachineShutdown @Params
            $Params = $null
        }
        elseif ($config.Target.OrchestrationMethod -eq "API") {}
        if ($CitrixMachinesFinalShutdown -eq $true) {
            Write-Log -Message "All machines powered down ready for next test" -level Info
        } else {
            Write-Log -Message "Not all machines confirmed down. Check before next test run." -Level Warn
        }
    }
}
#endregion shutdown citrix machines after final run

#region Update Test Dashboard
$params = @{
    ConfigFile     = $NTNXInfra
    TestName       = $NTNXTestname 
    RunNumber      = "0" 
    InfluxUri      = $Config.TestInfra.InfluxDBurl 
    InfluxBucket   = $InfluxTestDashBucket 
    Status         = "Completed" 
    CurrentPhase   = $CurrentTotalPhase 
    CurrentMessage = "Test Complete" 
    TotalPhase     = "$($TotalPhases)"
}
$null = Set-TestData @params
$params = $null
#endregion Update Test Dashboard

#endregion Execute

Write-Log -Message "Script Finished" -Level Info

#region logfile cleanup
# Move the Temp Log file to the final location
try {
    $FinalLogPath = "$ScriptRoot\results\$($NTNXTestname)_Run1"
    # Cleanup blank lines in file
    $LogContent = Get-Content -path $LogOutputTempFile
    $LogContent = $LogContent | Where-Object { $_ -ne "" } | Set-Content -Path $LogOutputTempFile -Force
    # Move the file to the final location
    Move-Item -Path $LogOutputTempFile -Destination $FinalLogPath -Force -ErrorAction Stop
    # Rename the file to reflect the final name
    Rename-Item -Path "$FinalLogPath\$($LogOutputTempFile | Split-Path -leaf)" -NewName "$FinalLogPath\log_$($NTNXTestname).log" -Force -ErrorAction Stop
    $Date = Get-Date
    Write-Host "$([char]0x1b)[96m[$([char]0x1b)[97m$($Date)$([char]0x1b)[96m]$([char]0x1b)[97m INFO: LogFile saved to: $FinalLogPath\log_$($NTNXTestname).log"
}
catch {
    Write-Host "$([char]0x1b)[33m[$([char]0x1b)[33m$($Date)$([char]0x1b)[33m]$([char]0x1b)[33m WARNING: Failed to move logfile to final location. Logfile is still in $($LogOutputTempFile)"
}
# Remove the temp file variable
Remove-Variable -Name LogOutputTempFile -Scope global -ErrorAction SilentlyContinue
#endregion logfile cleanup

Exit 0
