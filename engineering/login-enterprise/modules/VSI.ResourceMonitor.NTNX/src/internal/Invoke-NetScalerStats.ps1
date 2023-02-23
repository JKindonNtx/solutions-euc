function Invoke-NetScalerStats {
    param
    (
        $HostName,
        $Password
    )

    # Login to NetScaler
    $login = @{
        login = @{
            username = "nsroot";
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
    $Stats = Invoke-RestMethod -uri "$hostname/nitro/v1/stat/ns" -WebSession $NSSession.WebSession -Method GET 

    $NSDetails = New-Object -TypeName psobject 
    $NSDetails | Add-Member -MemberType NoteProperty -Name "PacketEngineCPU" -Value $Stats.ns.pktcpuusagepcnt
    $NSDetails | Add-Member -MemberType NoteProperty -Name "ManagementEngineCPU" -Value $Stats.ns.mgmtcpuusagepcnt
    $NSDetails | Add-Member -MemberType NoteProperty -Name "MemoryUsage" -Value $Stats.ns.memusagepcnt

    # Logout of NetScaler
    $logout = @{
        logout = @{
        }
    }
    $logoutJson = ConvertTo-Json -InputObject $logout       
    Invoke-RestMethod -uri "$hostname/nitro/v1/config/logout" -body $logoutJson -WebSession $NSSession.WebSession -Headers @{"Content-Type" = "application/vnd.com.citrix.netscaler.logout+json"} -Method POST

    return $NSDetails
}