function New-LELauncherGroup {
    
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(ParameterSetName = 'Filter', Mandatory = $false)][switch]$Filter,      
        [Parameter(ParameterSetName = 'Filter', Mandatory = $true)][string]$Condition,
        [Parameter(Mandatory = $false)][array]$LauncherNames,
        [Parameter(Mandatory = $false)][string]$Description
    )

    if ($Filter.IsPresent) {
        $Body = @{
            'type'      = "Filter"
            groupId     = New-Guid
            name        = $Name
            description = $Description
            condition   = $Condition
        } | ConvertTo-Json
    }
    else {
        $Body = @{
            'type'        = "Selection"
            groupId       = New-Guid
            name          = $Name
            description   = $Description
            launcherNames = $LauncherNames
        } | ConvertTo-Json
    }
    try {
        $Response = Invoke-PublicApiMethod -Method "POST" -Path "v6/launcher-groups" -Body $Body -ErrorAction Stop
        $Response.id
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break
    }

}
