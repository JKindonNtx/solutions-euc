function New-LEAccountGroupMember {
    Param (
        [string]$GroupId,
        [array]$ids
    )

    $Body = ConvertTo-Json @($ids)

    $Response = Invoke-PublicApiMethod -Method "PUT" -Path "v6/account-groups/$GroupId/members" -Body $Body
    $Response.items
}