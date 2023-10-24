
Param(
    $ConfigFile = ".\ExampleConfig.jsonc",
    $ReportConfigFile = ".\ReportConfigurationNTNX.jsonc",
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
Import-Module $ScriptRoot\modules\VSI.Target.HorizonView -Force
Import-Module $ScriptRoot\modules\VSI.AutomationToolkit -Force

Set-VSIConfigurationVariables -ConfigurationFile $ConfigFile

#region PREP
#Remove existing SSH keys.
if (((Get-Module -ListAvailable *) | Where-Object {$_.Name -eq "Posh-SSH"})) {
    Get-SSHTrustedHost | Remove-SSHTrustedHost
}

# Fix trailing slash issue
$VSI_LoginEnterprise_ApplianceURL = $VSI_LoginEnterprise_ApplianceURL.TrimEnd("/")
# Populates the $global:LE_URL
Connect-LEAppliance -Url $VSI_LoginEnterprise_ApplianceURL -Token $VSI_LoginEnterprise_ApplianceToken

#endregion
$configFile = Get-Content -Path $ConfigFile
$configFile = $configFile -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'
$config = $configFile | ConvertFrom-Json
# Get Infra-info
$NTNXInfra = Get-NTNXinfo -Config $config
# End Get Infra-info

if ($VSI_Target_Workload -Like "Task*"){
    $LEWorkload = "TW"
}
if ($VSI_Target_Workload -Like "Office*"){
    $LEWorkload = "OW"
}
if ($VSI_Target_Workload -Like "Knowledge*"){
    $LEWorkload = "KW"
}
if ($VSI_Target_Workload -Like "Power*"){
    $LEWorkload = "PW"
}

#region RunTest
#Set the multiplier for the Workloadtype. This adjusts the required MHz per user setting.
ForEach ($ImageToTest in $VSI_Target_ImagesToTest) {
    Set-VSIConfigurationVariables -ImageConfiguration $ImageToTest

    $NTNXInfra.Target.ImagesToTest = $ImageToTest

    # Setup testname
    $NTNXid = (New-Guid).Guid.SubString(1,6)
    $NTNXTestname = "$($NTNXid)_$($VSI_Target_NodeCount)n_A$($NTNXInfra.Testinfra.AOSversion)_$($NTNXInfra.Testinfra.HypervisorType)_$($VSI_Target_NumberOfVMS)V_$($VSI_Target_NumberOfSessions)U_$LEWorkload"
    # End Setup testname
   
    # Slack update
    $SlackMessage = "New Login Enterprise test started by $VSI_Target_CVM_admin on Cluster $($NTNXInfra.TestInfra.ClusterName). Testname: $($NTNXTestname)."
    Update-VSISlack -Message $SlackMessage -Slack $($NTNXInfra.Testinfra.Slack)
    
    Connect-VSIHVConnectionServer -Server $VSI_Target_ConnectionServer -User $VSI_Target_ConnectionServerUser -Password $VSI_Target_ConnectionServerUserPassword -vCenterServer $VSI_Target_vCenterServer -vCenterUserName $VSI_Target_vCenterUsername -vCenterPassword $VSI_Target_vCenterPassword

    $Test = Get-LETests | Where-Object { $_.name -eq $VSI_Test_Name }
    Wait-LeTest -testId $Test.Id
    if (-not ($SkipLEUsers)) {
        # Create the accounts and accountgroup in LE
        $LEaccounts = New-LEAccounts -Username $VSI_Users_BaseName -Password $VSI_Users_Password -Domain $VSI_Users_NetBios -NumberOfDigits $VSI_Users_NumberOfDigits -NumberOfAccounts $VSI_Target_NumberOfSessions
        New-LEAccountGroup -Name $VSI_Users_GroupName -Description "Created by automation toolkit" -MemberIds $LEaccounts | Out-Null
    }

    if (-not ($SkipADUsers)) {
        # OUs will be created if they don't exist, will also create a group with the $Basename in the same OU
        # This variant for when you're running this from a domain joined machine and your current user has rights to create AD resources
        if ([string]::isNullOrEmpty($VSI_Domain_LDAPUsername)) {
            New-VSIADUsers -BaseName $VSI_Users_BaseName `
                -Amount $VSI_Target_NumberOfSessions `
                -Password $VSI_Users_Password `
                -NumberOfDigits $VSI_Users_NumberOfDigits `
                -DomainLDAPPath $VSI_Domain_LDAPPath `
                -OU $VSI_Users_OU `
                -ApplianceURL $VSI_LoginEnterprise_ApplianceURL
        }
        else {

            # Alternative for when invoking the toolkit from a machine that's not part of the domain/ user that does not have the appropriate rights to create users
            New-VSIADUsers -BaseName $VSI_Users_Basename `
                -Amount $VSI_Target_NumberOfSessions `
                -Password $VSI_Users_Password `
                -NumberOfDigits $VSI_Users_NumberOfDigits `
                -DomainLDAPPath $VSI_Domain_LDAPPath `
                -OU $VSI_Users_OU `
                -LDAPUsername $VSI_Domain_LDAPUsername `
                -LDAPPassword $VSI_Domain_LDAPPassword `
                -ApplianceURL $VSI_LoginEnterprise_ApplianceURL
        }
    }
    
    if ($Force.IsPresent) {
        Remove-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName
    }

    #$VSI_Test_RampupInMinutes = [Math]::Round($VSI_Target_NumberOfSessions / $VSI_Target_LogonsPerMinute, 0, [MidpointRounding]::AwayFromZero)
    $VSI_Target_RampupInMinutes = 5


    for ($i = 1; $i -le $VSI_Target_ImageIterations; $i++) {
        
        # Will only create the pool if it does not exist
        ## AHV

        # Slack update
        $SlackMessage = "Testname: $($NTNXTestname) Run$i is started by $VSI_Target_CVM_admin on Cluster $($NTNXInfra.TestInfra.ClusterName)."
        Update-VSISlack -Message $SlackMessage -Slack $($NTNXInfra.Testinfra.Slack)

        $ContainerId=Get-NTNXStorageUUID -Storage $VSI_Target_CVM_storage
        $Hostuuid=Get-NTNXHostUUID -NTNXHost $VSI_Target_NTNXHost
        $IPMI_ip=Get-NTNXHostIPMI -NTNXHost $VSI_Target_NTNXHost
        
        # Will only create the pool if it does not exist
        # refactor to: Set-VSIHVDesktopPool, will create/update desktop pool, no need to worry about remove/create
        Set-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName `
            -ParentVM $VSI_Target_ParentVM `
            -VMSnapshot $VSI_Target_Snapshot `
            -VMFolder $VSI_Target_VMFolder `
            -HostOrCluster $VSI_Target_Cluster `
            -ResourcePool $VSI_Target_ResourcePool `
            -ReplicaDatastore $VSI_Target_ReplicaDatastore `
            -InstantCloneDatastores $VSI_Target_InstantCloneDatastores `
            -NamingPattern $VSI_Target_NamingPattern `
            -NetBiosName $VSI_Target_DomainName `
            -ADContainer $VSI_Target_ADContainer `
            -EntitledGroups $VSI_Target_Entitlements `
            -vTPM $VSI_Target_vTPM `
            -Protocol $VSI_Target_SessionCfg `
            -RefreshOsDiskAfterLogoff $VSI_Target_RefreshOSDiskAfterLogoff `
            -UserAssignment $VSI_Target_UserAssignment `
            -PoolType $VSI_Target_CloneType `
            -UseViewStorageAccelerator $VSI_Target_UseViewStorageAccelerator `
            -enableGRIDvGPUs $VSI_Target_enableGRIDvGPUs

        $NTNXInfra.Testinfra.MaxAbsoluteActiveActions = "20"
        $NTNXInfra.Testinfra.MaxAbsoluteNewActionsPerMinute = "20"
        $NTNXInfra.Testinfra.MaxPercentageActiveActions = "20"
        
        ## Edit foldername to use new Testname and Run #
        $FolderName = "$($NTNXTestname)_Run$($i)"
        $OutputFolder = "$ScriptRoot\results\$FolderName"

        # Start monitoring Boot phase
        $monitoringJob = Start-VSINTNXMonitoring -OutputFolder $OutputFolder -DurationInMinutes "Boot" -RampupInMinutes $VSI_Target_RampupInMinutes -Hostuuid $Hostuuid -IPMI_ip $IPMI_ip -Path $Scriptroot -NTNXCounterConfigurationFile $ReportConfigFile -AsJob

        if ($VSI_Target_PoolType -eq "RDSH") {
            $Boot = Enable-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName -VMAmount $VSI_Target_NumberOfVMs -Increment $VSI_Target_VMPoolIncrement -RDSH
        } elseif ($VSI_Target_ProvisioningMode -eq "AllMachinesUpFront") {
            $Boot = Enable-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName -VMAmount $VSI_Target_NumberOfVMs -Increment $VSI_Target_VMPoolIncrement -AllMachinesUpFront
        } else {
            $Boot = Enable-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName -VMAmount $VSI_Target_NumberOfVMs -NumberOfSpareVMs $VSI_Target_NumberOfSpareVMs
        }

        $NTNXInfra.Testinfra.BootStart = $Boot.bootstart
        $NTNXInfra.Testinfra.Boottime = $Boot.boottim

        # Set number of sessions per launcher
        if ($($VSI_Target_SessionCfg.ToLower()) -eq "ica") {
            $SessionsperLauncher = 20
        } else {
            $SessionsperLauncher = 12
        }
        if (-not ($SkipLaunchers)) {
            $NumberOfLaunchers = [System.Math]::Ceiling($VSI_Target_NumberOfSessions / $SessionsperLauncher)
            # Wait for all launchers to be registered in LE
            Wait-LELaunchers -Amount $NumberOfLaunchers -NamingPattern $VSI_Launchers_NamingPattern
        
            # Create/update launchergroup with the launchers
            Set-LELauncherGroup -LauncherGroupName $VSI_Launchers_GroupName -NamingPattern $VSI_Launchers_NamingPattern
        }


        # Update the test params/create test if not exist
        $testId = Set-LELoadTest -TestName $VSI_Test_Name `
            -SessionAmount $VSI_Target_NumberOfSessions `
            -RampupInMinutes $VSI_Target_RampupInMinutes `
            -DurationInMinutes $VSI_Target_DurationInMinutes `
            -LauncherGroupName $VSI_Launchers_GroupName `
            -AccountGroupName $VSI_Users_GroupName `
            -ConnectorName "VMware Horizon View" `
            -ConnectorParams @{serverUrl = $VSI_Target_ConnectionServer; resource = $VSI_Target_DesktopPoolName } `
            -Workload $VSI_Target_Workload
        
        # Wait for VM's to have settled down
        if (-not ($SkipWaitForIdleVMs)) {
            Write-Host (Get-Date) "Wait for VMs to become idle"
            Start-Sleep -Seconds 60
        }

        # Get Build Tattoo Information and update variable with new values
        $MasterImageDNS = $boot.firstvmname
        $Tattoo = Invoke-Command -Computer $MasterImageDNS { Get-ItemProperty HKLM:\Software\BuildTatoo }
        $NTNXInfra.Target.ImagesToTest.TargetOS = $Tattoo.OSName
        $NTNXInfra.Target.ImagesToTest.TargetOSVersion = $Tattoo.OSVersion
        $NTNXInfra.Target.ImagesToTest.OfficeVersion = $Tattoo.OfficeName
        $NTNXInfra.Target.ImagesToTest.ToolsGuestVersion = $Tattoo.GuestToolsVersion
        $NTNXInfra.Target.ImagesToTest.OptimizerVendor = $Tattoo.Optimizer
        $NTNXInfra.Target.ImagesToTest.OptimizationsVersion = $Tattoo.OptimizerVersion
        $NTNXInfra.Target.ImagesToTest.DesktopBrokerAgentVersion = $Tattoo.VdaVersion

        #Stop and cleanup monitoring job Boot phase
        $monitoringJob | Stop-Job | Remove-Job

        #Set RDA Source and Destination files and clean out source files if they still exist
        $RDADestination = "$OutputFolder\RDA.csv"
        $RDASource = Join-Path -Path "$($NTNXInfra.TestInfra.RDAPath)" -ChildPath "$($VSI_Users_BaseName)0001.csv"
        if(Test-Path -Path $RDASource){
            Write-Host (Get-Date) "Removing RDA Source File $($RDASource)"
            Remove-Item -Path $RDASource -ErrorAction SilentlyContinue
        } else {
            Write-Host (Get-Date) "RDA Source File $($RDASource) does not exist"
        }

        Write-Host (Get-Date) "Waiting for $VSI_Target_MinutesToWaitAfterIdleVMs minutes before starting test"
        Start-sleep -Seconds $($VSI_Target_MinutesToWaitAfterIdleVMs * 60)
        # Stop Curator
        Set-NTNXcurator -ClusterIP $NTNXInfra.Target.CVM -CVMSSHPassword $NTNXInfra.Target.CVMsshpassword -Action "stop"

        # Start the test
        Start-LETest -testId $testId -Comment "$FolderName-$VSI_Target_Comment"
        $TestRun = Get-LETestRuns -testId $testId | Select-Object -Last 1
        # Start monitoring
        $monitoringJob = Start-VSINTNXMonitoring -OutputFolder $OutputFolder -DurationInMinutes $VSI_Target_DurationInMinutes -RampupInMinutes $VSI_Target_RampupInMinutes -Hostuuid $Hostuuid -IPMI_ip $IPMI_ip -Path $Scriptroot -NTNXCounterConfigurationFile $ReportConfigFile -AsJob
        if ($VSI_Target_Files -ne "") {
            $monitoringFilesJob = Start-NTNXFilesMonitoring -OutputFolder $OutputFolder -DurationInMinutes $VSI_Target_DurationInMinutes -RampupInMinutes $VSI_Target_RampupInMinutes -Path $Scriptroot -NTNXCounterConfigurationFile $ReportConfigFile -AsJob
        }
        if ($VSI_Target_NetScaler -ne "") {
            $monitoringNSJob = Start-NTNXNSMonitoring -OutputFolder $OutputFolder -DurationInMinutes $VSI_Target_DurationInMinutes -RampupInMinutes $VSI_Target_RampupInMinutes -Path $Scriptroot -AsJob
        }
        # Get-NTNXHostinfo -NTNXHost $VSI_Target_NTNXHost -OutputFolder $OutputFolder
        # Wait for test to finish
        Wait-LETest -testId $testId
        #Cleanup monitoring job
        $monitoringJob | Wait-Job | Remove-Job
        if ($VSI_Target_Files -ne "") {
            $monitoringFilesJob | Wait-Job | Remove-Job
        }
        if ($VSI_Target_NetScaler -ne "") {
            $monitoringNSJob | Wait-Job | Remove-Job
        }
        # Start curator
        Set-NTNXcurator -ClusterIP $NTNXInfra.Target.CVM -CVMSSHPassword $NTNXInfra.Target.CVMsshpassword -Action "start"

        #Write config to OutputFolder
        $NTNXInfra.Testinfra.VMCPUCount = [Int]$VSI_Target_NumCPUs * [Int]$VSI_Target_NumCores
        $NTNXInfra.Testinfra.Testname = $FolderName
        $NTNXInfra | ConvertTo-Json -Depth 20 | Set-Content -Path $OutputFolder\Testconfig.json -Force
        Write-Host (Get-Date) "Exporting LE Measurements to output folder"
        Export-LEMeasurements -Folder $OutputFolder -TestRun $TestRun -DurationInMinutes $VSI_Target_DurationInMinutes

        #Check for RDA File and if exists then move it to the output folder
        if(Test-Path -Path $RDASource){
            $csvData = get-content $RDASource | ConvertFrom-String -Delimiter "," -PropertyNames Timestamp,screenResolutionid,encoderid,movingImageCompressionConfigurationid,preferredColorDepthid,videoCodecid,VideoCodecUseid,VideoCodecTextOptimizationid,VideoCodecColorspaceid,VideoCodecTypeid,HardwareEncodeEnabledid,VisualQualityid,FramesperSecondid,RDHSMaxFPS,currentCPU,currentRAM,totalCPU,currentFps,totalFps,currentRTT,NetworkLatency,NetworkLoss,CurrentBandwidthEDT,totalBandwidthusageEDT,averageBandwidthusageEDT,currentavailableEDTBandwidth,EDTInUseId,currentBandwithoutput,currentLatency,currentavailableBandwidth,totalBandwidthusage,averageBandwidthUsage,averageBandwidthAvailable,GPUusage,GPUmemoryusage,GPUmemoryInUse,GPUvideoEncoderusage,GPUvideoDecoderusage,GPUtotalUsage,GPUVideoEncoderSessions,GPUVideoEncoderAverageFPS,GPUVideoEncoderLatency | Select -Skip 1
            $csvData | Export-Csv -Path $RDADestination -NoTypeInformation
            Remove-Item -Path $RDASource -ErrorAction SilentlyContinue
        }

        #$XLSXPath = "$OutputFolder\$FolderName.xlsx"
        #ConvertTo-VSINTNXExcelDocument -SourceFolder $OutputFolder -OutputFile $XLSXPath
        #if (-not ($SkipPDFExport)) {
        #    Export-LEPDFReport -XLSXFile $XLSXPath -ReportConfigurationFile $ReportConfigFile
        #}

        Write-Host (Get-Date) "Uploading results to Influx DB"
        # Upload Config to Influx
        if($NTNXInfra.Test.UploadResults) {
            Start-NTNXInfluxUpload -influxDbUrl $NTNXInfra.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $NTNXInfra.Testinfra.InfluxToken -Boot $true
            Start-NTNXInfluxUpload -influxDbUrl $NTNXInfra.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $NTNXInfra.Testinfra.InfluxToken -Boot $false
        }

        $Testresult = import-csv "$OutputFolder\VSI-results.csv"
        $Appsuccessrate = $Testresult."Apps success"/$Testresult."Apps total" *100
        # Slack update
        $SlackMessage = "Testname: $($NTNXTestname) Run $i is finished on Cluster $($NTNXInfra.TestInfra.ClusterName). $($Testresult.activesessionCount) sessions active of $($Testresult."login total") total sessions. EUXscore: $($Testresult."EUX score") - VSImax: $($Testresult.vsiMax). App Success rate: $($Appsuccessrate.tostring("#.###"))"
        Update-VSISlack -Message $SlackMessage -Slack $($NTNXInfra.Testinfra.Slack)

        $FileName = Get-VSIGraphs -TestConfig $NTNXInfra -OutputFolder $OutputFolder -RunNumber $i -TestName $NTNXTestname
        if(test-path -path $Filename) {
            Update-VSISlackImage -ImageURL $FileName -SlackToken $NTNXInfra.Testinfra.SlackToken -SlackChannel $NTNXInfra.Testinfra.SlackChannel -SlackTitle "$($NTNXInfra.Target.ImagesToTest[0].Comment)_Run$($i)" -SlackComment "CPU and EUX score of $($NTNXInfra.Target.ImagesToTest[0].Comment)_Run$($i)"
        }
    }
    # Analyze Run results
    Get-VSIResults -TestName $NTNXTestname -Path $ScriptRoot
    # Slack update
    Update-VSISlackresults -TestName $NTNXTestname -Path $ScriptRoot
    $OutputFolder = "$($ScriptRoot)\testresults\$($NTNXTestname)"
    $FileName = Get-VSIGraphs -TestConfig $NTNXInfra -OutputFolder $OutputFolder -TestName $NTNXTestname
    if(test-path -path $Filename) {
        Update-VSISlackImage -ImageURL $FileName -SlackToken $NTNXInfra.Testinfra.SlackToken -SlackChannel $NTNXInfra.Testinfra.SlackChannel -SlackTitle "$($NTNXInfra.Target.ImagesToTest[0].Comment)" -SlackComment "CPU and EUX scores of $($NTNXInfra.Target.ImagesToTest[0].Comment) - All Runs"
    }
}
#endregion  