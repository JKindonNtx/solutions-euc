function Set-LELoadTest {
    param(
        $TestName,
        $SessionAmount,
        $RampupInMinutes,
        $DurationInMinutes,
        $LauncherGroupName,
        $AccountGroupName,
        $ConnectorName,
        $ConnectorParams,
        $Workload
    )
    
    $ExistingTest = $null
    $ExistingTest = Get-LETests -testType "loadTest" | Where-Object { $_.Name -eq $TestName }

    Switch ($ConnectorName) {
        # create test
        "VMware Horizon View" {
            $HORIZON_CMD_LINE = '"C:\Program Files (x86)\VMware\VMware Horizon View Client\vmware-view.exe" -serverURL {serverurl} -userName "{username}" -password "{password}" -domainName "{domain}" -desktopName "{resource}" -standalone -loginAsCurrentUser False -nonInteractive'
            $NewTestBody = @{
                type           = "LoadTest"
                name           = $TestName
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
                type                    = "LoadTest"
                numberOfSessions        = $SessionAmount
                rampUpDurationInMinutes = $RampupInMinutes
                testDurationInMinutes   = $DurationInMinutes
                name                    = $TestName
                euxEnabled              = $true
                description             = $ConnectorParams["resource"]
                environmentUpdate       = @{
                    connector      = @{
                        type        = "Horizon"
                        serverUrl   = $ConnectorParams["serverUrl"]
                        resource    = $ConnectorParams["resource"]
                        commandLine = $HORIZON_CMD_LINE
                    }
                    accountGroups  = @((Get-LEAccountGroups | Where-Object { $_.Name -eq $AccountGroupName } | Select-Object -ExpandProperty groupId))
                    launcherGroups = @((Get-LELauncherGroups | Where-Object { $_.Name -eq $LauncherGroupName } | Select-Object -ExpandProperty id))
                }
            } | ConvertTo-Json
        }
        "Custom Connector" {
            $NewTestBody = @{
                type           = "LoadTest"
                name           = $TestName
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
                euxEnabled              = $true
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
            } | ConvertTo-Json
        }
        "Citrix StoreFront" {
            $NewTestBody = @{
                type           = "LoadTest"
                name           = $TestName
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
                euxEnabled              = $true
                description             = $ConnectorParams["resource"]
                environmentUpdate       = @{
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
                    type                = "AppGroupReference"
                    applicationGroupId  = @((Get-LEApplicationGroups | Where-Object { $_.Name -Like "$($Workload)*" } | Select-Object -ExpandProperty id))
                    isEnabled           = $true
                    }
                )   
            } | ConvertTo-Json
        }
    }


    if ($null -eq $ExistingTest) {
        # Create the test if it doesn't exist
        $Result = Invoke-PublicApiMethod -Method "POST" -Path "v6/tests" -Body $NewTestBody
        Write-Log "Created new test with id: $($Result.id)"
        $ExistingTest = Get-LETest -testId $Result.id
    }
    
    $Result = Invoke-PublicApiMethod -Method "PUT" -Path "v6/tests/$($ExistingTest.id)" -Body $UpdateTestBody
    Write-Log "Updated existing test $($TestName)"
    return $ExistingTest.id

}
