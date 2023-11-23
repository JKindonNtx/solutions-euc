function New-LELauncherGroup {
    [CmdletBinding(DefaultParametersetName = 'None')] 
    Param (
        [Parameter(Mandatory = $true)] [string]$Name,
        [Parameter(ParameterSetName = 'Filter', Mandatory = $false)][switch]$Filter,      
        [Parameter(ParameterSetName = 'Filter', Mandatory = $true)][string]$Condition,
        [array]$LauncherNames,
        [string]$Description
    )

    if ($Filter.IsPresent) {
        $Body = @{
            'type'     = "Filter"
            groupId     = New-Guid
            name        = $Name
            description = $Description
            condition   = $Condition
        } | ConvertTo-Json
    }
    else {
        $Body = @{
            'type'       = "Selection"
            groupId       = New-Guid
            name          = $Name
            description   = $Description
            launcherNames = $LauncherNames
        } | ConvertTo-Json
    }
    $Response = Invoke-PublicApiMethod -Method "POST" -Path "v6/launcher-groups" -Body $Body
    $Response.id
}