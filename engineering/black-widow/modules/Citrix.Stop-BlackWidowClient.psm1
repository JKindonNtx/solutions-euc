function Stop-BlackWidowCLient {

    Param
    (
        $IP,
        $UserName,
        $Password
    )
    
    write-progress "Stopping Black Widow Client on NetScaler $($IP)"

    $password = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
    $HostCredential = New-Object System.Management.Automation.PSCredential ("$($UserName)", $password)

    write-progress "Creating SSH Session to NetScaler $($IP)"
    $session = New-SSHSession -ComputerName $IP -Credential $HostCredential -AcceptKey -KeepAliveInterval 30

    write-progress -message "Building SSH Stream"
    $sshStream = New-SSHShellStream -SessionId $session.SessionId

    write-progress -message "Stopping Black Widow Client"
    $sshStream.WriteLine("shell")
    $sshStream.WriteLine("cd /var/bw")
    $Command = "nscsconfig -s client=100 -yE stop"
    $sshStream.WriteLine($Command)
    
    write-progress -message "Reading SSH Stream"
    start-sleep -Seconds 15
    $SSHOutput = $sshStream.read()

    write-progress -message "Removing SSH Session"
    Remove-SSHSession -Name $Session | Out-Null
    if($SSHOutput.Contains("Done")){
        write-progress -message "Black Widow Client stopped on NetScaler $($IP)"
        Return $true
    } else {
        write-progress -message "There was a problem stopping the Black Widow Client"
        Return $false
    }

}