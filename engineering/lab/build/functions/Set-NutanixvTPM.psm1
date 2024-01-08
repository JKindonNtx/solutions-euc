function Set-NutanixvTPM {
<#
    .SYNOPSIS
    Set a vTPM up on the VM.

    .DESCRIPTION
    This function will set up a vTPM on a Virtual Machine.
    
    .PARAMETER ClusterIP
    The Nutanix Cluster IP

    .PARAMETER CVMSSHPassword
    The user name to use for connection

    .PARAMETER VMname
    The password for the connection

    .EXAMPLE
    PS> Set-NutanixvTPM -ClusterIP "10.10.10.10" -CVMSSHPassword "password" -VMname "VM"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    Task variable containing the output of the Invoke-RestMethod command run

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Set-NutanixvTPM.md

    .NOTES
    Author          Version         Date            Detail
    Sven Huisman    v1.0.0          28/11/2022      Function creation
    David Brett     v1.0.1          06/12/2022      Updated Parameter definition and added Alias' for IP, UserName and Password
                                                    Updated function header to include MD help file
                                                    Changed Write-Host from hardcoded function name to $($PSCmdlet.MyInvocation.MyCommand.Name)

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
        [system.string[]]$VMname
    )

    Begin
    {
        Set-StrictMode -Version Latest
        Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
    } # Begin

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":VMname: $VMname" 

        # Install the Posh-SSH Module to enable vTPM Connection
        Install-Module -Name Posh-SSH -RequiredVersion 3.1.1 -Force
        Import-Module Posh-SSH -RequiredVersion 3.1.1

        # Build the command and add the vTPM using SSH
        $command = "~/bin/acli vm.update $($VMname) virtual_tpm=true"
        $password = ConvertTo-SecureString "$CVMsshpassword" -AsPlainText -Force
        $HostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
        $session = New-SSHSession -ComputerName $ClusterIP -Credential $HostCredential -AcceptKey -KeepAliveInterval 5
        $SSHOutput = (Invoke-SSHCommand -Index $session.SessionId -Command $command -Timeout 7200).output
        Remove-SSHSession -Name $Session | Out-Null
    } # Process
    
    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
    } # End

} # Set-NutanixvTPM
