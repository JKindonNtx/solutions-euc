
. "$PSScriptRoot\General\Automation.Slack.ps1"
. "$PSScriptRoot\NTNX-upload\Automation.NTNXupload.ps1"
. "$PSScriptRoot\LoginVSI\Automation.LoginVSI.ps1"

$config = Get-Content -Path "$PSScriptRoot\config.json" -Raw | ConvertFrom-Json
$Share = $config.share
Analyze-SingleTest -Share $($config.Share) -TestName "16ef9fd-d655_1Node_AOS5.20_AHV_Windows-10_360VMs_2vCPU_360Users_ICA_20H2-statsON_run_3"
#start-sleep 2
#Upload-Github -Config $Config -Share $($config.Share) -TestnameRun "d7e8d73-63cb_1Node_AOS5.20_AHV_Windows-10_64VMs_4vCPU_64Users_ICA_20H2-GPU-statsOFF_run_5"
#start-sleep 2
#Slack-ResultJPG -Config $Config -testNameRun "ac4453e-af2e_1Node_AOS5.20_AHV_Windows-10_360VMs_2vCPU_360Users_ICA_20H2-statsOFF_run_1" -Run 1
#AddTextToImage -sourcePath "$($Share)\VSIgraph.jpg" -destPath "$($Share)\VSIGraph.png" -Title "LoginVSI results" -Description "VSIMax=300-VSIBase=788"