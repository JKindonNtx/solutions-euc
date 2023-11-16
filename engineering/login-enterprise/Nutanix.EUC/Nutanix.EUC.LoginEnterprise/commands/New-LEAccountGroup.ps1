function New-LEAccountGroup {
    [CmdletBinding(DefaultParametersetName = 'None')]
    Param (
        [Parameter(Position = 0, Mandatory = $true)] [string]$Name,
        [Parameter(ParameterSetName = 'Filter', Mandatory = $false)][switch]$Filter,
        [Parameter(ParameterSetName = 'Filter', Mandatory = $true)][string]$Condition,
        [string]$Description,
        [Array]$MemberIds

    )

    if ($Filter -eq $false) {
        $Body = @{
            'type'      = "Selection"
            groupId     = New-Guid
            name        = $Name
            description = $Description
            memberIds   = $MemberIds
        } | ConvertTo-Json
    }
    else {
        $Body = @{
            'type'      = "Filter"
            groupId     = New-Guid
            name        = $Name
            description = $Description
            condition   = $Condition
        } | ConvertTo-Json
    }
    $ExistingAccountGroup = Get-LEAccountGroups | Where-Object { $_.name -eq $Name }
    if ($null -ne $ExistingAccountGroup) {
        Remove-LEAccountGroups -ids $ExistingAccountGroup.groupId
    }
    $Response = Invoke-PublicApiMethod -Method "POST" -Path "v6/account-groups" -Body $Body
    $Response.id
}