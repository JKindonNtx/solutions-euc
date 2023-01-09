function Remove-LEAccountGroups {
    Param (
        [Parameter(Mandatory = $true)]
        [array]$ids
    )
 
    $Body = ConvertTo-Json @($ids)

    $Response = Invoke-PublicApiMethod -Method "DELETE" -Path "v6/account-groups" -Body $Body
    $Response.id
}