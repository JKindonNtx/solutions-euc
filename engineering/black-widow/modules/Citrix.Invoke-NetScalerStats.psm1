function Invoke-NetScalerStats {

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
    $Stats = Invoke-RestMethod -uri "$hostname/nitro/v1/stat/ns" -WebSession $NSSession.WebSession -Method GET 
    $SSL = Invoke-RestMethod -uri "$hostname/nitro/v1/stat/ssl" -WebSession $NSSession.WebSession -Method GET 
    $TCP = Invoke-RestMethod -uri "$hostname/nitro/v1/stat/protocoltcp" -WebSession $NSSession.WebSession -Method GET 
    $HTTP = Invoke-RestMethod -uri "$hostname/nitro/v1/stat/protocolhttp" -WebSession $NSSession.WebSession -Method GET 
    $InterFace = Invoke-RestMethod -uri "$hostname/nitro/v1/stat/interface" -WebSession $NSSession.WebSession -Method GET 
    $ActiveInterface = $InterFace.interface | Where-Object {$_.id -like "*1/1*" }  

    $NSDetails = New-Object -TypeName psobject 
    $NSDetails | Add-Member -MemberType NoteProperty -Name "cpuusagepcnt" -Value $Stats.ns.cpuusagepcnt
    $NSDetails | Add-Member -MemberType NoteProperty -Name "pktcpuusagepcnt" -Value $Stats.ns.pktcpuusagepcnt
    $NSDetails | Add-Member -MemberType NoteProperty -Name "mgmtcpuusagepcnt" -Value $Stats.ns.mgmtcpuusagepcnt
    $NSDetails | Add-Member -MemberType NoteProperty -Name "memusagepcnt" -Value $Stats.ns.memusagepcnt
    $NSDetails | Add-Member -MemberType NoteProperty -Name "memuseinmb" -Value $Stats.ns.memuseinmb
    $NSDetails | Add-Member -MemberType NoteProperty -Name "totrxmbits" -Value $Stats.ns.totrxmbits
    $NSDetails | Add-Member -MemberType NoteProperty -Name "rxmbitsrate" -Value $Stats.ns.rxmbitsrate
    $NSDetails | Add-Member -MemberType NoteProperty -Name "tottxmbits" -Value $Stats.ns.tottxmbits
    $NSDetails | Add-Member -MemberType NoteProperty -Name "txmbitsrate" -Value $Stats.ns.txmbitsrate
    $NSDetails | Add-Member -MemberType NoteProperty -Name "httptotrequests" -Value $Stats.ns.httptotrequests
    $NSDetails | Add-Member -MemberType NoteProperty -Name "httprequestsrate" -Value $Stats.ns.httprequestsrate
    $NSDetails | Add-Member -MemberType NoteProperty -Name "httptotresponses" -Value $Stats.ns.httptotresponses
    $NSDetails | Add-Member -MemberType NoteProperty -Name "httpresponsesrate" -Value $Stats.ns.httpresponsesrate
    $NSDetails | Add-Member -MemberType NoteProperty -Name "httptotrxrequestbytes" -Value $Stats.ns.httptotrxrequestbytes
    $NSDetails | Add-Member -MemberType NoteProperty -Name "httprxrequestbytesrate" -Value $Stats.ns.httprxrequestbytesrate
    $NSDetails | Add-Member -MemberType NoteProperty -Name "httptotrxresponsebytes" -Value $Stats.ns.httptotrxresponsebytes
    $NSDetails | Add-Member -MemberType NoteProperty -Name "httprxresponsebytesrate" -Value $Stats.ns.httprxresponsebytesrate
    $NSDetails | Add-Member -MemberType NoteProperty -Name "tcpcurclientconn" -Value $Stats.ns.tcpcurclientconn
    $NSDetails | Add-Member -MemberType NoteProperty -Name "ssltottransactions" -Value $SSL.ssl.ssltottransactions
    $NSDetails | Add-Member -MemberType NoteProperty -Name "ssltransactionsrate" -Value $SSL.ssl.ssltransactionsrate
    $NSDetails | Add-Member -MemberType NoteProperty -Name "ssltotecdhetransactions" -Value $SSL.ssl.ssltotecdhetransactions
    $NSDetails | Add-Member -MemberType NoteProperty -Name "sslecdhetransactionsrate" -Value $SSL.ssl.sslecdhetransactionsrate
    $NSDetails | Add-Member -MemberType NoteProperty -Name "tcperrrst" -Value $TCP.protocoltcp.tcperrrst
    $NSDetails | Add-Member -MemberType NoteProperty -Name "errdroppedrxpkts" -Value $ActiveInterface.errdroppedrxpkts
    $NSDetails | Add-Member -MemberType NoteProperty -Name "errdroppedtxpkts" -Value $ActiveInterface.errdroppedtxpkts
    $NSDetails | Add-Member -MemberType NoteProperty -Name "http11requestsrate" -Value $HTTP.protocolhttp.http11requestsrate
    $NSDetails | Add-Member -MemberType NoteProperty -Name "http11responsesrate" -Value $HTTP.protocolhttp.http11responsesrate

    # Logout of NetScaler
    $logout = @{
        logout = @{
        }
    }
    $logoutJson = ConvertTo-Json -InputObject $logout       
    Invoke-RestMethod -uri "$hostname/nitro/v1/config/logout" -body $logoutJson -WebSession $NSSession.WebSession -Headers @{"Content-Type" = "application/vnd.com.citrix.netscaler.logout+json"} -Method POST

    return $NSDetails
}