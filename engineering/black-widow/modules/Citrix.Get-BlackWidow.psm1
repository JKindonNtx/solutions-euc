function Get-BlackWidow {

    Param
    (
        $IP,
        $UserName,
        $Password
    )
    
    write-progress "Checking for Black Widow on NetScaler $($IP)"
    $password = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
    $HostCredential = New-Object System.Management.Automation.PSCredential ("$($UserName)", $password)
    write-progress "Creating SSH Session to NetScaler $($IP)"
    $session = New-SSHSession -ComputerName $IP -Credential $HostCredential -AcceptKey -KeepAliveInterval 30
    write-progress -message "Building SSH Stream and checking for Black Widow"
    $sshStream = New-SSHShellStream -SessionId $session.SessionId
    $sshStream.WriteLine("shell")
    $sshStream.WriteLine("cd /var/bw")
    write-progress -message "Reading SSH Stream"
    start-sleep -Seconds 10
    $SSHOutput = $sshStream.read()
    write-progress -message "Removing SSH Session"
    Remove-SSHSession -Name $Session | Out-Null
    if($SSHOutput.Contains("/var/bw: No such file or directory")){
        write-error -message "Black Widow not found on the NetScaler"
        write-error -message "Please install and re-run this test"
        Return $false
    } else {
        write-progress -message "Black Widow found on the NetScaler"
        Return $true
    }

}