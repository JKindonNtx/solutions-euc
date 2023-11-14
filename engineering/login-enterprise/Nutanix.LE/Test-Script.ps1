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
- Update function descriptions and details per Dave defaults
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

#region Variables
# ============================================================================
# Variables
# ============================================================================

If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }
$Validated_Workload_Profiles = @("Task Worker", "Knowledge Worker")
$Validated_OS_Types = @("multisession", "singlesession")

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
    Exit 1
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
    Exit 1
}

if ($PSVersionTable.PSVersion.Major -gt 6) { 
    Write-Log -Message "You cannot use PowerShell $($PSVersionTable.PSVersion.Major) with Citrix snapins. Please revert to PowerShell 5.x" -Level Warn
    #Exit 1
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
        Exit 1
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
        Exit 1
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

#region Get Nutanix Infra
$NTNXInfra = Get-NTNXinfo -Config $config
#endregion Get Nutanix Infra

#endregion variable setting

#region Execute Test
#Set the multiplier for the Workloadtype. This adjusts the required MHz per user setting.
ForEach ($ImageToTest in $VSI_Target_ImagesToTest) {
    Set-VSIConfigurationVariables -ImageConfiguration $ImageToTest -ConfigurationFile $ConfigFile

    #region Set affinity
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
        Exit 1
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

    #region Setup testname
    Write-Log -Message "Setting up Test Details" -Level Info
    $NTNXid = (New-Guid).Guid.SubString(1,6)
    $NTNXTestname = "$($NTNXid)_$($VSI_Target_NodeCount)n_A$($NTNXInfra.Testinfra.AOSversion)_$($NTNXInfra.Testinfra.HypervisorType)_$($VSI_Target_NumberOfVMS)V_$($VSI_Target_NumberOfSessions)U_$LEWorkload"
    #endregion Setup testname

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

    #region AD Users

    #region Test Rampup

    #region Iteration through runs

    #region Update Slack

    #region Configure Citrix Desktop Pool

    #region Configure Folder Details for output

    #region Monitoring

    #region Citrix Desktop Pool Boot

    #region Build Tattoo 

    #region Set number of sessions per launcher

    #region Update the test params/create test if not exist

    #region Wait for VM's to have settled down

    #region Stop and cleanup monitoring job Boot phase

    #region Set RDA Source and Destination files and clean out source files if they still exist

    #region VM Idle state

    #region Nutanix Curator Stop

    #region Start the test

    #region Start monitoring

    #region Wait for test to finish

    #region Cleanup monitoring job

    #region Nutanix Curator Start

    #region Write config to OutputFolder

    #region Check for RDA File and if exists then move it to the output folder

    #region Upload Data to Influx

    $CurrentPhase = "15"
    
    if($NTNXInfra.Test.UploadResults) {
        Write-Log -Message "Uploading Test Run Data to Influx" -Level Info
        
        $TestDetail = $NTNXInfra.TestInfra.TestName -Split '_Run'
        $Run = $TestDetail[1]

        # Get the boot files and start time
        $Files = Get-ChildItem "$($OutputFolder)\Boot\*.csv"
        $Started = $($NTNXInfra.TestInfra.Bootstart)

        # Build the Boot Bucket Name
        If ($($NTNXInfra.Test.BucketName) -eq "LoginDocuments") {
            $BucketName = "BootBucket"
        } Else {
            $BucketName = "BootBucketRegression"
        }

        # Loop through the boot files and process each one
        foreach($File in $Files){
            if(($File.Name -like "host raw*") -or ($File.Name -like "cluster raw*")){
                Write-Log -Message "Uploading $($File.name) to Influx" -Level Info
                $null = Set-TestData -ConfigFile "$($OutputFolder)\Testconfig.json" -TestName $($NTNXInfra.TestInfra.TestName) -RunNumber $Run -InfluxUri $NTNXInfra.TestInfra.InfluxDBurl -InfluxBucket "Tests" -Status "Running" -CurrentPhase $CurrentPhase -CurrentMessage "Uploading Boot File $($File.name) to Influx"
                if(Start-InfluxUpload -influxDbUrl $NTNXInfra.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $NTNXInfra.Testinfra.InfluxToken -File $File -Started $Started -BucketName $BucketName) {
                    Write-Log -Message "Finished uploading Boot File $($File.Name) to Influx" -Level Info
                } else {
                    Write-Log -Message "Error uploading $($File.name) to Influx" -Level Warn
                }
            } else {
                Write-Log -Message "Skipped uploading Boot File $($File.Name) to Influx" -Level Info
            }
        }

        # Get the test run files and start time
        $Files = Get-ChildItem "$($OutputFolder)\*.csv"
        $vsiresult = Import-CSV "$($OutputFolder)\VSI-results.csv"
        $Started = $vsiresult.started
        $BucketName = $($NTNXInfra.Test.BucketName)

        # Loop through the test run data files and process each one
        foreach($File in $Files){
            if(($File.Name -like "Raw Timer Results*") -or ($File.Name -like "Raw Login Times*") -or ($File.Name -like "NetScaler Raw*") -or ($File.Name -like "host raw*") -or ($File.Name -like "files raw*") -or ($File.Name -like "cluster raw*") -or ($File.Name -like "raw appmeasurements*") -or ($File.Name -like "EUX-Score*") -or ($File.Name -like "EUX-timer-score*") -or ($File.Name -like "RDA*")){
                Write-Log -Message "Uploading $($File.name) to Influx" -Level Info
                $UploadResult = Start-InfluxUpload -influxDbUrl $NTNXInfra.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $NTNXInfra.Testinfra.InfluxToken -File $File -Started $Started -BucketName $BucketName
                if($UploadResult.Return -eq $true){
                    Write-Log -Message "Finished uploading File $($File.Name) to Influx" -Level Info -Update
                    $UploadStatus = "Finished"
                } else {
                    if($UploadResult.TagValidated -eq $false){
                        Write-Log -Message "Error with empty tag value - check json test result file" -Level Warn
                        $UploadStatus = "Empty Tag Value"
                    } else {
                        Write-Log -Message "Error uploading $($File.name) to Influx" -Level Warn
                        $UploadStatus = "Errored"
                    }
                }
            } else {
                Write-Log -Message "Skipped uploading File $($File.Name) to Influx" -Level Info
            }
            $null = Set-TestData -ConfigFile "$($OutputFolder)\Testconfig.json" -TestName $($NTNXInfra.TestInfra.TestName) -RunNumber $Run -InfluxUri $NTNXInfra.TestInfra.InfluxDBurl -InfluxBucket "Tests" -Status "Running" -CurrentPhase $CurrentPhase -CurrentMessage "Uploading $($File.name) to Influx - Status: $($UploadStatus)"
        }

    } else {
        Write-Log -Message "Skipping uploading Test Run Data to Influx" -Level Info
    }

    $null = Set-TestData -ConfigFile "$($OutputFolder)\Testconfig.json" -TestName $($NTNXInfra.TestInfra.TestName) -RunNumber $Run -InfluxUri $NTNXInfra.TestInfra.InfluxDBurl -InfluxBucket "Tests" -Status "Running" -CurrentPhase $CurrentPhase -CurrentMessage "Finished Region - Upload Data to Influx"

    #endregion Upload Data to Influx

    #region Slack update

    #region Analyze Run results

    #region Slack update
}

#endregion Execute Test

#endregion Execute

Write-Log -Message "Script Finished" -Level Info
Exit 0