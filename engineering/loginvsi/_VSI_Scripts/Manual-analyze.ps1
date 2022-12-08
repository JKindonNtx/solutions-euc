. "$PSScriptRoot\LoginVSI\Automation.LoginVSI.ps1"
$Testname = "0dbde85-dc26_1Node_AOS6.5.1_AHV_Windows-10_330VMs_2vCPU_330Users_ICA_W10-AHV8-tpm"
Analyze-Tests -TestName $Testname -Share "\\WS-VSI3\LoginVSI"
#& \\WS-VSI3\LoginVSI\_VSI_Scripts\LoginVSI\Automation.AppStarts.ps1 "\\WS-VSI3\LoginVSI" $TestName