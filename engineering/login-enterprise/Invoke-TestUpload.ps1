<##
.SYNOPSIS
.DESCRIPTION
.PARAMETER TestName
Mandatory. Test Name you want to upload the results for
.PARAMETER LogonMetricsOnly
Optional. Will execute upload of only Raw Logon Data. Use wisely.
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
    [string]$TestName,
    [Parameter(Mandatory = $false)]
    [switch]$AzureMode,
    [Parameter(Mandatory = $false)]
    [switch]$LogonMetricsOnly
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
$NTNXInfra = $config
#endregion Get Nutanix Infra

#region Upload Data to InfluxDB
#----------------------------------------------------------------------------------------------------------------------------
Write-Log -Message "Uploading Test Run Data to Influx" -Level Info
            
$TestDetail = $NTNXInfra.TestInfra.TestName -Split '_Run'
$Run = $TestDetail[1]

# Check and execute Logon Metrics only
if (-not $AzureMode.IsPresent) {
    if ($LogonMetricsOnly) {
        Write-Log -Message "[DATA UPLOAD] Processing Logon Metrics data uploads" -Level Info 
        # Get the test run files and start time
        $Files = Get-ChildItem "$($OutputFolder)\*.csv"
        $BucketName = $($NTNXInfra.Test.BucketName)

        # Loop through the test run data files and process each one
        foreach ($File in $Files) {
            if (($File.Name -like "Raw Login Times*")) {
                
                Write-Log -Message "[DATA UPLOAD] Uploading $($File.name) to Influx" -Level Info
                #Set Azure VM Value - If this is an Azure VM, we will be sending different tags in to Influx. If not, then it's business as usual.
                if ($NTNXInfra.AzureGuestDetails.IsAzureVM -eq $true) { $IsAzureVM = $true } else { $IsAzureVM = $false }
                $DataUploadStopWatch = [system.Diagnostics.Stopwatch]::StartNew()
                if (Start-InfluxUpload -influxDbUrl $NTNXInfra.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $NTNXInfra.Testinfra.InfluxToken -File $File -BucketName $BucketName -IsAzureVM $IsAzureVM) {
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

        Write-Log -Message "Script Finished" -Level Info
        Exit 0
    } 
}

# Get the boot files and start time
if (-not $AzureMode.IsPresent) {
    Write-Log -Message "[DATA UPLOAD] Processing Boot phase data uploads" -Level Info 
    #This is not an Azure Run
    $Files = Get-ChildItem "$($OutputFolder)\Boot\*.csv"

    # Build the Boot Bucket Name
    If ($($NTNXInfra.Test.BucketName) -eq "LoginDocuments") {
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
            if (Start-InfluxUpload -influxDbUrl $NTNXInfra.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $NTNXInfra.Testinfra.InfluxToken -File $File -BucketName $BucketName) {
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

Write-Log -Message "[DATA UPLOAD] Processing full test data uploads" -Level Info
# Get the test run files and start time
$Files = Get-ChildItem "$($OutputFolder)\*.csv"
$BucketName = $($NTNXInfra.Test.BucketName)

# Loop through the test run data files and process each one
foreach ($File in $Files) {
    if (($File.Name -like "Raw Timer Results*") -or ($File.Name -like "Raw Login Times*") -or ($File.Name -like "NetScaler Raw*") -or ($File.Name -like "host raw*") -or ($File.Name -like "files raw*") -or ($File.Name -like "cluster raw*") -or ($File.Name -like "raw appmeasurements*") -or ($File.Name -like "EUX-Score*") -or ($File.Name -like "EUX-timer-score*") -or ($File.Name -like "RDA*") -or ($File.Name -like "VM Perf Metrics*") -or ($File.Name -like "Telegraf*") -or ($File.Name -like "Prom*")) {
        Write-Log -Message "[DATA UPLOAD] Uploading $($File.name) to Influx" -Level Info
        #Set Azure VM Value - If this is an Azure VM, we will be sending different tags in to Influx. If not, then it's business as usual.
        if ($NTNXInfra.AzureGuestDetails.IsAzureVM -eq $true) { $IsAzureVM = $true } else { $IsAzureVM = $false }
        if ($File.Name -like "Prom*") {
            $BucketName = $($NTNXInfra.TestInfra.PromBucketName)
        } Else {
            $BucketName = $($NTNXInfra.Test.BucketName)
        }
        $DataUploadStopWatch = [system.Diagnostics.Stopwatch]::StartNew()
        if (Start-InfluxUpload -influxDbUrl $NTNXInfra.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $NTNXInfra.Testinfra.InfluxToken -File $File -BucketName $BucketName -IsAzureVM $IsAzureVM) {
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
#endregion Upload Data to InfluxDB

#region Upload Files Hosting Data to Influx
if (Test-Path -Path "$($OutputFolder)\Files_Cluster") {
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
            $DataUploadStopWatch = [system.Diagnostics.Stopwatch]::StartNew()
            if (Start-InfluxUpload -influxDbUrl $NTNXInfra.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $NTNXInfra.Testinfra.InfluxToken -File $File -BucketName $BucketName) {
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

#endregion Execute

Write-Log -Message "Script Finished" -Level Info
Exit 0