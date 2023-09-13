function Start-BlackWidowCLient {

    Param
    (
        $Config,
        $IP,
        $UserName,
        $Password,
        $BWTargetIP
    )
    
    write-progress "Starting Black Widow Client on NetScaler $($IP)"

    $password = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
    $HostCredential = New-Object System.Management.Automation.PSCredential ("$($UserName)", $password)

    write-progress "Creating SSH Session to NetScaler $($IP)"
    $session = New-SSHSession -ComputerName $IP -Credential $HostCredential -AcceptKey -KeepAliveInterval 30

    write-progress -message "Building SSH Stream"
    $sshStream = New-SSHShellStream -SessionId $session.SessionId

    write-progress -message "Starting Black Widow Client"
    $sshStream.WriteLine("shell")
    $sshStream.WriteLine("cd /var/bw")
    if($Config.BlackWidow.TestType -eq "Throughput") {
        write-progress -message "Starting Black Widow throughput test"
        $Command = "nscsconfig -s client=100 -s cltserverport=443 -s ssl=1 -s ssl_sess_reuse_disable=0 -s ssl_dont_parse_server_cert=1 -s ssl_client_hello_version=12 -s reqperconn=1 -s percentpers=0 -w /var/bw/WL/100konly.wl -s cltserverip=$($BWTargetIP) -s threads=$($Config.BlackWidow.Threads) -s parallelconn=$($Config.BlackWidow.ParallelConnections) -s totalsess=0 -ye start"
    } else {
        write-progress -message "Starting Black Widow vServer test"
        $Command = "nscsconfig -s client=100 -s cltserverport=443 -s ssl=1 -s ssl_sess_reuse_disable=1 -s ssl_dont_parse_server_cert=1 -s ssl_client_hello_version=12 -s reqperconn=1 -s percentpers=0 -w /var/bw/WL/1only.wl -s cltserverip=$($BWTargetIP) -s threads=$($Config.BlackWidow.Threads) -s parallelconn=$($Config.BlackWidow.ParallelConnections) -s totalsess=0 -ye start"
    }
    $sshStream.WriteLine($Command)
    
    write-progress -message "Reading SSH Stream"
    start-sleep -Seconds 15
    $SSHOutput = $sshStream.read()

    write-progress -message "Removing SSH Session"
    Remove-SSHSession -Name $Session | Out-Null
    if($SSHOutput.Contains("Done")){
        write-progress -message "Black Widow Client started on NetScaler $($IP) targetting $($BWTargetIP)"
        Return $true
    } else {
        write-progress -message "There was a problem starting the Black Widow Client"
        Return $false
    }

}