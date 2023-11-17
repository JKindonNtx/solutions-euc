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
            timeout  = "900"
        }
    }
    
    $loginJson = ConvertTo-Json -InputObject $login
    Invoke-RestMethod -uri "$hostname/nitro/v1/config/login" -body $loginJson -SessionVariable saveSession -Headers @{"Content-Type" = "application/vnd.com.citrix.netscaler.login+json" } -Method POST 

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
    $NSDetails | Add-Member -MemberType NoteProperty -Name "TotalReceivedmbits" -Value $Stats.ns.totrxmbits
    $NSDetails | Add-Member -MemberType NoteProperty -Name "RateReceived" -Value $Stats.ns.rxmbitsrate
    $NSDetails | Add-Member -MemberType NoteProperty -Name "TotalTransmitmbits" -Value $Stats.ns.tottxmbits
    $NSDetails | Add-Member -MemberType NoteProperty -Name "RateTransmit" -Value $Stats.ns.txmbitsrate

    # Get StoreFront Stats
    $SFStats = Invoke-RestMethod -uri "$hostname/nitro/v1/stat/lbvserver?args=name:vsvr_storefront_80" -WebSession $NSSession.WebSession -Method GET 
    $NSDetails | Add-Member -MemberType NoteProperty -Name "SFCurrentClientConnections" -Value $SFStats.lbvserver.curclntconnections
    $NSDetails | Add-Member -MemberType NoteProperty -Name "SFCurrentPersistentSessions" -Value $SFStats.lbvserver.curpersistencesessions
    $NSDetails | Add-Member -MemberType NoteProperty -Name "SFTotalSpillovers" -Value $SFStats.lbvserver.totspillovers
    $NSDetails | Add-Member -MemberType NoteProperty -Name "SFCPUUsage" -Value $SFStats.lbvserver.cpuusagepm
    $NSDetails | Add-Member -MemberType NoteProperty -Name "SFTotalHits" -Value $SFStats.lbvserver.tothits
    $NSDetails | Add-Member -MemberType NoteProperty -Name "SFTotalRequests" -Value $SFStats.lbvserver.totalrequests
    $NSDetails | Add-Member -MemberType NoteProperty -Name "SFTotalResponses" -Value $SFStats.lbvserver.totalresponses
    $NSDetails | Add-Member -MemberType NoteProperty -Name "SFTotalRequestBytes" -Value $SFStats.lbvserver.totalrequestbytes
    $NSDetails | Add-Member -MemberType NoteProperty -Name "SFTotalResponseBytes" -Value $SFStats.lbvserver.totalresponsebytes
    $NSDetails | Add-Member -MemberType NoteProperty -Name "SFTotalPacketsReceived" -Value $SFStats.lbvserver.totalpktsrecvd
    $NSDetails | Add-Member -MemberType NoteProperty -Name "SFTotalPacketsSent" -Value $SFStats.lbvserver.totalpktssent
    
    # Logout of NetScaler
    $logout = @{
        logout = @{
        }
    }
    $logoutJson = ConvertTo-Json -InputObject $logout       
    Invoke-RestMethod -uri "$hostname/nitro/v1/config/logout" -body $logoutJson -WebSession $NSSession.WebSession -Headers @{"Content-Type" = "application/vnd.com.citrix.netscaler.logout+json" } -Method POST

    return $NSDetails
}