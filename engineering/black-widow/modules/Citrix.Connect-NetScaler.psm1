function Connect-NetScaler {
    param
    (
        $HostName,
        $Password,
        $UserName
    )

    # Login to NetScaler
    $login = @{
        login = @{
            username = $UserName;
            password = $Password
            timeout = "3600"
        }
    }
    
    $loginJson = ConvertTo-Json -InputObject $login
    Invoke-RestMethod -uri "$hostname/nitro/v1/config/login" -body $loginJson -SessionVariable saveSession -Headers @{"Content-Type" = "application/vnd.com.citrix.netscaler.login+json"} -Method POST -timeout 10

    # Build Script NetScaler Session Variable
    $nsSession = New-Object -TypeName PSObject
    $nsSession | Add-Member -NotePropertyName Endpoint -NotePropertyValue $hostname -TypeName String
    $nsSession | Add-Member -NotePropertyName WebSession -NotePropertyValue $saveSession -TypeName Microsoft.PowerShell.Commands.WebRequestSession

    Return $nsSession
}