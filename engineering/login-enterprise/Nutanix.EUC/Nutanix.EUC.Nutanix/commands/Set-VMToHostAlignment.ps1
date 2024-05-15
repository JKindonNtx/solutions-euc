function Set-VMToHostAlignment {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)][string]$Node,
        [Parameter(Mandatory = $true)]$HostMachineList,
        [Parameter(Mandatory = $true)]$Session
    )

    Write-Log -Message "Executing VM alignment tasks for host: $($Node)" -Level Info
    foreach ($VM in $HostMachineList) {
        $command = "~/bin/acli vm.affinity_set $VM host_list=$Node"
        try {
            $SSHOutput = (Invoke-SSHCommand -Index $session.SessionId -Command $command -Timeout 7200 -ErrorAction Stop).output
        }
        catch {
            Write-Log -Message "Failed to handle VM alignment on Host: $($Node)" -Level Warn
            Write-Log -Message $_ -Level Warn
            Break
        } 
    }

    return $true # Do this, or just terminate above - if we do this, we need to add error logic into Set-NTNXHostAlignment Function
}