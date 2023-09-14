function Start-BlackWidowServer {

    Param
    (
        $IP,
        $UserName,
        $Password,
        $BWServerIP,
        $NumberOfServers
    )
    
    write-progress "Starting Black Widow Server on NetScaler $($IP)"

    $password = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
    $HostCredential = New-Object System.Management.Automation.PSCredential ("$($UserName)", $password)

    write-progress "Creating SSH Session to NetScaler $($IP)"
    $session = New-SSHSession -ComputerName $IP -Credential $HostCredential -AcceptKey -KeepAliveInterval 30

    write-progress -message "Building SSH Stream"
    $sshStream = New-SSHShellStream -SessionId $session.SessionId

    write-progress -message "Starting Black Widow Server"
    $sshStream.WriteLine("shell")
    $sshStream.WriteLine("cd /var/bw")
    $Command = "nscsconfig -s server=1 -s serverip=$($BWServerIP) -s serverip_range=$($NumberOfServers) -s ka=100 -s contentlen=100 -s chunked=0 -W /var/bw/Contents -w /var/bw/WL/AllMixed.wl -ye httpsvr"
    $sshStream.WriteLine($Command)
    
    write-progress -message "Reading SSH Stream"
    start-sleep -Seconds 10
    $SSHOutput = $sshStream.read()

    write-progress -message "Removing SSH Session"
    Remove-SSHSession -Name $Session | Out-Null
    if($SSHOutput.Contains("Enabling HTTP server(1) ...  Done")){
        write-progress -message "Black Widow Server started on NetScaler $($IP) on listener $($BWServerIP)"
        Return $true
    } else {
        write-progress -message "There was a problem starting the Black Widow Server"
        Return $false
    }

}