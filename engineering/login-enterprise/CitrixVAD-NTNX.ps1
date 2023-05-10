
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
Import-Module $ScriptRoot\modules\VSI.Target.CitrixVAD -Force
Import-Module $ScriptRoot\modules\VSI.AutomationToolkit -Force

Add-PSSnapin Citrix*

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

#region RunTest
#Set the multiplier for the Workloadtype. This adjusts the required MHz per user setting.
ForEach ($ImageToTest in $VSI_Target_ImagesToTest) {
    Set-VSIConfigurationVariables -ImageConfiguration $ImageToTest

    #Set affinity
    if ($VSI_Target_NodeCount -eq "1"){
        $NTNXInfra.Testinfra.SetAffinity = $true
    } else {
        $NTNXInfra.Testinfra.SetAffinity = $false
    }

    if ($VSI_Target_Workload -Like "Task*"){
        $LEWorkload = "TW"
        $WLmultiplier = 0.8
    }
    if ($VSI_Target_Workload -Like "Office*"){
        $LEWorkload = "OW"
        $WLmultiplier = 1.0
    }
    if ($VSI_Target_Workload -Like "Knowledge*"){
        $LEWorkload = "KW"
        $WLmultiplier = 1.1
    }
    if ($VSI_Target_Workload -Like "Power*"){
        $LEWorkload = "PW"
        $WLmultiplier = 1.2
    }
     # Calculate number of VMs and sessions
    If ($VSI_Target_AutocalcVMs){
        If ($VSI_Target_Max) {
            $VSI_VSImax = 1
        } Else {$VSI_VSImax = 0.8 }
        $TotalCores = $NTNXInfra.Testinfra.CPUCores * $VSI_Target_NodeCount
        $TotalGHz = $TotalCores * $NTNXInfra.Testinfra.CPUSpeed * 1000
        $vCPUsperVM = $VSI_Target_NumCPUs * $VSI_Target_NumCores
        $GHzperVM = 600 * $WLmultiplier
        # Set the vCPU multiplier. This affects the number of VMs per node.
        $vCPUMultiplier = "1.$vCPUsperVM"
        #$TotalMem = [Math]::Round($NTNXInfra.Testinfra.MemoryGB * 0.92, 0, [MidpointRounding]::AwayFromZero) * $VSI_Target_NodeCount
        $TotalMem = $VSI_Target_NodeCount * (($($NTNXInfra.Testinfra.MemoryGB) - 32) * 0.94)
        $MemperVM = $VSI_Target_MemoryGB
        if ($($VSI_Target_SessionsSupport.ToLower()) -eq "multisession") {
            $VSI_Target_NumberOfVMS = [Math]::Round(($TotalCores - (4 * $VSI_Target_NodeCount)) / $vCPUsperVM * 2, 0, [MidpointRounding]::AwayFromZero)
            $VSI_Target_PowerOnVMs = $VSI_Target_NumberOfVMS
            if ($TotalMem -le ($VSI_Target_NumberOfVMS *  $MemperVM)){
                $VSI_Target_NumberOfVMS = [Math]::Round($TotalMem / $MemperVM, 0, [MidpointRounding]::AwayFromZero)
                $VSI_Target_PowerOnVMs = $VSI_Target_NumberOfVMS
            }
            $RDSHperVM = [Math]::Round(18 / $WLmultiplier, 0, [MidpointRounding]::AwayFromZero)
            $VSI_Target_NumberOfSessions = [Math]::Round($VSI_Target_NumberOfVMS * $RDSHperVM * $VSI_VSImax, 0, [MidpointRounding]::AwayFromZero)
        }
        if ($($VSI_Target_SessionsSupport.ToLower()) -eq "singlesession") {
            $VSI_Target_NumberOfVMS = [Math]::Round(($TotalGHz / ($GHzperVM * $vCPUMultiplier) * $VSI_VSImax), 0, [MidpointRounding]::AwayFromZero)
            $VSI_Target_PowerOnVMs = $VSI_Target_NumberOfVMS
            if ($TotalMem -le ($VSI_Target_NumberOfVMS *  $MemperVM)){
                $VSI_Target_NumberOfVMS = [Math]::Round($TotalMem / $MemperVM, 0, [MidpointRounding]::AwayFromZero)
                $VSI_Target_PowerOnVMs = $VSI_Target_NumberOfVMS
            }
            $VSI_Target_NumberOfSessions = $VSI_Target_NumberOfVMS
        }
        ($NTNXInfra.Target.ImagesToTest | Where-Object{$_.Comment -eq $VSI_Target_Comment}).NumberOfVMs = $VSI_Target_NumberOfVMS
        ($NTNXInfra.Target.ImagesToTest | Where-Object{$_.Comment -eq $VSI_Target_Comment}).PowerOnVMs =  $VSI_Target_PowerOnVMs
        ($NTNXInfra.Target.ImagesToTest | Where-Object{$_.Comment -eq $VSI_Target_Comment}).NumberOfSessions = $VSI_Target_NumberOfSessions
        Write-Host "AutoCalc is enabled and the number of VMs is set to $VSI_Target_NumberOfVMS and the number of sessions to $VSI_Target_NumberOfSessions on $VSI_Target_NodeCount Node(s)"
        Write-Host ""
    }
    $NTNXInfra.Target.ImagesToTest = $ImageToTest

    # Setup testname
    $NTNXid = (New-Guid).Guid.SubString(1,6)
    $NTNXTestname = "$($NTNXid)_$($VSI_Target_NodeCount)n_A$($NTNXInfra.Testinfra.AOSversion)_$($NTNXInfra.Testinfra.HypervisorType)_$($VSI_Target_NumberOfVMS)V_$($VSI_Target_NumberOfSessions)U_$LEWorkload"
    # End Setup testname
   
    # Slack update
    $SlackMessage = "New Login Enterprise test started by $VSI_Target_CVM_admin on Cluster $($NTNXInfra.TestInfra.ClusterName). Testname: $($NTNXTestname)."
    Update-VSISlack -Message $SlackMessage -Slack $($NTNXInfra.Testinfra.Slack)
    
    Connect-VSICTX -DDC $VSI_Target_DDC

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
    
   
    #$VSI_Test_RampupInMinutes = [Math]::Round($VSI_Target_NumberOfSessions / $VSI_Target_LogonsPerMinute, 0, [MidpointRounding]::AwayFromZero)
    $VSI_Target_RampupInMinutes = 48


    for ($i = 1; $i -le $VSI_Target_ImageIterations; $i++) {
        
        # Will only create the pool if it does not exist
        ## AHV

        # Slack update
        $SlackMessage = "Testname: $($NTNXTestname) Run$i is started by $VSI_Target_CVM_admin on Cluster $($NTNXInfra.TestInfra.ClusterName)."
        Update-VSISlack -Message $SlackMessage -Slack $($NTNXInfra.Testinfra.Slack)

        $ContainerId=Get-NTNXStorageUUID -Storage $VSI_Target_CVM_storage
        $Hostuuid=Get-NTNXHostUUID -NTNXHost $VSI_Target_NTNXHost
        $IPMI_ip=Get-NTNXHostIPMI -NTNXHost $VSI_Target_NTNXHost
        $networkMap = @{ "0" = "XDHyp:\HostingUnits\" + $VSI_Target_HypervisorConnection +"\"+ $VSI_Target_HypervisorNetwork +".network" }
        $ParentVM = "XDHyp:\HostingUnits\$VSI_Target_HypervisorConnection\$VSI_Target_ParentVM"
        
        # refactor to: Set-VSIHVDesktopPool, will create/update desktop pool, no need to worry about remove/create
        $CreatePool = Set-VSICTXDesktopPoolNTNX -ParentVM $ParentVM `
            -HypervisorConnection $VSI_Target_HypervisorConnection `
            -HypervisorType $NTNXInfra.Testinfra.HypervisorType `
            -Networkmap $networkMap `
            -CpuCount $VSI_Target_NumCPUs `
            -CoresCount $VSI_Target_NumCores `
            -MemoryGB $VSI_Target_MemoryGB `
            -ContainerID $ContainerId `
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

        $NTNXInfra.Testinfra.MaxAbsoluteActiveActions = $CreatePool.MaxAbsoluteActiveActions
        $NTNXInfra.Testinfra.MaxAbsoluteNewActionsPerMinute = $CreatePool.MaxAbsoluteNewActionsPerMinute
        $NTNXInfra.Testinfra.MaxPercentageActiveActions = $CreatePool.MaxPercentageActiveActions
        
        ## Edit foldername to use new Testname and Run #
        $FolderName = "$($NTNXTestname)_Run$($i)"
        $OutputFolder = "$ScriptRoot\results\$FolderName"

        # Start monitoring Boot phase
        $monitoringJob = Start-VSINTNXMonitoring -OutputFolder $OutputFolder -DurationInMinutes "Boot" -RampupInMinutes $VSI_Target_RampupInMinutes -Hostuuid $Hostuuid -IPMI_ip $IPMI_ip -Path $Scriptroot -NTNXCounterConfigurationFile $ReportConfigFile -AsJob

        $Boot = Enable-VSICTXDesktopPool -DesktopPoolName $VSI_Target_DesktopPoolName `
            -NumberofVMs $VSI_Target_NumberOfVMS `
            -PowerOnVMs $VSI_Target_PowerOnVMs `
            -DDC $VSI_Target_DDC `
            -HypervisorType $NTNXInfra.Testinfra.HypervisorType `
            -Affinity $NTNXInfra.Testinfra.SetAffinity `
            -ClusterIP $NTNXInfra.Target.CVM `
            -CVMSSHPassword $NTNXInfra.Target.CVMsshpassword `
            -VMnameprefix $NTNXInfra.Target.NamingPattern `
            -Hosts $NTNXInfra.Testinfra.Hostip

        $NTNXInfra.Testinfra.BootStart = $Boot.bootstart
        $NTNXInfra.Testinfra.Boottime = $Boot.boottime

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
            -ConnectorName "Citrix Storefront" `
            -ConnectorParams @{serverURL = $VSI_Target_StorefrontURL; resource = $VSI_Target_DesktopPoolName } `
            -Workload $VSI_Target_Workload
        
        # Wait for VM's to have settled down
        if (-not ($SkipWaitForIdleVMs)) {
            Write-Host (Get-Date) "Wait for VMs to become idle"
            Start-Sleep -Seconds 60
        }

        #Stop and cleanup monitoring job Boot phase
        $monitoringJob | Stop-Job | Remove-Job

        Write-Host (Get-Date) "Waiting for $VSI_Target_MinutesToWaitAfterIdleVMs minutes before starting test"
        Start-sleep -Seconds $($VSI_Target_MinutesToWaitAfterIdleVMs * 60)
        
        # Start the test
        Start-LETest -testId $testId -Comment "$FolderName-$VSI_Target_Comment"
        $TestRun = Get-LETestRuns -testId $testId | Select-Object -Last 1
        # Start monitoring
        $monitoringJob = Start-VSINTNXMonitoring -OutputFolder $OutputFolder -DurationInMinutes $VSI_Target_DurationInMinutes -RampupInMinutes $VSI_Target_RampupInMinutes -Hostuuid $Hostuuid -IPMI_ip $IPMI_ip -Path $Scriptroot -NTNXCounterConfigurationFile $ReportConfigFile -AsJob
        
        if ($VSI_Target_NetScaler -ne "") {
            $monitoringNSJob = Start-NTNXNSMonitoring -OutputFolder $OutputFolder -DurationInMinutes $VSI_Target_DurationInMinutes -RampupInMinutes $VSI_Target_RampupInMinutes -Path $Scriptroot -AsJob
        }
        Start-Sleep -Seconds 60
        if ($VSI_Target_Files -ne "") {
            $monitoringFilesJob = Start-NTNXFilesMonitoring -OutputFolder $OutputFolder -DurationInMinutes $VSI_Target_DurationInMinutes -RampupInMinutes $VSI_Target_RampupInMinutes -Path $Scriptroot -NTNXCounterConfigurationFile $ReportConfigFile -AsJob
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

        #Write config to OutputFolder
        $NTNXInfra.Testinfra.VMCPUCount = [Int]$VSI_Target_NumCPUs * [Int]$VSI_Target_NumCores
        $NTNXInfra.Testinfra.Testname = $FolderName
        $NTNXInfra | ConvertTo-Json -Depth 20 | Set-Content -Path $OutputFolder\Testconfig.json -Force
        Export-LEMeasurements -Folder $OutputFolder -TestRun $TestRun -DurationInMinutes $VSI_Target_DurationInMinutes
        $XLSXPath = "$OutputFolder\$FolderName.xlsx"
        ConvertTo-VSINTNXExcelDocument -SourceFolder $OutputFolder -OutputFile $XLSXPath
        #if (-not ($SkipPDFExport)) {
        #    Export-LEPDFReport -XLSXFile $XLSXPath -ReportConfigurationFile $ReportConfigFile
        #}

        # Upload Config to Influx
        if($NTNXInfra.Test.UploadResults) {
            Start-NTNXInfluxUpload -influxDbUrl $NTNXInfra.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $NTNXInfra.Testinfra.InfluxToken -Boot $true
            Start-NTNXInfluxUpload -influxDbUrl $NTNXInfra.Testinfra.InfluxDBurl -ResultsPath $OutputFolder -Token $NTNXInfra.Testinfra.InfluxToken -Boot $false
        }

        $Testresult = import-csv "$OutputFolder\VSI-results.csv"
        # Slack update
        $SlackMessage = "Testname: $($NTNXTestname) Run $i is finished on Cluster $($NTNXInfra.TestInfra.ClusterName). $($Testresult.activesessionCount) sessions active of $($Testresult."login total") total sessions. EUXscore: $($Testresult."EUX score") - VSImax: $($Testresult.vsiMax)."
        Update-VSISlack -Message $SlackMessage -Slack $($NTNXInfra.Testinfra.Slack)

    }
    # Analyze Run results
    Get-VSIResults -TestName $NTNXTestname -Path $ScriptRoot
    # Slack update
    Update-VSISlackresults -TestName $NTNXTestname -Path $ScriptRoot
}
#endregion