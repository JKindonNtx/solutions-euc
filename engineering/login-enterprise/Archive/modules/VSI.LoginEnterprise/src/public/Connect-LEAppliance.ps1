function Connect-LEAppliance {
    param(
        $url,
        $token
    )
    $global:LE_URL = $url.TrimEnd("/")
    $global:LE_Token = $token

    if ($null -eq (Get-LEApplications)) {
        Write-Error "Failed to connect to appliance at $url, please check that the URL and Token are correct"
    }
}