function New-LEAccount {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$username,
        [Parameter(Mandatory = $true)]
        [string]$domain,
        [Parameter(Mandatory = $true)]
        [string]$password
    )

    $Body = @{
        username = $username
        domain   = $domain
        password = $password
    } | ConvertTo-Json

    $Response = Invoke-PublicApiMethod -Method "POST" -Path 'v6/accounts' -Body $Body
    $Response.id
}