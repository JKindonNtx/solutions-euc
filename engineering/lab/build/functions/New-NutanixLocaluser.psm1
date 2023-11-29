function New-NutanixLocalUser {
<#
    .SYNOPSIS
    Creates a new Local User on the cluster

    .DESCRIPTION
    This function will create a new Local User on the cluster for build and config.
    
    .PARAMETER ClusterIP
    The Nutanix Cluster IP

    .PARAMETER CVMSSHPassword
    The CVM SSH Password

    .PARAMETER LocalUser
    The password for the connection

    .PARAMETER LocalPassword
    The storage UUID for the ISO

    .EXAMPLE
    PS> New-NutanixLocalUser -IP "10.10.10.10" -CVMSSHPassword "password" -LocalUser $Username -LocalPassword "Password"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    Task variable containing the output of the Invoke-RestMethod command run

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/New-NutanixLocalUser.md

    .NOTES
    Author          Version         Date            Detail
    Sven Huisman    v1.0.0          28/11/2022      Function creation
    David Brett     v1.0.1          06/12/2022      Updated Parameter definition
                                                    Updated function header to include MD help file
                                                    Changed Write-Host from hardcoded function name to $($PSCmdlet.MyInvocation.MyCommand.Name)

#>


    [CmdletBinding()]

    Param
    (
        [Parameter(
            Mandatory=$true, 
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
        [system.string[]]$LocalUser,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$LocalPassword
    )

    Begin
    {
        Set-StrictMode -Version Latest
        Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
    } # Begin

    Process
    {
        # Install the Posh-SSH Module
        Install-Module -Name Posh-SSH -Force -Scope CurrentUser

        # Display Function Parameters
        Write-Host (Get-Date)":Local user: $LocalUser" 

        # Build the SSH Session
        $password = ConvertTo-SecureString "$CVMSSHPassword" -AsPlainText -Force
        $HostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
        $session = New-SSHSession -ComputerName $ClusterIP -Credential $HostCredential -AcceptKey -KeepAliveInterval 5 -Force

        # Check for local user
        Write-Host (Get-Date)":Check if there is a local user called $LocalUser" 
        $command = "~/prism/cli/ncli user list user-name=$($LocalUser)"
        $Getusername = (Invoke-SSHCommand -Index $session.SessionId -Command $command).output
        if ( $Getusername -eq "    [None]") {
            # No User found - adding
            Write-Host (Get-Date)":Create local user: $LocalUser" 
            $sshStream = New-SSHShellStream -SessionId $session.SessionId
            $sshStream.WriteLine("~/prism/cli/ncli user add user-name=$($LocalUser) user-password=$($LocalPassword) first-name=$($LocalUser) last-name=nutanix email-id=$($LocalUser)@nutanix.com")
            Start-Sleep -Seconds 3
            Write-Host (Get-Date)":Create local user: $LocalUser done!" 

            # Add user to cluster admin role
            Write-Host (Get-Date)":Add local user: $LocalUser to cluster admin role" 
            $sshStream.WriteLine("~/prism/cli/ncli user grant-cluster-admin-role user-name=$($LocalUser)")
            Start-Sleep -Seconds 15
            Write-Host (Get-Date)":Add local user: $LocalUser to cluster admin role done!"
            $sshStream.Close()
            Remove-SSHSession -Name $Session | Out-Null 
            $task = "added" 
        } Else {
            # User Not Found
            Write-Host (Get-Date)":Local user already exists, assuming with the same password"
            $task = "exists" 
            Start-Sleep 2
            Remove-SSHSession -Name $Session | Out-Null
        }
    } # Process

    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        Return $task
    } # End

} # New-NutanixLocalUser
