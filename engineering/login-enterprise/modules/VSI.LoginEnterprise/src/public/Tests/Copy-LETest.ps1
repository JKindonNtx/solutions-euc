function Copy-LETest {
    Param (
        $Test,
        $NewName
    )
    <# V4
    $Type = $test.'$type'
    $Name = "Copy of " + $test.name
    $Description = "Copy of " + $test.description
    $ConnectorID = $test.environment.connectorConfiguration.connector.id
    $connectorParameterValues = $test.environment.connectorConfiguration.connectorParameterValues
    [array]$AccountGroups = $test.environment.accountGroups.groupId
    [array]$LauncherGroups = $test.environment.launcherGroups.id
    $Workload = $test.workload 

    $connectorParameters = $null
    foreach ($value in $connectorParameterValues) {
        $connectorParameters += [pscustomobject]@{Key = $value.value; Value = $value.key; }
        $connectorParameters = @($connectorParameters)
    }
    $connectorParameterValues = $connectorParameters


    $Body = [ordered]@{
        '$type'                  = "$Type"
        Name                     = $Name
        Description              = $Description
        ConnectorID              = $ConnectorID
        ConnectorParameterValues = $connectorParameterValues
        AccountGroups            = $AccountGroups
        LauncherGroups           = $LauncherGroups
        Workload                 = $Workload
    } | ConvertTo-Json
#>
    $Body = @{
        Name = $NewName
    } | ConvertTo-Json

    $Response = Invoke-PublicApiMethod -Method "POST" -Path "v6/tests/$($Test.Id)" -Body $Body
    $Response.id
}