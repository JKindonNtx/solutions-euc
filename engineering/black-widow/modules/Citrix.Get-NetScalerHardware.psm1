function Get-NetScalerHardware {

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
            timeout = "900"
        }
    }
    
    $loginJson = ConvertTo-Json -InputObject $login
    Invoke-RestMethod -uri "$hostname/nitro/v1/config/login" -body $loginJson -SessionVariable saveSession -Headers @{"Content-Type" = "application/vnd.com.citrix.netscaler.login+json"} -Method POST 

    # Build Script NetScaler Session Variable
    $nsSession = New-Object -TypeName PSObject
    $nsSession | Add-Member -NotePropertyName Endpoint -NotePropertyValue $hostname -TypeName String
    $nsSession | Add-Member -NotePropertyName WebSession -NotePropertyValue $saveSession -TypeName Microsoft.PowerShell.Commands.WebRequestSession

    # Get NetScaler Stats
    $Hardware = Invoke-RestMethod -uri "$hostname/nitro/v1/config/nshardware" -WebSession $NSSession.WebSession -Method GET 
    $System = Invoke-RestMethod -uri "$hostname/nitro/v1/config/nsversion" -WebSession $NSSession.WebSession -Method GET 

    $NSHardware = New-Object -TypeName psobject 
    $NSHardware | Add-Member -MemberType NoteProperty -Name "hwdescription" -Value $Hardware.nshardware.hwdescription
    $NSHardware | Add-Member -MemberType NoteProperty -Name "host" -Value $Hardware.nshardware.host
    $NSHardware | Add-Member -MemberType NoteProperty -Name "netscaleruuid" -Value $Hardware.nshardware.netscaleruuid
    $NSHardware | Add-Member -MemberType NoteProperty -Name "version" -Value $system.nsversion.version
    
    # Logout of NetScaler
    $logout = @{
        logout = @{
        }
    }
    $logoutJson = ConvertTo-Json -InputObject $logout       
    Invoke-RestMethod -uri "$hostname/nitro/v1/config/logout" -body $logoutJson -WebSession $NSSession.WebSession -Headers @{"Content-Type" = "application/vnd.com.citrix.netscaler.logout+json"} -Method POST

    return $NSHardware
}