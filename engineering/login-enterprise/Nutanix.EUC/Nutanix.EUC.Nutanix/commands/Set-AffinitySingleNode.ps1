Function Set-AffinitySingleNode {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)][string]$ClusterIP,
        [Parameter(Mandatory = $true)][string]$CVMsshpassword,
        [Parameter(Mandatory = $true)][string]$VMnameprefix,
        [Parameter(Mandatory = $true)][string]$hosts,
        [Parameter(Mandatory = $true)][string]$Run
    )

    if ($Run -eq 1) {
        # We will process because this is run one

        #region Sort Credential and Session for Nutanix Cluster Operations
        $password = ConvertTo-SecureString "$CVMsshpassword" -AsPlainText -Force
        $HostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
        $session = New-SSHSession -ComputerName $ClusterIP -Credential $HostCredential -AcceptKey -KeepAliveInterval 5
        #endregion Sort Credential and Session for Nutanix Cluster Operations
        
        Write-Log -Message "Set Affinity to Host with IP $Hosts." -Level Info
        try {
            # Build the command and set affinity using SSH
            $VMs = $VMnameprefix -Replace '#','?'
            $command = "~/bin/acli vm.affinity_set $VMs host_list=$($hosts)"
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
        Write-Log -Message "Set Affinity Finished." -Level Info

        $AffinityProcessed = $true
        
    } else {
        Write-Log -Message "We will not process affinity jobs as they have been completed in run1" -Level Info
    }

    return $AffinityProcessed #Check this
}