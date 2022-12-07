. "$PSScriptRoot\NTNX-upload\Automation.NTNXupload.ps1"
$Testname = "0dbde85-dc26_1Node_AOS6.5.1_AHV_Windows-10_330VMs_2vCPU_330Users_ICA_W10-AHV8-tpm"
$config = "\\WS-VSI3\LoginVSI\_VSI_Results\$Testname\config.json"
Upload-NTNX -Config $Config -TestName $Testname -Share "\\WS-VSI3\LoginVSI"
