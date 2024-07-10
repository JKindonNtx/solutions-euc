function Invoke-ESXHostDRestart {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)][string]$VCenter,
        [Parameter(Mandatory = $true)][string]$User,
        [Parameter(Mandatory = $true)][string]$Password,
        [Parameter(Mandatory = $true)][string]$SshUsername,
        [Parameter(Mandatory = $true)][string]$SshPassword,
        [Parameter(Mandatory = $true)][string]$ClusterName,
        [Parameter(Mandatory = $true)][string]$DataCenter
    )

    try {
        $Module = "VMware.VimAutomation.Core"
        Write-Log -Message "Importing Module: $($Module)" -Level Info

        $ModuleLoaded = Get-Module -Name $Module -ErrorAction Stop
        if (-not $ModuleLoaded) {
            Import-Module -Name $Module -ErrorAction Stop
        }

        Write-Log -Message "Connecting to vCenter: $($VCenter)" -Level Info
        $VIServerConnection = Connect-VIServer -Server $VCenter -Port "443" -Protocol "https" -User $User -Password $Password -Force -ErrorAction Stop
        # Get Cluster Details
        Write-Log -Message "Getting Cluster Details for Cluster: $($ClusterName) in Datacenter: $($DataCenter)" -Level Info
        $Cluster = Get-Cluster -Server $VCenter -Name $ClusterName -Location $DataCenter -ErrorAction Stop

        $VMHosts = Get-VMHost -Location $Cluster -ErrorAction Stop
    }
    catch {
       Write-Log -Message "$_" -Level Warn
       Continue
    }

    # Create a secure string for the password
    $securePassword = ConvertTo-SecureString $SshPassword -AsPlainText -Force
    $sshCredential = New-Object System.Management.Automation.PSCredential ($SshUsername, $securePassword)

    Write-Log -Message "Restarting hostd service on ESXi hosts" -Level Info

    # Restart the hostd service on each host
    foreach ($VMHost in ($VMHosts | Sort-Object Name)) {
        $VMHostIP = (Get-VMHostNetworkAdapter -VMHost $VMHost | Where-Object {$_.Name -eq "vmk0"}).IP
        try {
            $command = "/etc/init.d/hostd restart"
            $session = New-SSHSession -ComputerName $VMHostIP -Credential $sshCredential -AcceptKey -ErrorAction Stop
            $output = Invoke-SSHCommand -SessionId $session.SessionId -Command $command
            if ($output.ExitStatus -eq 0) {
                Write-Log -Message "hostd service restarted on host: $($VMHost.Name)" -Level Info
            } else {
                Write-Log -Message "Failed to restart hostd service on host: $($VMHost.Name)" -Level Warn
            }
            Remove-SSHSession -SessionId $session.SessionId | Out-Null
        }
        catch {
            Write-Log -Message "$_" -Level Warn
            Continue
        }   
    }
}