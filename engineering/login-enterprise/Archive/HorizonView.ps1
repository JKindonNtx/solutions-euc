
Param(
    $ConfigFile = ".\ExampleConfig.jsonc",
    $ReportConfigFile = ".\ReportConfiguration.jsonc",
    [switch]$Force,
    [switch]$SkipWaitForIdleVMs,
    [switch]$SkipPDFExport


)
If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }
Import-Module $ScriptRoot\modules\VSI.AD -Force
Import-Module $ScriptRoot\modules\VSI.LoginEnterprise -Force
Import-Module $ScriptRoot\modules\VSI.ResourceMonitor.vCenter -Force
Import-Module $ScriptRoot\modules\VSI.Target.HorizonView -Force
Import-Module $ScriptRoot\modules\VSI.AutomationToolkit -Force


Set-VSIConfigurationVariables -ConfigurationFile $ConfigFile

#region PREP
# Fix trailing slash issue
$VSI_LoginEnterprise_ApplianceURL = $VSI_LoginEnterprise_ApplianceURL.TrimEnd("/")
# Populates the $global:LE_URL
Connect-LEAppliance -Url $VSI_LoginEnterprise_ApplianceURL -Token $VSI_LoginEnterprise_ApplianceToken

#endregion


#region RunTest


# Uncomment this to disable other desktoppools
# Exclude requires full name of the pool, include works with wildcard
# Disable-VSIHVDesktopPools -PoolsToDisable ${Target.PoolsToDisable}


ForEach ($ImageToTest in $VSI_Target_ImagesToTest) {
    Set-VSIConfigurationVariables -ImageConfiguration $ImageToTest
    Connect-VSIHVConnectionServer -Server $VSI_Target_ConnectionServer -User $VSI_Target_ConnectionServerUser -Password $VSI_Target_ConnectionServerUserPassword -vCenterServer $VSI_Target_vCenterServer -vCenterUserName $VSI_Target_vCenterUsername -vCenterPassword $VSI_Target_vCenterPassword
    $Test = Get-LETests | Where-Object { $_.name -eq $VSI_Test_Name }
    Write-VSILog "Waiting for test $VSI_Test_Name to be completed"
    while ($Test.State -eq "stopping" -or $Test.State -eq "running") {
        Start-Sleep -Seconds 10
        $Test = Get-LETests | Where-Object { $_.name -eq $VSI_Test_Name }
    }
    # Create the accounts and accountgroup in LE
    $LEaccounts = New-LEAccounts -Username $VSI_Users_BaseName -Password $VSI_Users_Password -Domain $VSI_Users_NetBios -NumberOfDigits $VSI_Users_NumberOfDigits -NumberOfAccounts $VSI_Target_NumberOfSessions
    New-LEAccountGroup -Name $VSI_Users_GroupName -Description "Created by automation toolkit" -MemberIds $LEaccounts | Out-Null


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
    } else {

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
    
    # Removes the current desktop pool to create a new one
    # optional if you only run tests with the same image/snapshot configuration as it's not needed to recreate the desktop pool everytime in that case

    if ($Force.IsPresent) {
        Remove-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName
    }

    if ((Get-Variable -Name VSI_Target_RampupInMinutes -ErrorAction SilentlyContinue) -And  ($VSI_Target_RampupInMinutes -gt 0)) {
        if ((Get-Variable -Name $VSI_Target_LogonsPerMinute -ErrorAction SilentlyContinue) -And ($VSI_Target_LogonsPerMinute -gt 0)) {
            Write-VSILog "Parameter VSI_Target_LogonsPerMinute is ignored, because VSI_Test_RampupInMinutes was set"
        }
    } else {
        $VSI_Target_RampupInMinutes = [Math]::Round($VSI_Target_NumberOfSessions / $VSI_Target_LogonsPerMinute, 0, [MidpointRounding]::AwayFromZero)
    }

    Write-VSILog "Running test of $VSI_Target_NumberOfSessions sessions with ramp-up $VSI_Target_RampupInMinutes minutes and duration $VSI_Target_DurationInMinutes"

    for ($i = 1; $i -le $VSI_Target_ImageIterations; $i++) {
        
        $NumberOfLaunchers = [System.Math]::Ceiling($VSI_Target_NumberOfSessions / 15)
        Set-VSIHVLaunchers -Amount $NumberOfLaunchers `
            -vCenterServer $VSI_Launchers_vCenterServer `
            -vCenterUser $VSI_Launchers_vCenterUsername `
            -vCenterPass $VSI_Launchers_vCenterPassword `
            -CustomizationSpec $VSI_Launchers_CustomizationSpec `
            -ParentVM $VSI_Launchers_ParentVM `
            -Snapshot $VSI_Launchers_Snapshot `
            -VMHost $VSI_Launchers_VMHost `
            -Datastore $VSI_Launchers_Datastore `
            -NamingPattern $VSI_Launchers_NamingPattern `
            -LauncherGroupName $VSI_Launchers_GroupName `
            -Force:$Force
        
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
            -NetBiosName $VSI_Target_NetBiosName `
            -ADContainer $VSI_Target_ADContainer `
            -EntitledGroups $VSI_Target_Entitlements `
            -vTPM $VSI_Target_vTPM `
            -Protocol $VSI_Target_Protocol `
            -RefreshOsDiskAfterLogoff $VSI_Target_RefreshOSDiskAfterLogoff `
            -UserAssignment $VSI_Target_UserAssignment `
            -PoolType $VSI_Target_PoolType `
            -UseViewStorageAccelerator $VSI_Target_UseViewStorageAccelerator `
            -enableGRIDvGPUs $VSI_Target_enableGRIDvGPUs

        if ($VSI_Target_PoolType -eq "RDSH") {
            Enable-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName -VMAmount $VSI_Target_NumberOfVMs -Increment $VSI_Target_VMPoolIncrement -RDSH
        } elseif ($VSI_Target_ProvisioningMode -eq "AllMachinesUpFront") {
            Enable-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName -VMAmount $VSI_Target_NumberOfVMs -Increment $VSI_Target_VMPoolIncrement -AllMachinesUpFront
        } else {
            Enable-VSIHVDesktopPool -Name $VSI_Target_DesktopPoolName -VMAmount $VSI_Target_NumberOfVMs -NumberOfSpareVMs $VSI_Target_NumberOfSpareVMs
        }

        # Wait for all launchers to be registered in LE
        Wait-LELaunchers -Amount $NumberOfLaunchers -NamingPattern $VSI_Launchers_NamingPattern
        # Create/update launchergroup with the launchers
        Set-LELauncherGroup -LauncherGroupName $VSI_Launchers_GroupName -NamingPattern $VSI_Launchers_NamingPattern
        # Update the test params/create test if not exist
        $testId = Set-LELoadTest -TestName $VSI_Test_Name `
            -SessionAmount $VSI_Target_NumberOfSessions `
            -RampupInMinutes $VSI_Target_RampupInMinutes `
            -DurationInMinutes $VSI_Target_DurationInMinutes `
            -LauncherGroupName $VSI_Launchers_GroupName `
            -AccountGroupName $VSI_Users_GroupName `
            -ConnectorName "VMware Horizon View" `
            -ConnectorParams @{serverUrl = $VSI_Target_ConnectionServer; resource = $VSI_Target_DesktopPoolName }

        # Wait for VM's to have settled down
        if (-not ($SkipWaitForIdleVMs)) {
            Start-VSIVCMonitoring -Cluster $VSI_Target_Cluster -vCenterServer $VSI_Target_vCenterServer -vCenterUserName $VSI_Target_vCenterUsername -vCenterPassword $VSI_Target_vCenterPassword -StopWhenVMsAreReady -CPUUtilMHz $VSI_Target_VMCPUsageMHzThreshold -vCenterCounterConfigurationFile $ReportConfigFile
            Start-Sleep -Seconds ($VSI_Target_MinutesToWaitAfterIdleVMs * 60)
        }
        # Start the test
        Start-LETest -testId $testId -Comment $VSI_Target_Comment
        $TestRun = Get-LETestRuns -testId $testId | Select-Object -Last 1
        # Start monitoring
        $FolderName = "$($VSI_Test_Name)_Run$($TestRun.counter)_$($VSI_Target_ParentVM)_$($VSI_Target_Snapshot)_$($VSI_Target_NumberOfSessions)Sessions"
        $OutputFolder = "$ScriptRoot\results\$FolderName"
        $monitoringJob = Start-VSIVCMonitoring -OutputFolder $OutputFolder -DurationInMinutes $VSI_Target_DurationInMinutes -RampupInMinutes $VSI_Target_RampupInMinutes -Cluster $VSI_Target_Cluster -vCenterServer $VSI_Target_vCenterServer -vCenterUserName $VSI_Target_vCenterUsername -vCenterPassword $VSI_Target_vCenterPassword -vCenterCounterConfigurationFile $ReportConfigFile -AsJob
        Get-VSIHVInfo -OutputFolder $OutputFolder -DesktopPoolName $VSI_Target_DesktopPoolName -ConnectionServer $VSI_Target_ConnectionServer -ConnectionServerUser $VSI_Target_ConnectionServerUser -ConnectionServerPassword $VSI_Target_ConnectionServerUserPassword
        # Wait for test to finish
        Wait-LETest -testId $testId
        #Cleanup monitoring job
        $monitoringJob | Wait-Job | Remove-Job

        Export-LEMeasurements -Folder $OutputFolder -TestRun $TestRun -DurationInMinutes $VSI_Target_DurationInMinutes
        $XLSXPath = "$OutputFolder.xlsx"
        ConvertTo-VSIVCExcelDocument -SourceFolder $OutputFolder -OutputFile $XLSXPath
        if (-not ($SkipPDFExport)) {
            Export-LEPDFReport -XLSXFile $XLSXPath -ReportConfigurationFile $ReportConfigFile
        }


    }

}
#endregion