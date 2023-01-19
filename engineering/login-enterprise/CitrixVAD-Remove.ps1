
Param(
    $ConfigFile = ".\ExampleConfig.jsonc",
    $ReportConfigFile = ".\ReportConfigurationNTNX.jsonc",
    [switch]$Force


)
If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }
Import-Module $ScriptRoot\modules\VSI.AD -Force
Import-Module $ScriptRoot\modules\VSI.LoginEnterprise -Force
Import-Module $ScriptRoot\modules\VSI.ResourceMonitor.NTNX -Force
Import-Module $ScriptRoot\modules\VSI.Target.CitrixVAD -Force
Import-Module $ScriptRoot\modules\VSI.AutomationToolkit -Force

Add-PSSnapin Citrix*

Set-VSIConfigurationVariables -ConfigurationFile $ConfigFile

#region RunTest
#Set the multiplier for the Workloadtype. This adjusts the required MHz per user setting.

Set-VSIConfigurationVariables -ImageConfiguration $ImageToTest
$networkMap = @{ "0" = "XDHyp:\HostingUnits\" + $VSI_Target_HypervisorConnection +"\"+ $VSI_Target_HypervisorNetwork +".network" }
Remove-VSICTXDesktopPool -ParentVM $VSI_Target_ParentVM `
-HypervisorConnection $VSI_Target_HypervisorConnection `
-Networkmap $networkMap `
-CpuCount $VSI_Target_NumCPUs `
-CoresCount $VSI_Target_NumCores `
-MemoryGB $VSI_Target_MemoryGB `
-NamingPattern $VSI_Target_NamingPattern `
-OU $VSI_Target_ADContainer `
-DomainName $VSI_Target_DomainName `
-SessionsSupport $VSI_Target_SessionsSupport `
-DesktopPoolName $VSI_Target_DesktopPoolName `
-ZoneName $VSI_Target_ZoneName `
-Force:$Force.IsPresent `
-EntitledGroup $VSI_Users_BaseName `
-SkipImagePrep $VSI_Target_SkipImagePrep `
-FunctionalLevel $VSI_Target_FunctionalLevel `
-DDC $VSI_Target_DDC

#endregion