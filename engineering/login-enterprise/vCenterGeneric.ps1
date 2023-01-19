
Param(
    $ConfigFile = ".\ExampleConfig.jsonc",
    $ReportConfigurationFile = ".\ReportConfiguration.jsonc",
    $DurationInMinutes,
    $NumberOfSessions,
    $LogonsPerMinute,
    [switch]$SkipWaitForIdleVMs,
    [bool]$IncludeUserCreation = $false,
    [bool]$IncludeLauncherCreation = $false,
    [switch]$SkipPDFExport



)
If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }
Import-Module $ScriptRoot\modules\VSI.AD -Force
Import-Module $ScriptRoot\modules\VSI.LoginEnterprise -Force
Import-Module $ScriptRoot\modules\VSI.ResourceMonitor.vCenter -Force
Import-Module $ScriptRoot\modules\VSI.AutomationToolkit -Force
Import-Module $ScriptRoot\modules\VSI.Target.HorizonView -Force


Set-VSIConfigurationVariables -ConfigurationFile $ConfigFile


# Process config from cmdline Args
if (-not ([string]::IsNullOrEmpty($DurationInMinutes))) {
    $VSI_Target_DurationInMinutes = $DurationInMinutes
}
if (-not ([string]::IsNullOrEmpty($NumberOfSessions))) {
    $VSI_Target_NumberOfSessions = $NumberOfSessions
}
if (-not ([string]::IsNullOrEmpty($RampupInMinutes))) {
    $VSI_Target_LogonsPerMinute = $LogonsPerMinute
}
$NumberOfLaunchers = [System.Math]::Ceiling($VSI_Target_NumberOfSessions / 15)


$VSI_Test_RampupInMinutes = [Math]::Round($VSI_Target_NumberOfSessions / $VSI_Target_LogonsPerMinute, 0, [MidpointRounding]::AwayFromZero)
if ($VSI_Test_RampupInMinutes -eq 0) {
    $VSI_Test_RampupInMinutes = 1
}

#region PREP
# Fix trailing slash issue
$VSI_LoginEnterprise_ApplianceURL = $VSI_LoginEnterprise_ApplianceURL.TrimEnd("/")
# Populates the $global:LE_URL
Connect-LEAppliance -Url $VSI_LoginEnterprise_ApplianceURL -Token $VSI_LoginEnterprise_ApplianceToken

if ($IncludeUserCreation -eq $true) {
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
}

#endregion



#region RunTest

if ($IncludeLauncherCreation -eq $true) {
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
        -LauncherGroupName $VSI_Launchers_GroupName
}
# Wait for all launchers to be registered in LE
Wait-LELaunchers -Amount $NumberOfLaunchers -NamingPattern $VSI_Launchers_NamingPattern
# Create/update launchergroup with the launchers
Set-LELauncherGroup -LauncherGroupName $VSI_Launchers_GroupName -NamingPattern $VSI_Launchers_NamingPattern
# Update the test params/create test if not exist
$testId = Set-LELoadTest -TestName $VSI_Test_Name `
    -SessionAmount $VSI_Target_NumberOfSessions `
    -RampupInMinutes $VSI_Test_RampupInMinutes `
    -DurationInMinutes $VSI_Target_DurationInMinutes `
    -LauncherGroupName $VSI_Launchers_GroupName `
    -AccountGroupName $VSI_Users_GroupName `
    -ConnectorName $VSI_Test_ConnectorName `
    -ConnectorParams $VSI_Test_ConnectorParams

# Wait for VM's to have settled down
if (-not ($SkipWaitForIdleVMs)) {
    Start-VSIVCMonitoring -Cluster $VSI_Target_Cluster -vCenterServer $VSI_Target_vCenterServer -vCenterUserName $VSI_Target_vCenterUsername -vCenterPassword $VSI_Target_vCenterPassword -StopWhenVMsAreReady -CPUUtilMHz $VSI_Target_VMCPUsageMHzThreshold -vCenterCounterConfigurationFile $vCenterCounterConfigFile
    Start-Sleep -Seconds ($VSI_Target_MinutesToWaitAfterIdleVMs * 60)
}
# Start the test
Start-LETest -testId $testId
$TestRun = Get-LETestRuns -testId $testId | Select-Object -Last 1
# Start monitoring
$FolderName = "$($VSI_Test_Name)_Run$($TestRun.counter)_$($VSI_Target_NumberOfSessions)Sessions"
$OutputFolder = "$ScriptRoot\results\$FolderName"
$monitoringJob = Start-VSIVCMonitoring -OutputFolder $OutputFolder -DurationInMinutes $VSI_Target_DurationInMinutes -RampupInMinutes $VSI_Test_RampupInMinutes -Cluster $VSI_Target_Cluster -vCenterServer $VSI_Target_vCenterServer -vCenterUserName $VSI_Target_vCenterUsername -vCenterPassword $VSI_Target_vCenterPassword -vCenterCounterConfigurationFile $vCenterCounterConfigFile -AsJob

# Wait for test to finish
Wait-LETest -testId $testId

Export-LEMeasurements -Folder $OutputFolder -TestRun $TestRun -DurationInMinutes $VSI_Target_DurationInMinutes

$XLSXPath = "$OutputFolder.xlsx"
ConvertTo-VSIVCExcelDocument -SourceFolder $OutputFolder -OutputFile $XLSXPath
if (-not ($SkipPDFExport)) {
    Export-LEPDFReport -XLSXFile $XLSXPath -ReportConfigurationFile $ReportConfigurationFile
}
#Cleanup monitoring job
$monitoringJob | Wait-Job | Remove-Job

#endregion