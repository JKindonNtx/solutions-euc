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
.PARAMETER Buckets
Mandatory. An array of Buckets the Test Data resides in.
.PARAMETER Tests
Mandatory. An array of Test Names to be removed
.PARAMETER Run
Optional. The run number of the test to remove.
.NOTES
None
.EXAMPLE
Remove-TestData-API.ps1 -Buckets "LoginDocuments","LoginRegression" -Tests "Test1","Test2","Test3" -ConfigFile c:\temp\config.json

.EXAMPLE
Remove-TestData-API.ps1 -Buckets "LoginDocuments","LoginRegression" -Tests "Test1","Test2","Test3" -InfluxDBUrl "http://10.57.64.25:8086" -Org "Nutanix" -Token "MY_TOKEN_HERE"

.EXAMPLE
Remove-TestData-API.ps1 -Buckets "LoginDocuments","LoginRegression" -Tests "Test1" -Run "1" -InfluxDBUrl "http://10.57.64.25:8086" -Org "Nutanix" -Token "MY_TOKEN_HERE"
-----------------------------------------------------------------------------------------
#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $false)][string]$ConfigFile,
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $true)][array]$Buckets,
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $true)][array]$Tests,
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $false)][string]$influxDBUrl,
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $false)][string]$Org,
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $false)][string]$Token,
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $false)][string]$start = "2022-12-30T00:00:00.000000000Z",
    [Parameter(ValuefromPipelineByPropertyName = $true,Mandatory = $false)][string]$stop = "2023-01-14T00:00:00.000000000Z",
    [Parameter(ValuefromPipelineByPropertyName = $true,mandatory = $false)][string]$Run
)
#endregion Params

#region Variables
# ============================================================================
# Variables
# ============================================================================

If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }
$Valid_Buckets = @("LoginDocuments","LoginRegression","Tests")

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
if (($Tests | Measure-Object).Count -gt 1 -and (-not ([string]::IsNullOrEmpty($Run)))) {
    Write-Log -Message "You cannot specify a Run ID with more than one test defined. Please specify a single test and associated Run ID" -Level Warn
    Break
}
#endregion param validate

#Region Execute
# ============================================================================
# Execute
# ============================================================================

#region Validate Bucket ###////KINDON //DAVE can you check this logic here - Do we need to cater for it in an iterative approach like I Have, we have a list of tests, and a list of buckets - 
# it's going to loop through and if the bucket isn't found or doesn't have test data, it will just loop through
#----------------------------------------------------------------------------------------------------------------------------
<#
if($Bucket -eq "LoginDocuments"){
    $MainBucket = $Bucket
    $BootBucket = "BootBucket"
} else {
    if($Bucket -eq "LoginRegression"){
        $MainBucket = $Bucket
        $BootBucket = "BootBucketRegression"
    } else {
        if($Bucket -eq "Tests"){
            $MainBucket = $Bucket
        } else {
            Write-Host "$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: Bucket not currently supported. Exit script" #I've moved this to the loop logic
            Exit 1
        }
    }
}
#>

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

#region Param Output 
#----------------------------------------------------------------------------------------------------------------------------
Write-Log -Message "Configuration File is:        $($ConfigFile)" -Level Validation
Write-Log -Message "Test List is:                 $($Tests)" -Level Validation
Write-Log -Message "Bucket List is:               $($Buckets)" -Level Validation
Write-Log -Message "InfluxDB URL is:              $($influxDBUrl)" -Level Validation
Write-Log -Message "Org is:                       $($Org)" -Level Validation
Write-Log -Message "Token is:                     $($Token)" -Level Validation
if (-not ([String]::IsNullOrEmpty($Run))) {
    Write-Log -Message "Run is:                     $($Token)" -Level Validation
}
#endregion Param Output

#region delete test data
$Headers = @{
    "Content-Type"  = "application/json";
    "Authorization" = "Token $Token";
}

$TotalTests = ($Tests | Measure-Object).Count
    $CurrentTest = 1
    foreach ($Test in $Tests) {
        Write-Log -Message "Processing Test $($CurrentTest) of $($TotalTests): $($Test)" -Level Info
        foreach ($Bucket in $Buckets) {
            if ($Bucket -notin $Valid_Buckets) {
                Write-Log -Message "Bucket $($Bucket) is not supported. Skipping" -Level Warn
                Continue
            }
            $Method = "Post"
            $RequestUri = "$($influxDBUrl)/api/v2/delete?org=$($Org)&bucket=$($Bucket)"
            if (-not ($Run)) {
                #delete the whole test
                $PayloadContent = [PSCustomObject]@{
                    predicate = "_measurement=""$Test"""
                    start = "$Start"
                    stop = "$Stop"
                }
                $Payload = (ConvertTo-Json $PayloadContent)
            }
            else {
                #delete the run
                $PayloadContent = [PSCustomObject]@{
                    predicate = "_measurement=""$Test"" and Run=""$Run"""
                    start = "$Start"
                    stop = "$Stop"
                }
                $Payload = (ConvertTo-Json $PayloadContent)
            }
        
            try {
                if (-not ($Run)) {
                    Write-Log -Message "Deleting data from Influx DB $($influxDBUrl) in org $($Org) for test: $($Test) in bucket $($Bucket). Be patient" -Level Info
                }
                else {
                    Write-Log -Message "Deleting data from Influx DB $($influxDBUrl) in org $($Org) for test: $($Test) in bucket $($Bucket) with run $($Run). Be patient" -Level Info
                }
                
                $delete_test = Invoke-WebRequest -Uri $RequestUri -Method $Method -Body $Payload -Headers $Headers
                if ($delete_test.StatusCode -eq "204") {
                    Write-Log -Message "Test data deleted or not found" -Level Info
                }
                else {
                    Write-Log -Message "$($delete_test)" -Level Info
                }
            }
            catch {
                Write-Log -Message $_ -Level Error
            }
        }
        $CurrentTest ++
    }

#endregion delete test data

#endregion Execute

Write-Log -Message "Script Finished" -Level Info
Exit 0