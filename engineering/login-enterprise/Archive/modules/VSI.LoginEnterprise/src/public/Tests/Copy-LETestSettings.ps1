function Copy-LETestSettings {
    Param (
        $Source,
        $Destination
    )
 
    $OldTest = $Source
    $Newtest = $Destination
    $Type = $Oldtest.'$type'
    $Name = $Newtest.name
    $Description = $Newtest.description
    $ConnectorID = $Oldtest.environment.connectorConfiguration.connector.id
    $connectorParameterValues = $Oldtest.environment.connectorConfiguration.connectorParameterValues

    [array]$AccountGroups = $Oldtest.environment.accountGroups.groupId
    [array]$LauncherGroups = $Oldtest.environment.launcherGroups.id

    $connectorParameters = $null
    foreach ($value in $connectorParameterValues) {
        $connectorParameters += [pscustomobject]@{Key = $value.value; Value = $value.key; }
        $connectorParameters = @($connectorParameters)
    }
    $connectorParameterValues = $connectorParameters

    $steps = $null
    Foreach ($item in $Oldtest.workload.steps) {
        if ($item.'$type' -eq "AppInvocation") {
            $steps += [pscustomobject]@{'$type' = $item.'$type'; ApplicationId = $item.Application.id; IsEnabled = $item.isEnabled; }
        }
        if ($item.'$type' -eq "Delay") {
            $steps += [pscustomobject]@{'$type' = $item.'$type'; delayInSeconds = $item.delayInSeconds; IsEnabled = $item.isEnabled; }
        }
        $steps = @($steps)
    }



    if ($Type -eq "ApplicationTest") {

        if ($null -ne ($Oldtest.Thresholds)) {        
            Foreach ($Threshold in $Oldtest.Thresholds) {
                Update-Threshold -TestId $Newtest.id -Threshold $Threshold
            }
        }

        if ($null -ne ($Oldtest.alertConfigurations.threshold)) {        
            Foreach ($Threshold in $Oldtest.alertConfigurations.threshold) {
                Update-Threshold -TestId $Newtest.id -Threshold $Threshold
            }
        }

        if ($null -eq $Oldtest.emailRecipient) { $Oldtest.emailRecipient = "noreply@test.com" }
        $Body = [ordered]@{
            '$type'                       = "$Type"
            isEmailEnabled                = $Oldtest.isEmailEnabled
            emailRecipient                = $Oldtest.emailRecipient
            includeSuccessfulApplications = $Oldtest.includeSuccessfulApplications
            state                         = $Oldtest.state
            name                          = $Name
            description                   = $Oldtest.description
            ConnectorID                   = $ConnectorID
            ConnectorParameterValues      = $connectorParameterValues
            AccountGroups                 = $AccountGroups
            LauncherGroups                = $LauncherGroups
            steps                         = $steps
        } | ConvertTo-Json
    }

    if ($Type -eq "LoadTest") {
        $Body = [ordered]@{
            '$type'                  = "$Type"
            numberOfSessions         = $Oldtest.numberOfSessions
            rampUpDurationInMinutes  = $Oldtest.rampUpDurationInMinutes
            testDurationInMinutes    = $Oldtest.testDurationInMinutes
            name                     = $Name
            description              = $Oldtest.description
            ConnectorID              = $ConnectorID
            ConnectorParameterValues = $connectorParameterValues
            AccountGroups            = $AccountGroups
            LauncherGroups           = $LauncherGroups
            steps                    = $steps
        } | ConvertTo-Json
    }

    if ($Type -eq "ContinuousTest") {
        $Body = [ordered]@{
            '$type'                  = "$Type"
            scheduleType             = $Oldtest.scheduleType
            intervalInMinutes        = $Oldtest.scheduleIntervalInMinutes
            numberOfSessions         = $Oldtest.numberOfSessions
            takeScriptScreenshots    = $Oldtest.takeScriptScreenshots
            repeatCount              = $Oldtest.repeatCount
            isRepeatEnabled          = $Oldtest.isRepeatEnabled
            isEnabled                = $Oldtest.isEnabled
            restartOnComplete        = $Oldtest.restartOnComplete
            name                     = $Name
            description              = "description"
            connectorID              = $ConnectorID
            connectorParameterValues = $connectorParameterValues
            accountGroups            = $AccountGroups
            launcherGroups           = $LauncherGroups
            steps                    = $steps
        } | ConvertTo-Json
    }

    $Response = Invoke-PublicApiMethod -Method "PUT" -Path "v6/tests/$($Newtest.id)" -Body $Body
    $Response.id
}
