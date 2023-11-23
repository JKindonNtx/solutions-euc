function Remove-LELauncherGroups {
    Param (
        [Parameter(Mandatory = $true)]
        [array]$ids
    )

    $Body = ConvertTo-Json @($ids)

    $Response = Invoke-PublicApiMethod -Method "DELETE" -Path "v6/launcher-groups" -Body $Body
    $Response.id
}