function Set-LEAccountStatus {
    Param (
        [string]$id,
        [switch]$disable
    )

    if ($disable.IsPresent) {
        $status = $false
    }
    else {
        $status = $true
    }

    $Body = $status  | ConvertTo-Json

    $Response = Invoke-PublicApiMethod -Method "PUT" -Path "v6/accounts/$id/enabled" -Body $Body
    $Response.items 
}