function Set-NTNXcurator {
    <#
        .SYNOPSIS
        start or stop curator on the cluster.
    
        .DESCRIPTION
        This function will start or stop curator on the cluster.
        
        .PARAMETER ClusterIP
        The Nutanix Cluster IP
    
        .PARAMETER CVMSSHPassword
        The user name to use for connection
    
        .PARAMETER action
        Start or Stop
    
        .EXAMPLE
        PS> Set-NTNXcurator -ClusterIP "10.10.10.10" -CVMSSHPassword "password" -action "stop"
    
        .INPUTS
        This function will take inputs via pipeline by property
    
        .OUTPUTS
        Task variable containing the output of the Invoke-RestMethod command run
    
        .LINK
        https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Set-NTNXcurator.md
    
        .NOTES
        Author          Version         Date            Detail
        Sven Huisman    v1.0.0          28/11/2022      Function creation
        David Brett     v1.0.1          06/12/2022      Updated Parameter definition and added Alias' for IP, UserName and Password
                                                
    #>
    
    
    [CmdletBinding()]
    
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][system.string[]]$ClusterIP,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][system.string[]]$CVMSSHPassword,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][system.string[]]$Action
    )
    
    Begin {
        # Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # Begin
    
    Process {
    
        # Install Posh-SSH module. Required to connect to the hosts using SSH. Used for capturing performance stats.
        #if (!((Get-Module -ListAvailable *) | Where-Object { $_.Name -eq "Posh-SSH" })) {
        #    Write-Host "SSH module not found, installing missing module."
        #    Install-Module -Name Posh-SSH -RequiredVersion 2.3.0 -Confirm:$false -Force
        #
        #}
        # Build the command and set the curator status using SSH
        if ($Action -eq "stop") {
            $command = "allssh genesis stop curator"
        }
        else {
            $command = "allssh genesis restart"
        }
        $password = ConvertTo-SecureString "$CVMsshpassword" -AsPlainText -Force
        $HostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
        try {
            $session = New-SSHSession -ComputerName $ClusterIP -Credential $HostCredential -AcceptKey -KeepAliveInterval 5 -ErrorAction Stop
            $sshStream = New-SSHShellStream -SessionId $session.SessionId -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break
        }
        
        $sshStream.WriteLine($command)
        Start-sleep -Seconds 10
        $JobFinished = $false
        while ($JobFinished -eq $false) {
            $JobOutput = $sshStream.Read()
            if ($JobOutput -like "*nutanix@*") {
                $JobFinished = $true
            } 
            Start-sleep -Seconds 10
        }

        Remove-SSHSession -Name $Session | Out-Null
    } # Process
        
    End {
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # End
    
} # Set-NutanixAffinity
    
