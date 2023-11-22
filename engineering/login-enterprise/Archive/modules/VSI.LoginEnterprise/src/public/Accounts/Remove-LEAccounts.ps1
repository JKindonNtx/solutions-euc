function Remove-LEAccounts {
    Param (
        [Parameter(Mandatory = $true)]
        [array]$ids
    )

    $Body = ConvertTo-Json @($ids)

    $Response = Invoke-PublicApiMethod -Method "DELETE" -Path "v6/accounts" -Body $Body
    $Response.id
}