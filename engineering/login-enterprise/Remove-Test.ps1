<##
.SYNOPSIS
.DESCRIPTION
.PARAMETER ConfigFile
Mandatory. The JSON file containing the test configuration
.PARAMETER Test
Mandatory. The Test Name to be removed
.PARAMETER Bucket
Mandatory. The Bucket the Test Data resides in.
.PARAMETER Run
Optional. The run number of the test to remove.
.NOTES
None

-----------------------------------------------------------------------------------------
#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigFile,

    [Parameter(Mandatory = $true)]
    [string]$Test,

    [Parameter(Mandatory = $true)]
    [string]$Bucket,

    [Parameter(Mandatory = $false)]
    [string]$Run
)
#endregion Params

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

#region Build Influx Path
#----------------------------------------------------------------------------------------------------------------------------

Write-Log -Message "Successfully imported $var_ModuleName Module" -Level Info
$InfluxPath = "$($ScriptRoot)\$($var_ModuleName)\$($var_ModuleName).Reporting\resources" 

#endregion Build Influx Path

#region Param Output
#----------------------------------------------------------------------------------------------------------------------------
Write-Log -Message "Configuration File is:        $($ConfigFile)" -Level Validation
Write-Log -Message "Test Name is:                 $($Test)" -Level Validation
Write-Log -Message "Bucket Name is:               $($Bucket)" -Level Validation
#endregion Param Output

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

#region Remove Test
#----------------------------------------------------------------------------------------------------------------------------
if(!([string]::IsNullOrEmpty($Run))){
    Write-Log -Message "Processing Delete $($Test) Run Number $($Run)" -Level Info
    Write-Log -Message "Please wait while the data is removed (this may take some time)" -Level Info
    $null = Remove-TestData -InfluxPath "$($InfluxPath)" -HostUrl "$($config.InfluxDBurl)" -Org "$($config.InfluxOrg)" -Bucket "$($Bucket)" -Test "$($Test)" -Run "$($Run)" -Token "$($config.InfluxToken)"
    Write-Log -Message "$($Test) Run Number $($Run) Deleted" -Level Info
} else {
    Write-Log -Message "Processing Delete $($Test) All Runs" -Level Info
    Write-Log -Message "Please wait while the data is removed (this may take some time)" -Level Info
    $null = Remove-TestData -InfluxPath "$($InfluxPath)" -HostUrl "$($config.InfluxDBurl)" -Org "$($config.InfluxOrg)" -Bucket "$($Bucket)" -Test "$($Test)" -Token "$($config.InfluxToken)"
    Write-Log -Message "$($Test) Deleted" -Level Info
}
#endregion Remove Test

#endregion Execute

Write-Log -Message "Script Finished" -Level Info
Break #Temporary! Replace with #Exit 0