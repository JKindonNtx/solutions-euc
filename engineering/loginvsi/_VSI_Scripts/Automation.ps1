try {
    Stop-Transcript
}
catch {
    Write-Host "No transcript active."
}
# Create transtrcipt-file for logging the tests.
$transScriptFile = "NTNX-VSI-" + (Get-Date -Format yyyymmdd-hhMM).ToString() + ".log"
Start-Transcript -Path "$PSScriptRoot\logs\$transScriptFile"

$ErrorActionPreference = "Stop"
If ($config -eq $null)
{
    $config = Get-Content -Path "$PSScriptRoot\config.json" -Raw | ConvertFrom-Json
}
if (!(Get-PackageProvider | Where-Object {$_.Name -eq "NuGet"})) {
    Write-Host "Default NuGet package provider not installed."
    Write-Host "Installing NuGet package provider."
    Install-PackageProvider -Name "NuGet" -Confirm:$false -Force
    Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted" 
}
# Install Posh-SSH module. Required to connect to the hosts using SSH. Used for capturing performance stats.
if (!((Get-Module -ListAvailable *) | Where-Object {$_.Name -eq "Posh-SSH"})) {
    Write-Host "SSH module not found, installing missing module."
    Install-Module -Name Posh-SSH -RequiredVersion 2.3.0 -Confirm:$false -Force
}

function Get-IniContent ($filePath)
{
    $ini = @{}
    switch -regex -file $FilePath
    {
        "^\[(.+)\]" # Section
        {
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        "^(;.*)$" # Comment
        {
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = "Comment" + $CommentCount
            $ini[$section][$name] = $value
        }
        "(.+?)\s*=(.*)" # Key
        {
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }
    return $ini
}

function Load-LauncherConfig
{
    $vsiLaunchers = Get-IniContent -FilePath "$($config.Share)\_VSI_Configuration\Launchers.ini"

    $vsiLaunchersArray = @()
    foreach ($ls in $vsiLaunchers.Keys)
    {
        if ($vsiLaunchers[$ls].Disabled -eq 0)
        {
            $vsiLaunchersArray += $ls
        }
    }

    return $vsiLaunchersArray | Sort-Object
}

if ($config.Share -match '.+?\\$') {
    $config.Share = $config.Share.SubString(1)
}

if (!(Test-Path -Path $config.Share)) {
    Write-Error -Message "Cannot access the Login VSI share."
    Stop-Transcript
}

# Add unique id to the test name.
$testId = (New-Guid).Guid.SubString(1,12)
$config.TestName ="$($testId)_$($Config.NodeCount)Node_AOS$($config.AOSVersion)_$($config.HostingType)_$($config.TargetOS)_$($config.VMCount)VMs_$($config.VMCPUCount)vCPU_$($config.SessionCount)Users_$($config.SessionCfg)_$($config.TestName)"
$config.Testname = $($config.TestName).Replace(" ", "-")

if (Get-ChildItem -Path "$($config.Share)\_VSI_LogFiles\" | Where-Object {$_.Name.StartsWith($($config.TestName))}) {
    Write-Host "Test already exists please provide a new testname."
    
    $testNameConfig = $false
    
    $config.TestName = $null
    while (!($testNameConfig)) {
        [string]$config.TestName = Read-Host -Prompt "Testname"
        if (!($config.TestName)) {
            Write-Host "Invalid input, please provide a test name."
        } else {
            if (Get-ChildItem -Path "$($config.Share)\_VSI_LogFiles\" | Where-Object {$_.Name.StartsWith($($config.TestName))}) {
                Write-Host "Test already exists please provide a different testname."
            } else {
                $config | ConvertTo-Json | Set-Content -Path .\config.json -Force
                break
            }
        }
    }
}

. "$PSScriptRoot\LoginVSI\Automation.Launcher.ps1"
. "$PSScriptRoot\LoginVSI\Automation.LoginVSI.ps1"
. "$PSScriptRoot\General\Automation.Slack.ps1"
. "$PSScriptRoot\Nutanix\Automation.CVM.ps1"
. "$PSScriptRoot\NTNX-upload\Automation.NTNXupload.ps1"

Update-VSIconfig -Config $config

$vsiLauncher = Get-IniContent -FilePath "$($config.Share)\_VSI_Configuration\_CurrentTest\VSILauncher.ini"
$vsiGlobal = Get-IniContent -FilePath "$($config.Share)\_VSI_Configuration\_CurrentTest\Global.ini"

$vsiOfficeVersion = $vsiGlobal.Settings.Office_version
switch ($vsiOfficeVersion) {
    12 { $vsiOfficeVersion = "2007" }
    14 { $vsiOfficeVersion = "2010" }
    15 { $vsiOfficeVersion = "2013" }
    16 { $vsiOfficeVersion = "2016" }
    Default { 
        Write-Error -Message "Office not configured in Login VSI." 
        Stop-Transcript }
}

$vsiWorkload = $vsiGlobal.Settings.Workload
$vsiSessions = $vsiLauncher.Launcher.NumberOfSessions
$vsiDuration = $vsiLauncher.Launcher.NumberOfWindows
$vsiLogofftimeout = $vsiLauncher.Launcher.LogoffTimeOut
$vsiTotalDuration = [int]$vsiDuration + [int]$vsiLogofftimeout
$vsiDurationMin = ($vsiDuration / 60)

switch ($config.HostingType) {
    Hyper-V { . "$PSScriptRoot\Microsoft\Automation.HyperV.ps1" }
    XenServer { . "$PSScriptRoot\Citrix\Automation.XenServer.ps1" }
    ESXi { . "$PSScriptRoot\VMware\Automation.ESXi.ps1" }
    AHV { . "$PSScriptRoot\Nutanix\Automation.AHV.ps1" }
    Default {
        Write-Error -Message "Hypervisor type $($config.HostingType) invalid, options are Hyper-V, XenServer, ESXi or AHV."
        Stop-Transcript }
}

switch ($config.DeliveryType) {
    #Microsoft { . "$PSScriptRoot\Microsoft\Automation.HyperV.ps1" }
    Citrix { . "$PSScriptRoot\Citrix\Automation.XenDesktop.ps1" }
    VMware { . "$PSScriptRoot\VMware\Automation.View.ps1" }
    Frame { . "$PSScriptRoot\Nutanix\Automation.Frame.ps1" }
    Default { 
        Write-Error -Message "Delivery type $($config.DeliveryType) invalid, options are Microsoft, Citrix or VMware."
        Stop-Transcript }
}


$vsiLaunchersArray = Load-LauncherConfig


Write-Host "
_   _ _   _ _____  _    _   _ _____  __  _                _    __     ______ ___ 
| \ | | | | |_   _|/ \  | \ | |_ _\ \/ / | |    ___   __ _(_)_ _\ \   / / ___|_ _|
|  \| | | | | | | / _ \ |  \| || | \  /  | |   / _ \ / _` | | '_ \ \ / /\___ \| | 
| |\  | |_| | | |/ ___ \| |\  || | /  \  | |__| (_) | (_| | | | | \ V /  ___) | | 
|_| \_|\___/  |_/_/   \_\_| \_|___/_/\_\ |_____\___/ \__, |_|_| |_|\_/  |____/___|
                                                     |___/                                                                                                                                                                         
"

Write-Host "
--------------------------------------------------------------------------------------------------------"
Write-Host "Configured TestName:    $($config.TestName)"
Write-Host "Configured Runs:        $($config.Runs)"
Write-Host "Configured Office:      $vsiOfficeVersion"
Write-Host "Configured Workload:    $vsiWorkload"
Write-Host "Configured Sessions:    $vsiSessions"
Write-Host "Configured Duration:    $vsiDurationMin minutes"
Write-Host "Configured Host:        $($config.TargetHost)"
Write-Host "Single node test:       $($config.SingleNodeTest)"
Write-Host "Configured Hypervisor:  $($config.HostingType)"
Write-Host "CVM is off during test: $($config.CVMdisabled)"
Write-Host "Configured Delivery:    $($config.DeliveryType)"
Write-Host "Capture Host data:      $($config.CaptureHostData)"
Write-Host "Capture Cluster stats:  $($config.CaptureClusterstats)"
Write-Host "Capture NVIDIA data:    $($config.CaptureNVIDIAData)"
Write-Host "Capture Launcher data:  $($config.CaptureLaunchersData)"
Write-Host "Enabled Launchers:"     $vsiLaunchersArray
Write-Host "
--------------------------------------------------------------------------------------------------------"

$confirmationStart = Read-Host "Ready to start the tests? [y/n]"
while($confirmationStart -ne "y") {
    if ($confirmationStart -eq 'n') { exit }
    
    Write-Host "Invalid input, please use y or n."
    $confirmationStart = Read-Host "Ready to start the tests? [y/n]"
}
#Remove existing SSH keys.
Get-SSHTrustedHost | Remove-SSHTrustedHost
#Post Slack message.
Slack-Start -Config $Config -VsiWorkload $vsiWorkload -VsiSessions $vsiSessions
#Create Boot-time.csv
$Boottime = @()
$Boottime += "TestName,DataTime,TotalDesktops,Boottime,HardwareType,CPUType"
Set-Content -Path "$($Config.Share)\$($config.TestName)-boottime.csv" -Value $Boottime | Out-Null

$counter = 0
for ($run = 1; $run -le [int]$config.Runs; $run++) {

    Slack-Update -Config $Config -Run $run
    $testNameRun = "$($config.TestName)_run_$run"

    Reboot-Launchers -Launchers $vsiLaunchersArray

    #Disable the pool and shutdowns all the machines
    Disable-Pool -PoolName $($config.PoolName)

    #If testing on multiple nodes, the nodes will not be rebooted.
    if ($($config.SingleNodeTest) -And $($config.RebootHost)) {
        #Reboot the host
        Reboot-Host -HostName $($config.TargetHost) -TargetPrefix $($config.Environment)
        #Validate the host
        Validate-Host -HostName $($config.TargetHost)
        if ($($config.CVMdisabled)) {
            Start-Sleep -Seconds 300
            Shutdown-CVM
           }
    }
    
    #Enable the pool so all the machines are going to be started
    Enable-Pool -Config $config

    Write-Host (Get-Date) ": Waiting for resources to idle ($($config.IdleTime))."
    Start-Sleep -Seconds $($config.IdleTime * 60)
    Write-Host (Get-Date) ": Test cycle starting."

    if ($($config.CaptureHostData)) {
    Capture-HostData -HostName $($config.TargetHost) -TestName $testNameRun -Share $($config.Share) -Duration $vsiTotalDuration
    }

    if ($($config.CaptureClusterStats)) {
        Capture-Clusterstats -TestName $testNameRun -Share $($config.Share) -Duration $vsiTotalDuration
        }
    
    if ($($config.CaptureNVIDIAData)) {
        Capture-NvidiaData -HostName $($config.TargetHost) -TestName $testNameRun -Duration $vsiTotalDuration
    }

    if ($($config.CaptureLaunchersData)) {
        Capture-LauncherData -Launchers $vsiLaunchersArray -TestName $testNameRun -Duration $vsiDuration
    }

    Start-Test -TestName $testNameRun -Share $($config.Share) -Workload $vsiWorkload
    Monitor-Test -TestName $testNameRun -Share $($config.Share) -Sessions $vsiSessions -LogoffTimeout $vsiLogofftimeout
    Finish-Test -TestName $testNameRun -Share $($config.Share)

   #if ($($config.CaptureHostData) -And $($config.HostingType) -ne "AHV") {
   #     Collect-HostData -HostName $($config.TargetHost) -TestName $testNameRun -Share $($config.Share)
   # }

    if ($($config.CaptureNVIDIAData)) {
        Collect-NvidiaData -HostName $($config.TargetHost) -TestName $testNameRun -Share $($config.Share)
    }

    if ($($config.CaptureLaunchersData)) {
        Collect-LauncherData -Launchers $vsiLaunchersArray -TestName $testNameRun -Share $($config.Share)
    }

    Write-Host (Get-Date) ": Done with run: $run"
    Write-Host (Get-Date) ": Wait 3 minutes to finish the capture of data."
    Start-Sleep -Seconds 180
    Analyze-SingleTest -Share $($config.Share) -TestName $testNameRun
    if ($($config.CaptureHostData)) {
        Upload-Github -Config $Config -Resultsfolder "_VSI_Logfiles" -Share $($config.Share) -TestnameRun $testNameRun
    }
    Slack-ResultJPG -Config $Config -testNameRun $testNameRun -Run $run
    get-job | remove-job -Force
    $counter++
}

Analyze-Tests -TestName $($config.TestName) -Share $($config.Share)
if ($($config.CaptureHostData)) {
    Upload-Github -Config $Config -Resultsfolder "_VSI_Results" -Share $($config.Share) -TestnameRun $($config.TestName)
}
Slack-Done -Config $config
Slack-Results -Config $config
if ($($config.Uploadresults)) {
    $TestConfig = "$PSScriptRoot\config.json"
    Upload-NTNX -Config $TestConfig -TestName $($config.TestName) -Share $($config.Share)
}


try {
    Stop-Transcript
}
catch {
    Write-Host (Get-Date) ": Transscript already stopped"
}
