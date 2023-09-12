function Initialize-NetScaler {

    Param
    (
        $IP,
        $UserName,
        $Password
    )

    # Validate connectivity and Black Widow presence on Server NetScaler
    try {
        $NSSession = Connect-NetScaler -HostName $IP -UserName $UserName -Password $Password
        write-progress "Connected to NetScaler $($IP)"
        $NSSession = Disconnect-NetScaler -NSSession $nsSession -hostname $IP
        Return $true
    } catch {
        write-error "Could not connect to NetScaler $($TestConfig.NetScaler.ServerIP)"
        Return $False
    }

}