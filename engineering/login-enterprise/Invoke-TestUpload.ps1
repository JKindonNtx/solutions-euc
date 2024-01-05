<##
.SYNOPSIS
.DESCRIPTION
.PARAMETER TestName
Mandatory. Test Name you want to upload the results for
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
    [string]$TestName
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
    Exit 1
}
#endregion Nutanix Module Import

#region Script Variables
#----------------------------------------------------------------------------------------------------------------------------
$OutputFolder = "$ScriptRoot\results\$Testname"
$ConfigFile = "$OutputFolder\testconfig.json"
Set-VSIConfigurationVariables -ConfigurationFile $ConfigFile
#endregion Script Variables

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

#region Get Nutanix Infra
#----------------------------------------------------------------------------------------------------------------------------
$NTNXInfra = Get-NTNXinfo -Config $config
#endregion Get Nutanix Infra

#region Upload Data to InfluxDB
#----------------------------------------------------------------------------------------------------------------------------
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
#endregion Upload Data to InfluxDB

#region Upload Files Hosting Data to Influx
if (Test-Path -Path "$($OutputFolder)\Files_Cluster") {
    Write-Log -Message "Uploading Files Cluster Metrics to Influx" -Level Info

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
#endregion Upload Files Hosting Data to Influx

#endregion Execute

Write-Log -Message "Script Finished" -Level Info
Exit 0