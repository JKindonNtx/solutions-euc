function Set-NTNXHostAffinity {
    <#
        .SYNOPSIS
        Set affinity for the VMs.
    
        .DESCRIPTION
        This function will set the affinity on the Virtual Machines.
        
        .PARAMETER ClusterIP
        The Nutanix Cluster IP
    
        .PARAMETER CVMSSHPassword
        The user name to use for connection
    
        .PARAMETER VMname
        The VMname

        .PARAMETER hosts
        The hosts for the affinity
    
        .EXAMPLE
        PS> Set-NutanixVMaff -ClusterIP "10.10.10.10" -CVMSSHPassword "password" -VMname "VM" -Hosts "10.56.69.1,10.56.69.2"
    
        .INPUTS
        This function will take inputs via pipeline by property
    
        .OUTPUTS
        Task variable containing the output of the Invoke-RestMethod command run
    
        .LINK
        https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Set-NutanixVMaff.md
    
        .NOTES
        Author          Version         Date            Detail
        Sven Huisman    v1.0.0          28/11/2022      Function creation
        David Brett     v1.0.1          06/12/2022      Updated Parameter definition and added Alias' for IP, UserName and Password
                                                        
    #>
    
    
        [CmdletBinding()]
    
        Param
        (
            [Parameter(Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true
            )]
            [system.string[]]$ClusterIP,
    
            [Parameter(
                Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true
            )]
            [system.string[]]$CVMSSHPassword,
    
            [Parameter(
                Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true
                )]
            [system.string[]]$VMname,
    
            [Parameter(
                Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true
                )]
            [system.string[]]$Hosts
        )
    
        Begin
        {
            Set-StrictMode -Version Latest
            Write-Host (Get-Date)": Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
        } # Begin
    
        Process
        {
    
            # Install Posh-SSH module. Required to connect to the hosts using SSH. Used for capturing performance stats.
            if (!((Get-Module -ListAvailable *) | Where-Object {$_.Name -eq "Posh-SSH"})) {
                Write-Host "SSH module not found, installing missing module."
                Install-Module -Name Posh-SSH -RequiredVersion 2.3.0 -Confirm:$false -Force
        
            }
            # Build the command and set the affinity using SSH
            $VMs = $VMname -Replace '#','?'
            $command = "~/bin/acli vm.affinity_set $VMs host_list=$($hosts)"
            $password = ConvertTo-SecureString "$CVMsshpassword" -AsPlainText -Force
            $HostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
            $session = New-SSHSession -ComputerName $ClusterIP -Credential $HostCredential -AcceptKey -KeepAliveInterval 5
            $SSHOutput = (Invoke-SSHCommand -Index $session.SessionId -Command $command -Timeout 7200).output
            Remove-SSHSession -Name $Session | Out-Null
        } # Process
        
        End
        {
            Write-Host (Get-Date)": Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        } # End
    
    } # Set-NutanixAffinity
    
