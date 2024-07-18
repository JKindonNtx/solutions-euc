<##
.SYNOPSIS
Removes test data from InfluxDB
.DESCRIPTION
Removes test data from InlfuxDB via API
.PARAMETER ConfigFile
Optional. A JSON file containing the test configuration. Replaces influxDBUrl, Token and Org parameters
.PARAMETER influxDBUrl
Optional. Used if not specifying a ConfigFile. The URL of the Influx DB. "http://10.57.64.25:8086"
.PARAMETER Token
Optional. Used if not specifying a ConfigFile. The Auth Token for InfluxDB
.PARAMETER Org
Optional. Used if not specifying a ConfigFile. The Org for the Data. "Nutanix"
.PARAMETER Bucket
Mandatory.  The bucket to remove the data from. "LoginDocuments", "LoginRegression", "Tests" or "AzurePerfData"
.PARAMETER Test
Mandatory. The test to remove the data for.
.PARAMETER Run
Optional. The run number of the test to remove.
.PARAMETER LogonMetricsOnly
Optional. If specified, only the logon metrics will be removed.
.NOTES
None
-----------------------------------------------------------------------------------------
#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $false)][string]$ConfigFile,
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $true)][ValidateSet("LoginDocuments", "LoginRegression", "Tests", "AzurePerfData")][string]$Bucket,
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $true)][string]$Test,
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $false)][string]$influxDBUrl,
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $false)][string]$Org,
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $false)][string]$Token,
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $false)][string]$start = "2022-12-30T00:00:00.000000000Z",
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $false)][string]$stop = "2023-01-14T00:00:00.000000000Z",
    [Parameter(ValuefromPipelineByPropertyName = $true,mandatory = $false)][string]$Run,
    [Parameter(ValuefromPipelineByPropertyName = $true,mandatory = $false)][switch]$LogonMetricsOnly
)
#endregion Params

#region functions
function Remove-Influx-Test-Data {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)][string]$RequestUri,
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Payload,
        [Parameter(Mandatory = $true)][string]$Headers
    )

    begin {}

    process {
        try {
            $delete_test = Invoke-WebRequest -Uri $RequestUri -Method $Method -Body $Payload -Headers $Headers -ErrorAction Stop
            if ($delete_test.StatusCode -eq "204") {
                Write-Log -Message "Test data deleted or not found" -Level Info
            }
            else {
                Write-Log -Message "$($delete_test.StatusCode) with $($delete_test.StatusDescription)" -Level Warn
            }
        }
        catch {
            Write-Log -Message $_ -Level Warn
        }
    }

    end {}

}
#endregion functions

#region Variables
# ============================================================================
# Variables
# ============================================================================

If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }

#endregion Variables

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

#region param validate
if ([string]::IsNullOrEmpty($ConfigFile) -and [string]::IsNullOrEmpty($influxDBUrl) -or [string]::IsNullOrEmpty($Token) -or [string]::IsNullOrEmpty($Org)) {
    Write-Log -Message "You must specify either a configuration file, or the appropriate Influx Params" -Level Warn
    Break
}
if ($ConfigFile) {
    Write-Log -Message "Configuration File $($ConfigFile) has been selected and will override any other parameter configuration associated with Influx configuration" -Level Info
}
#endregion param validate

#Region Execute
# ============================================================================
# Execute
# ============================================================================

#region Validate Bucket
#----------------------------------------------------------------------------------------------------------------------------
if($Bucket -eq "LoginDocuments"){
    $MainBucket = $Bucket
    $BootBucket = "BootBucket"
} else {
    if($Bucket -eq "LoginRegression"){
        $MainBucket = $Bucket
        $BootBucket = "BootBucketRegression"
    } else {
        if($Bucket -eq "Tests" -or $Bucket -eq "AzurePerfData"){
            $MainBucket = $Bucket
        } else {
            Write-Host "$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: Bucket not currently supported. Exit script"
            Exit 1
        }
    }
}

#endregion Validate Bucket

#region Config File
#----------------------------------------------------------------------------------------------------------------------------
if ($ConfigFile) {
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

    $influxDBUrl = $config.InfluxDBurl
    $Org = $config.InfluxOrg
    $Token = $config.InfluxToken
}


#endregion Config File

#-------------------------------------------
# Filter out the URL to just the base URL Required for API Calls - we reset this later
#-------------------------------------------
$regex = '^(https?://[^/]+)'
if ($influxDBUrl -match $regex) {
    $InfluxDBUrl = $matches[1]
}


#region Param Output 
#----------------------------------------------------------------------------------------------------------------------------
Write-Log -Message "Configuration File is:        $($ConfigFile)" -Level Validation
Write-Log -Message "Test is:                      $($Test)" -Level Validation
Write-Log -Message "Bucket is:                    $($Bucket)" -Level Validation
Write-Log -Message "InfluxDB URL is:              $($influxDBUrl)" -Level Validation
Write-Log -Message "Org is:                       $($Org)" -Level Validation
Write-Log -Message "Token is:                     $($Token)" -Level Validation
if (-not ([String]::IsNullOrEmpty($Run))) {
    Write-Log -Message "Run is:                     $($Run)" -Level Validation
}
Write-Log -Message "Logon Metrics only is:         $($LogonMetricsOnly)" -Level Validation
#endregion Param Output

#region delete test data
#-------------------------------------------
# Set the Request Headers
#-------------------------------------------
$Headers = @{
    "Content-Type"  = "application/json";
    "Authorization" = "Token $Token";
}
$Method = "Post"

#Process the test Removal
if(!([string]::IsNullOrEmpty($Run))){
    Write-Log -Message "Processing Delete $($Test) Run Number $($Run)" -Level Info
    if ($LogonMetricsOnly) {
        Write-Log -Message "Please wait while the Logon data is removed (this may take some time)" -Level Info
        $Values_to_delete = @('total_login_time','connection','user_profile','group_policies')
        foreach ($Value in $Values_to_delete) {
            Write-Log -Message "Processing delete of $($Value) for Run $($Run)" -Level Info
            #-------------------------------------------
            # Build the API Payload
            #-------------------------------------------
            $RequestUri = "$($influxDBUrl)/api/v2/delete?org=$($Org)&bucket=$($Bucket)"
            $PayloadContent = [PSCustomObject]@{
                predicate = "_measurement=""$Test"" AND Run=""$Run"" AND id=""$Value"""
                start = "$Start"
                stop = "$Stop"
            }
            $Payload = (ConvertTo-Json $PayloadContent)
            #-------------------------------------------
            # Execute the deletion
            #-------------------------------------------
            Remove-Influx-Test-Data -RequestUri $RequestUri -Method $Method -Payload $Payload -Headers $Headers
            #$null = Remove-TestData -InfluxPath "$($InfluxPath)" -HostUrl "$($config.InfluxDBurl)" -Org "$($config.InfluxOrg)" -Bucket "$($MainBucket)" -Test "$($Test)" -Run "$($Run)" -Token "$($config.InfluxToken)" -LogonMetricsOnly
        }

    } else {
        Write-Log -Message "Please wait while the data is removed (this may take some time)" -Level Info
        #-------------------------------------------
        # Build the API Payload - Delete the specified run
        #-------------------------------------------
        $RequestUri = "$($influxDBUrl)/api/v2/delete?org=$($Org)&bucket=$($Bucket)"
        $PayloadContent = [PSCustomObject]@{
            predicate = "_measurement=""$Test"" AND Run=""$Run"""
            start = "$Start"
            stop = "$Stop"
        }
        $Payload = (ConvertTo-Json $PayloadContent)
        #-------------------------------------------
        # Execute the deletion
        #-------------------------------------------
        Remove-Influx-Test-Data -RequestUri $RequestUri -Method $Method -Payload $Payload -Headers $Headers
        #$null = Remove-TestData -InfluxPath "$($InfluxPath)" -HostUrl "$($config.InfluxDBurl)" -Org "$($config.InfluxOrg)" -Bucket "$($MainBucket)" -Test "$($Test)" -Run "$($Run)" -Token "$($config.InfluxToken)"
        
        Write-Log -Message "Processing Boot Information Delete $($Test) Run Number $($Run)" -Level Info
        if(!($MainBucket -eq "Tests")){
            Write-Log -Message "Please wait while the data is removed (this may take some time)" -Level Info
            #-------------------------------------------
            # Build the API Payload - Delete the specified run - Boot Bucket
            #-------------------------------------------
            $RequestUri = "$($influxDBUrl)/api/v2/delete?org=$($Org)&bucket=$($BootBucket)"
            $PayloadContent = [PSCustomObject]@{
                predicate = "_measurement=""$Test"" AND Run=""$Run"""
                start = "$Start"
                stop = "$Stop"
            }
            $Payload = (ConvertTo-Json $PayloadContent)
            #-------------------------------------------
            # Execute the deletion
            #-------------------------------------------
            Remove-Influx-Test-Data -RequestUri $RequestUri -Method $Method -Payload $Payload -Headers $Headers
            #$null = Remove-TestData -InfluxPath "$($InfluxPath)" -HostUrl "$($config.InfluxDBurl)" -Org "$($config.InfluxOrg)" -Bucket "$($BootBucket)" -Test "$($Test)" -Run "$($Run)" -Token "$($config.InfluxToken)"

            Write-Log -Message "$($Test) Run Number $($Run) Deleted" -Level Info
        }
    }
    
} else {
    Write-Log -Message "Processing Delete $($Test) All Runs" -Level Info
    if ($LogonMetricsOnly) {
        Write-Log -Message "Please wait while the Logon data is removed (this may take some time)" -Level Info
        $Values_to_delete = @('total_login_time','connection','user_profile','group_policies')
        foreach ($Value in $Values_to_delete) {
            Write-Log -Message "Processing delete of $($Value) for Run $($Run)" -Level Info
            #-------------------------------------------
            # Build the API Payload
            #-------------------------------------------
            $RequestUri = "$($influxDBUrl)/api/v2/delete?org=$($Org)&bucket=$($Bucket)"
            $PayloadContent = [PSCustomObject]@{
                predicate = "_measurement=""$Test"" AND id=""$Value"""
                start = "$Start"
                stop = "$Stop"
            }
            $Payload = (ConvertTo-Json $PayloadContent)
            #-------------------------------------------
            # Execute the deletion
            #-------------------------------------------
            Remove-Influx-Test-Data -RequestUri $RequestUri -Method $Method -Payload $Payload -Headers $Headers
            #$null = Remove-TestData -InfluxPath "$($InfluxPath)" -HostUrl "$($config.InfluxDBurl)" -Org "$($config.InfluxOrg)" -Bucket "$($MainBucket)" -Test "$($Test)" -Token "$($config.InfluxToken)" -LogonMetricsOnly
        }

    } else {
        Write-Log -Message "Please wait while the data is removed (this may take some time)" -Level Info
        
        #-------------------------------------------
        # Build the API Payload - Delete the whole test
        #-------------------------------------------
        $RequestUri = "$($influxDBUrl)/api/v2/delete?org=$($Org)&bucket=$($Bucket)"
        $PayloadContent = [PSCustomObject]@{
            predicate = "_measurement=""$Test"""
            start = "$Start"
            stop = "$Stop"
        }
        $Payload = (ConvertTo-Json $PayloadContent)
        #-------------------------------------------
        # Execute the deletion
        #-------------------------------------------
        Remove-Influx-Test-Data -RequestUri $RequestUri -Method $Method -Payload $Payload -Headers $Headers
        #$null = Remove-TestData -InfluxPath "$($InfluxPath)" -HostUrl "$($config.InfluxDBurl)" -Org "$($config.InfluxOrg)" -Bucket "$($MainBucket)" -Test "$($Test)" -Token "$($config.InfluxToken)"
        
        Write-Log -Message "Processing Boot Information Delete $($Test) All Runs" -Level Info
        if(!($MainBucket -eq "Tests")){
            Write-Log -Message "Please wait while the data is removed (this may take some time)" -Level Info
            #-------------------------------------------
            # Build the API Payload - Delete the whole test - Boot Bucket
            #-------------------------------------------
            $RequestUri = "$($influxDBUrl)/api/v2/delete?org=$($Org)&bucket=$($BootBucket)"
            $PayloadContent = [PSCustomObject]@{
                predicate = "_measurement=""$Test"""
                start = "$Start"
                stop = "$Stop"
            }
            $Payload = (ConvertTo-Json $PayloadContent)
            #-------------------------------------------
            # Execute the deletion
            #-------------------------------------------
            Remove-Influx-Test-Data -RequestUri $RequestUri -Method $Method -Payload $Payload -Headers $Headers
            #$null = Remove-TestData -InfluxPath "$($InfluxPath)" -HostUrl "$($config.InfluxDBurl)" -Org "$($config.InfluxOrg)" -Bucket "$($BootBucket)" -Test "$($Test)" -Token "$($config.InfluxToken)"

            Write-Log -Message "$($Test) Deleted" -Level Info
        }
    }
}

#endregion delete test data

#endregion Execute

Write-Log -Message "Script Finished" -Level Info
Exit 0
