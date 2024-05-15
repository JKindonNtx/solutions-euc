function Set-AffinityClear {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)][string]$ClusterIP,
        [Parameter(Mandatory = $true)][string]$CVMsshpassword,
        [Parameter(Mandatory = $true)][string]$VMnameprefix
    )

    #region Sort Credential and Session for Nutanix Cluster Operations
    $password = ConvertTo-SecureString "$CVMsshpassword" -AsPlainText -Force
    $HostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
    $session = New-SSHSession -ComputerName $ClusterIP -Credential $HostCredential -AcceptKey -KeepAliveInterval 5
    #endregion Sort Credential and Session for Nutanix Cluster Operations

    Write-Log -Message "Clear Affinity from all VMS in Test" -Level Info
    try {
         # Build the command and set affinity using SSH
         $VMs = $VMnameprefix -Replace '#','?'
         $command = "~/bin/acli vm.affinity_unset $VMs"
         $password = ConvertTo-SecureString "$CVMsshpassword" -AsPlainText -Force
         $HostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
         $session = New-SSHSession -ComputerName $ClusterIP -Credential $HostCredential -AcceptKey -KeepAliveInterval 5 -ErrorAction Stop
         $SSHOutput = (Invoke-SSHCommand -Index $session.SessionId -Command $command -Timeout 7200).output
    }
    catch {
        Write-Log -Message $_ -Level Warn
        Break
    }

    Remove-SSHSession -Name $Session | Out-Null

    return $true #Check this
}