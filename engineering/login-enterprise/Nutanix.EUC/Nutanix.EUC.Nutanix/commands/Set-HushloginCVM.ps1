Function Set-HushloginCVM {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)][string]$ClusterIP,
        [Parameter(Mandatory = $true)][string]$CVMsshuser,
        [Parameter(Mandatory = $true)][string]$CVMsshpassword
    )
        
    Write-Log -Message "Set hushlogin SSH on cluster $ClusterIP." -Level Info
    try {
        # Build the command and set affinity using SSH
        $command = "allssh touch .hushlogin"
        $password = ConvertTo-SecureString "$CVMsshpassword" -AsPlainText -Force
        $HostCredential = New-Object System.Management.Automation.PSCredential ("$CVMsshuser", $password)
        $session = New-SSHSession -ComputerName $ClusterIP -Credential $HostCredential -AcceptKey -KeepAliveInterval 5 -ErrorAction Stop
        $SSHOutput = (Invoke-SSHCommand -Index $session.SessionId -Command $command -Timeout 7200).output
    }
    catch {
        Write-Log -Message $_ -Level Warn
        Break
    }

    Remove-SSHSession -Name $Session | Out-Null
    Write-Log -Message "Set hushlogin Finished." -Level Info

    $hushloginprocessed = $true
        

    return $hushloginprocessed
}