
Param(
    $Testname
)
If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }
Import-Module $ScriptRoot\modules\VSI.ResourceMonitor.NTNX -Force
Import-Module $ScriptRoot\modules\VSI.AutomationToolkit -Force

$OutputFolder = "$ScriptRoot\results\$Testname"
$ConfigFile = "$OutputFolder\testconfig.json"
Set-VSIConfigurationVariables -ConfigurationFile $ConfigFile


#endregion
$configFile = Get-Content -Path $ConfigFile
$config = $configFile | ConvertFrom-Json
# Get Infra-info
$NTNXInfra = Get-NTNXinfo -Config $config
# End Get Infra-info 


# Upload Config to Influx
if($NTNXInfra.Test.UploadResults) {
    Start-NTNXInfluxUpload -influxDbUrl $NTNXInfra.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $NTNXInfra.Testinfra.InfluxToken -Boot $true
    Start-NTNXInfluxUpload -influxDbUrl $NTNXInfra.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $NTNXInfra.Testinfra.InfluxToken -Boot $false
}


#endregion