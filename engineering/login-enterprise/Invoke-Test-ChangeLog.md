# Changelog for script alterations and additions

| Date | Author | Detail | 
| --- | --- | --- |

| 08.12.2023 | Sven | Added broker version autofill |
#### Invoke=Test.ps1
Added line 507 (will add broker version for Citrix to the final config.json): 
$NTNXInfra.Target.DesktopBrokerVersion = (Get-BrokerController -AdminAddress $VSI_Target_DDC).ControllerVersion[0]

| 07.12.2023 | Sven/James | Removed reportconfiguration.jsonc |
#### Invoke-Test.ps1
Remove Param Description - Line 6
Remove Parameter from Invoke-Test.ps1 - Line43
Remove Validation - Line 110
Remove from Param Block - Line 877 -> IMPACTS Start-VSINTNXMonitoring
Remove from Param Block - Line 1279 -> IMPACTS Start-VSINTNXMonitoring
Remove from Param Block - Line 1294 -> IMPACTS Start-VSINTNXMonitoring
Remove from Param Block - Line 1344 -> IMPACTS Start-NTNXFilesMonitoring

#### Readme
Remove from Readme - Line 57

#### Start-VSINTNXMonitoring
Remove Param - Line 10
Remove JSON conversion - Line 17
Remove from Monitoring Script Blog - Line 32
Remove from Job Creation - Line 109 and Line 114

#### Start-NTNXFilesMonitoring
Remove Param - Line 11
Remove JSON conversion - Line 15
Remove from Monitoring Script Blog - Line 25
Remove from Job Creation - Line 75

| 29.11.2023 | A-Team | Initial Script Publication After Hackathon 2023 |
New entries go on top.