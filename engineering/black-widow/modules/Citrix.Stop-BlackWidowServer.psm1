function Stop-BlackWidowServer {

    Param
    (
        $IP,
        $UserName,
        $Password
    )
    
    write-progress "Stopping Black Widow Server on NetScaler $($IP)"

    $password = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
    $HostCredential = New-Object System.Management.Automation.PSCredential ("$($UserName)", $password)

    write-progress "Creating SSH Session to NetScaler $($IP)"
    $session = New-SSHSession -ComputerName $IP -Credential $HostCredential -AcceptKey -KeepAliveInterval 30

    write-progress -message "Building SSH Stream"
    $sshStream = New-SSHShellStream -SessionId $session.SessionId

    write-progress -message "Stopping Black Widow Server"
    $sshStream.WriteLine("shell")
    $sshStream.WriteLine("cd /var/bw")
    $Command = "nscsconfig -s server=1 -yE httpsvr"
    $sshStream.WriteLine($Command)
    
    write-progress -message "Reading SSH Stream"
    start-sleep -Seconds 10
    $SSHOutput = $sshStream.read()

    write-progress -message "Removing SSH Session"
    Remove-SSHSession -Name $Session | Out-Null
    if($SSHOutput.Contains("Done")){
        write-progress -message "Black Widow Server stopped on NetScaler $($IP)"
        Return $true
    } else {
        write-progress -message "There was a problem stopping the Black Widow Server"
        Return $false
    }

}