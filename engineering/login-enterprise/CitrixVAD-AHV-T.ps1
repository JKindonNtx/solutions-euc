
Param(
    $ConfigFile = ".\ExampleConfig.jsonc",
    $ReportConfigFile = ".\ReportConfiguration.jsonc",
    [switch]$Force,
    [switch]$SkipWaitForIdleVMs,
    [switch]$SkipPDFExport,
    [switch]$SkipADUsers,
    [switch]$SkipLEUsers,
    [switch]$SkipLaunchers


)
If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }
Import-Module $ScriptRoot\modules\VSI.AD -Force
Import-Module $ScriptRoot\modules\VSI.LoginEnterprise -Force
Import-Module $ScriptRoot\modules\VSI.ResourceMonitor.NTNX -Force
Import-Module $ScriptRoot\modules\VSI.ResourceMonitor.vCenter -Force
Import-Module $ScriptRoot\modules\VSI.Target.CitrixVAD -Force
Import-Module $ScriptRoot\modules\VSI.Target.HorizonView -Force
Import-Module $ScriptRoot\modules\VSI.AutomationToolkit -Force

Add-PSSnapin Citrix*

Set-VSIConfigurationVariables -ConfigurationFile $ConfigFile

ForEach ($ImageToTest in $VSI_Target_ImagesToTest) {
    Set-VSIConfigurationVariables -ImageConfiguration $ImageToTest
    Connect-VSICTX -DDC $VSI_Target_DDC

  
    for ($i = 1; $i -le $VSI_Target_ImageIterations; $i++) {
        
  
        $Storage_uuid=Get-NTNXStorageUUID -Storage $VSI_Target_CVM_storage
        write-host "Storage UUID is:" $storage_uuid
        $Hostuuid=Get-NTNXHostUUID -NTNXHost $VSI_Target_NTNXHost
        write-host "Host UUID is:" $Hostuuid 
        $IPMI_ip=Get-NTNXHostIPMI -NTNXHost $VSI_Target_NTNXHost
        write-host "Host IPMI is:" $IPMI_ip
        $OutputFolder = "$ScriptRoot\results\TestSven"
        $monitoringJob = Start-VSINTNXMonitoring -OutputFolder $OutputFolder -DurationInMinutes 5 -RampupInMinutes 5 -Hostuuid $Hostuuid -IPMI_ip $IPMI_ip -AsJob
        
        Start-sleep 60
  

    }

}
#endregion