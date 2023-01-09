
Param(
    $ConfigFile = ".\ExampleConfig.jsonc",
    $ReportConfigFile = ".\ReportConfiguration.jsonc",
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
Import-Module $ScriptRoot\modules\VSI.ResourceMonitor.vCenter -Force
Import-Module $ScriptRoot\modules\VSI.Target.CitrixVAD -Force
Import-Module $ScriptRoot\modules\VSI.Target.HorizonView -Force
Import-Module $ScriptRoot\modules\VSI.AutomationToolkit -Force

Add-PSSnapin Citrix*

Set-VSIConfigurationVariables -ConfigurationFile $ConfigFile

#region PREP
# Fix trailing slash issue
$VSI_LoginEnterprise_ApplianceURL = $VSI_LoginEnterprise_ApplianceURL.TrimEnd("/")
# Populates the $global:LE_URL
Connect-LEAppliance -Url $VSI_LoginEnterprise_ApplianceURL -Token $VSI_LoginEnterprise_ApplianceToken

#endregion


#region RunTest

ForEach ($ImageToTest in $VSI_Target_ImagesToTest) {
    Set-VSIConfigurationVariables -ImageConfiguration $ImageToTest
    Connect-VSICTX -ClientID $VSI_Target_ClientID -Secret $VSI_Target_Secret -CustomerID $VSI_Target_CustomerID

    $Test = Get-LETests | Where-Object { $_.name -eq $VSI_Test_Name }
    Wait-LeTest -testId $Test.Id
    if (-not $SkipLEUsers) {
        # Create the accounts and accountgroup in LE
        $LEaccounts = New-LEAccounts -Username $VSI_Users_BaseName -Password $VSI_Users_Password -Domain $VSI_Users_NetBios -NumberOfDigits $VSI_Users_NumberOfDigits -NumberOfAccounts $VSI_Target_NumberOfSessions
        New-LEAccountGroup -Name $VSI_Users_GroupName -Description "Created by automation toolkit" -MemberIds $LEaccounts | Out-Null
    }
    if (-not $SkipADUsers) {
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
    
    # Removes the current desktop pool to create a new one
    # optional if you only run tests with the same image/snapshot configuration as it's not needed to recreate the desktop pool everytime in that case

   
    $VSI_Test_RampupInMinutes = [Math]::Round($VSI_Target_NumberOfSessions / $VSI_Target_LogonsPerMinute, 0, [MidpointRounding]::AwayFromZero)


    for ($i = 1; $i -le $VSI_Target_ImageIterations; $i++) {
        
        $NumberOfLaunchers = [System.Math]::Ceiling($VSI_Target_NumberOfSessions / 15)
        if (-not $SkipLaunchers) {
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
                -Force:$Force.IsPresent
        }
        # Will only create the pool if it does not exist
        # refactor to: Set-VSIHVDesktopPool, will create/update desktop pool, no need to worry about remove/create
        Set-VSICTXDesktopPool -ParentVM $VSI_Target_ParentVM `
            -HypervisorConnection $VSI_Target_HypervisorConnection `
            -CpuCount $VSI_Target_NumCPUs `
            -MemoryMB $VSI_Target_MemoryMB `
            -NamingPattern $VSI_Target_NamingPattern `
            -OU $VSI_Target_ADContainer `
            -DomainName $VSI_Target_DomainName `
            -SessionsSupport $VSI_Target_SessionsSupport `
            -DesktopPoolName $VSI_Target_DesktopPoolName `
            -ZoneName $VSI_Target_ZoneName `
            -Force:$Force.IsPresent `
            -EntitledGroup $VSI_Users_BaseName `
            -SkipImagePrep $VSI_Target_SkipImagePrep `
            -FunctionalLevel $VSI_Target_FunctionalLevel
        If ([string]::IsNullOrEmpty($VSI_Target_ADCreds)) {
            Enable-VSICTXDesktopPool -DesktopPoolName $VSI_Target_DesktopPoolName -NumberofVMs $VSI_Target_NumberOfVMS -PowerOnVMs $VSI_Target_PowerOnVMs
        }
        else {
            $ADUser = $VSI_Target_ADCreds.Split(";")[0]
            $ADPassword = $VSI_Target_ADCreds.Split(";")[1]
            Enable-VSICTXDesktopPool -DesktopPoolName $VSI_Target_DesktopPoolName -NumberofVMs $VSI_Target_NumberOfVMS -ADUsername $ADUser -ADPassword $ADPassword -PowerOnVMs $VSI_Target_PowerOnVMs
        }
        if (-not $SkipLaunchers) {
            # Wait for all launchers to be registered in LE
            Wait-LELaunchers -Amount $NumberOfLaunchers -NamingPattern $VSI_Launchers_NamingPattern
            # Create/update launchergroup with the launchers
            Set-LELauncherGroup -LauncherGroupName $VSI_Launchers_GroupName -NamingPattern $VSI_Launchers_NamingPattern
        }
        # Update the test params/create test if not exist
        if ($null -ne (Get-Variable -Name VSI_Target_StorefrontURL -ea SilentlyContinue)) {
            $testId = Set-LELoadTest -TestName $VSI_Test_Name `
                -SessionAmount $VSI_Target_NumberOfSessions `
                -RampupInMinutes $VSI_Target_RampupInMinutes `
                -DurationInMinutes $VSI_Target_DurationInMinutes `
                -LauncherGroupName $VSI_Launchers_GroupName `
                -AccountGroupName $VSI_Users_GroupName `
                -ConnectorName "Citrix Storefront" `
                -ConnectorParams @{serverURL = $VSI_Target_StorefrontURL; resource = $VSI_Target_DesktopPoolName }
        }
        if ($null -ne (Get-Variable -Name VSI_Target_WorkspaceURL -ea SilentlyContinue)) {
            $testId = Set-LELoadTest -TestName $VSI_Test_Name `
                -SessionAmount $VSI_Target_NumberOfSessions `
                -RampupInMinutes $VSI_Target_RampupInMinutes `
                -DurationInMinutes $VSI_Target_DurationInMinutes `
                -LauncherGroupName $VSI_Launchers_GroupName `
                -AccountGroupName $VSI_Users_GroupName `
                -ConnectorName "Custom Connector" `
                -ConnectorParams @{host = $VSI_Target_WorkspaceURL; commandLine = "$($VSI_Launchers_WebConnectorPath) Script=`"CitrixCloud`" Url=`"$($VSI_Target_WorkspaceURL)`" Resource=`"$($VSI_Target_DesktopPoolName)`" User=`"{domain}\{username}`" Password=`"{password}`"" }
        }
        # Wait for VM's to have settled down
        if (-not ($SkipWaitForIdleVMs)) {
            Start-VSIVCMonitoring -Cluster $VSI_Target_Cluster -vCenterServer $VSI_Target_vCenterServer -vCenterUserName $VSI_Target_vCenterUsername -vCenterPassword $VSI_Target_vCenterPassword -StopWhenVMsAreReady -CPUUtilMHz $VSI_Target_VMCPUsageMHzThreshold -vCenterCounterConfigurationFile $ReportConfigFile
        }
        # Start the test
        Start-LETest -testId $testId -Comment $VSI_Target_Comment
        $TestRun = Get-LETestRuns -testId $testId | Select-Object -Last 1
        # Start monitoring
        $FolderName = "$($VSI_Test_Name)_Run$($TestRun.counter)_$($VSI_Target_NumberOfSessions)Sessions"
        $OutputFolder = "$ScriptRoot\results\$FolderName"
        $monitoringJob = Start-VSIVCMonitoring -OutputFolder $OutputFolder -DurationInMinutes $VSI_Target_DurationInMinutes -RampupInMinutes $VSI_Test_RampupInMinutes -Cluster $VSI_Target_Cluster -vCenterServer $VSI_Target_vCenterServer -vCenterUserName $VSI_Target_vCenterUsername -vCenterPassword $VSI_Target_vCenterPassword -vCenterCounterConfigurationFile $ReportConfigFile -AsJob
        
        #Get-VSIHVInfo -OutputFolder $OutputFolder -DesktopPoolName $VSI_Target_DesktopPoolName -ConnectionServer $VSI_Target_ConnectionServer -ConnectionServerUser $VSI_Target_ConnectionServerUser -ConnectionServerPassword $VSI_Target_ConnectionServerUserPassword
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