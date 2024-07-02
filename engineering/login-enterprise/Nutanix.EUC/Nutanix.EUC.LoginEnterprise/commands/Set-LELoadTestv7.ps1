function Set-LELoadTestv7 {

    [CmdletBinding()]

    Param (
        $TestName,
        $SessionAmount,
        $RampupInMinutes,
        $DurationInMinutes,
        $LauncherGroupName,
        $AccountGroupName,
        $SessionMetricGroup,
        $ConnectorName,
        $ConnectorParams,
        $Workload
    )

    $ExistingTest = $null
    $ExistingTest = Get-LETests -testType "loadTest" | Where-Object { $_.Name -eq $TestName }
    if($null -ne $ExistingTest) {
        $DeleteTest = Delete-LETest -TestID $ExistingTest.id
    }

    if ($VSI_Target_SessionMetricsEnabled) {
        $SessionMetricGroupKey = (Get-LESessionMetricGroups | Where-Object { $_.Name -eq "$($SessionMetricGroup)" } | Select-Object -ExpandProperty key)
    } Else {
        $SessionMetricGroupKey = ""
    }

    Switch ($ConnectorName) {
        # create test
        "VMware Horizon View" {
            $HORIZON_CMD_LINE = '"C:\Program Files\VMware\VMware Horizon View Client\vmware-view.exe" -serverURL {serverurl} -userName "{username}" -password "{password}" -domainName "{domain}" -desktopName "{resource}" -standalone -loginAsCurrentUser False -nonInteractive'
            $NewTestBody = @{
                type           = "LoadTest"
                name           = $TestName
                euxEnabled     = $VSI_Target_EUXEnabled
                description    = $ConnectorParams["resource"]
                connector      = @{
                    type        = "Horizon"
                    serverUrl   = $ConnectorParams["serverUrl"]
                    resource    = $ConnectorParams["resource"]
                    commandLine = $HORIZON_CMD_LINE
                }
                accountGroups  = @((Get-LEAccountGroups | Where-Object { $_.Name -eq $AccountGroupName } | Select-Object -ExpandProperty groupId))
                launcherGroups = @((Get-LELauncherGroups | Where-Object { $_.Name -eq $LauncherGroupName } | Select-Object -ExpandProperty id))
            } | ConvertTo-Json
                
            $UpdateTestBody = @{
                type                      = "LoadTest"
                numberOfSessions          = $SessionAmount
                rampUpDurationInMinutes   = $RampupInMinutes
                testDurationInMinutes     = $DurationInMinutes
                name                      = $TestName
                euxEnabled                = $VSI_Target_EUXEnabled
                sessionMetricsEnabled     = $VSI_Target_SessionMetricsEnabled
                sessionMetricScheduleRate = $SessionAmount
                sessionMetricGroupKey     = $SessionMetricGroupKey
                description               = $ConnectorParams["resource"]
                environmentUpdate         = @{
                    connector      = @{
                        type        = "Horizon"
                        serverUrl   = $ConnectorParams["serverUrl"]
                        resource    = $ConnectorParams["resource"]
                        commandLine = $HORIZON_CMD_LINE
                    }
                    accountGroups  = @((Get-LEAccountGroups | Where-Object { $_.Name -eq $AccountGroupName } | Select-Object -ExpandProperty groupId))
                    launcherGroups = @((Get-LELauncherGroups | Where-Object { $_.Name -eq $LauncherGroupName } | Select-Object -ExpandProperty id))
                }
                steps                   = @(
                    @{
                        type               = "AppGroupReference"
                        applicationGroupId = @((Get-LEApplicationGroups | Where-Object { $_.Name -Like "$($Workload)*" } | Select-Object -ExpandProperty id))
                        isEnabled          = $true
                    }
                ) 
            } | ConvertTo-Json
        }
        "Custom Connector" {
            $NewTestBody = @{
                type           = "LoadTest"
                name           = $TestName
                euxEnabled     = $VSI_Target_EUXEnabled
                description    = $ConnectorParams.host
                connector      = @{
                    type        = "Custom"
                    host        = $ConnectorParams.host
                    resource    = $ConnectorParams.resource
                    commandLine = $ConnectorParams.commandLine
                }
                accountGroups  = @((Get-LEAccountGroups | Where-Object { $_.Name -eq $AccountGroupName } | Select-Object -ExpandProperty groupId))
                launcherGroups = @((Get-LELauncherGroups | Where-Object { $_.Name -eq $LauncherGroupName } | Select-Object -ExpandProperty id))
            } | ConvertTo-Json
                
            $UpdateTestBody = @{
                type                    = "LoadTest"
                numberOfSessions        = $SessionAmount
                rampUpDurationInMinutes = $RampupInMinutes
                testDurationInMinutes   = $DurationInMinutes
                name                    = $TestName
                euxEnabled              = $VSI_Target_EUXEnabled
                description             = $ConnectorParams.host
                environmentUpdate       = @{
                    connector      = @{
                        type        = "Custom"
                        host        = $ConnectorParams.host
                        resource    = $ConnectorParams.resource
                        commandLine = $ConnectorParams.commandLine
                    }
                    accountGroups  = @((Get-LEAccountGroups | Where-Object { $_.Name -eq $AccountGroupName } | Select-Object -ExpandProperty groupId))
                    launcherGroups = @((Get-LELauncherGroups | Where-Object { $_.Name -eq $LauncherGroupName } | Select-Object -ExpandProperty id))
                }
                steps                   = @(
                    @{
                        type               = "AppGroupReference"
                        applicationGroupId = @((Get-LEApplicationGroups | Where-Object { $_.Name -Like "$($Workload)*" } | Select-Object -ExpandProperty id))
                        isEnabled          = $true
                    }
                )   
            } | ConvertTo-Json
        }
        "Citrix StoreFront" {
            $NewTestBody = @{
                type           = "LoadTest"
                name           = $TestName
                euxEnabled     = $VSI_Target_EUXEnabled
                description    = $ConnectorParams.resource
                connector      = @{
                    type      = "Storefront"
                    serverUrl = $ConnectorParams["serverUrl"]
                    resource  = $ConnectorParams["resource"]
                }
                accountGroups  = @((Get-LEAccountGroups | Where-Object { $_.Name -eq $AccountGroupName } | Select-Object -ExpandProperty groupId))
                launcherGroups = @((Get-LELauncherGroups | Where-Object { $_.Name -eq $LauncherGroupName } | Select-Object -ExpandProperty id))
            } | ConvertTo-Json

            $UpdateTestBody = @{
                type                    = "LoadTest"
                numberOfSessions        = $SessionAmount
                rampUpDurationInMinutes = $RampupInMinutes
                testDurationInMinutes   = $DurationInMinutes
                name                    = $TestName
                euxEnabled              = $VSI_Target_EUXEnabled
                sessionMetricsEnabled   = $VSI_Target_SessionMetricsEnabled
                sessionMetricScheduleRate = $SessionAmount
                sessionMetricGroupKey   = $SessionMetricGroupKey
                description             = $ConnectorParams["resource"]
                connectionResourcesUpdate   = @{
                    connector      = @{
                        type      = "Storefront"
                        serverUrl = $ConnectorParams["serverUrl"]
                        resource  = $ConnectorParams["resource"]
                    }
                    accountGroups  = @((Get-LEAccountGroups | Where-Object { $_.Name -eq $AccountGroupName } | Select-Object -ExpandProperty groupId))
                    launcherGroups = @((Get-LELauncherGroups | Where-Object { $_.Name -eq $LauncherGroupName } | Select-Object -ExpandProperty id))
                }
                steps                   = @(
                    @{
                        type               = "AppGroupReference"
                        applicationGroupId = @((Get-LEApplicationGroups | Where-Object { $_.Name -Like "$($Workload)*" } | Select-Object -ExpandProperty id))
                        isEnabled          = $true
                    }
                )   
            } | ConvertTo-Json
        }
        "Microsoft RDS" {
            $NewTestBody = @{
                type           = "LoadTest"
                name           = $TestName
                euxEnabled     = $VSI_Target_EUXEnabled
                description    = $ConnectorParams.resource
                connector      = @{
                    type              = "RDP"
                    hostList          = $ConnectorParams["hostList"]
                    suppressCertWarn  = $ConnectorParams["suppressCertWarn"]
                    displayResolution = $ConnectorParams["displayResolution"]
                }
                accountGroups  = @((Get-LEAccountGroups | Where-Object { $_.Name -eq $AccountGroupName } | Select-Object -ExpandProperty groupId))
                launcherGroups = @((Get-LELauncherGroups | Where-Object { $_.Name -eq $LauncherGroupName } | Select-Object -ExpandProperty id))
            } | ConvertTo-Json -Depth 4

            $UpdateTestBody = @{
                type                      = "LoadTest"
                numberOfSessions          = $SessionAmount
                rampUpDurationInMinutes   = $RampupInMinutes
                testDurationInMinutes     = $DurationInMinutes
                name                      = $TestName
                euxEnabled                = $VSI_Target_EUXEnabled
                sessionMetricsEnabled     = $VSI_Target_SessionMetricsEnabled
                sessionMetricScheduleRate = $SessionAmount
                sessionMetricGroupKey     = $SessionMetricGroupKey
                description               = $ConnectorParams["resource"]
                connectionResourcesUpdate = @{
                    connector      = @{
                        type              = "RDP"
                        hostList          = $ConnectorParams["hostList"]
                        suppressCertWarn  = $ConnectorParams["suppressCertWarn"]
                        displayResolution = $ConnectorParams["displayResolution"]
                    }
                    accountGroups  = @((Get-LEAccountGroups | Where-Object { $_.Name -eq $AccountGroupName } | Select-Object -ExpandProperty groupId))
                    launcherGroups = @((Get-LELauncherGroups | Where-Object { $_.Name -eq $LauncherGroupName } | Select-Object -ExpandProperty id))
                }
                steps                     = @(
                    @{
                        type               = "AppGroupReference"
                        applicationGroupId = (Get-LEApplicationGroups | Where-Object { $_.Name -Like "$($Workload)*" }).Id#@((Get-LEApplicationGroups | Where-Object { $_.Name -Like "$($Workload)*" } | Select-Object -ExpandProperty id))
                        isEnabled          = $true
                    }
                )   
            } | ConvertTo-Json -Depth 4
        }
    }

    $ExistingTest = $null
    $ExistingTest = Get-LETests -testType "loadTest" | Where-Object { $_.Name -eq $TestName }

    if ($null -eq $ExistingTest) {
        # Create the test if it doesn't exist
        try {
            $Result = Invoke-PublicApiMethod -Method "POST" -Path "v7-preview/tests" -Body $NewTestBody -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break
        }
        Write-Log -Message "Created new test with id: $($Result.id)" -Level Info
        $ExistingTest = Get-LETest -testId $Result.id
    }

    try {
        $Result = Invoke-PublicApiMethod -Method "PUT" -Path "v7-preview/tests/$($ExistingTest.id)" -Body $UpdateTestBody
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break
    }
        
    Write-Log -Message "Updated existing test $($TestName)" -Level Info
    return $ExistingTest.id
}
