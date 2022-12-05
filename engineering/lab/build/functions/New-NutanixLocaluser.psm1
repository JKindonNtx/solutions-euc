<#
.Synopsis
    Set a local user on the cluster
.DESCRIPTION
    Set a local user on the cluster
.EXAMPLE
    New-NutanixLocalUser -ClusterIP "10.10.10.10" -CVMsshpassword "password" -username "euclab" -password "password"
.INPUTS
    ClusterIP - The Nutanix Cluster IP
    CVMsshpassword - The CVM SSH Password
    Localuser - The local user to be created
    Localpassword - The local password to be used
.NOTES
    Sven Huisman      01/12/2022         v1.0.0             Function Creation
.FUNCTIONALITY
    Create a new local user on the cluster to avoud using admin account
#>

function New-NutanixLocalUser
{
    [CmdletBinding(SupportsShouldProcess=$true, 
                  PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $ClusterIP,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $CVMsshpassword,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $username,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $userpassword
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'New-NutanixLocalUser'" 
    }

    Process
    {
        # Install the Posh-SSH Module
        Install-Module -Name Posh-SSH -Force
        # Display Function Parameters
        Write-Host (Get-Date)":Local user: $username" 
        $password = ConvertTo-SecureString "$CVMsshpassword" -AsPlainText -Force
        $HostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
        $session = New-SSHSession -ComputerName $ClusterIP -Credential $HostCredential -AcceptKey -KeepAliveInterval 5
        Write-Host (Get-Date)":Check if there is a local user called $username" 
        $command = "~/prism/cli/ncli user list user-name=$($username)"
        $Getusername = (Invoke-SSHCommand -Index $session.SessionId -Command $command).output
        if ( $Getusername -eq "    [None]") {
            Write-Host (Get-Date)":Create local user: $username" 
            $sshStream = New-SSHShellStream -SessionId $session.SessionId
            $sshStream.WriteLine("~/prism/cli/ncli user add user-name=$($username) user-password=$($userpassword) first-name=$($username) last-name=nutanix email-id=$($username)@nutanix.com")
            Start-Sleep -Seconds 3
            Write-Host (Get-Date)":Create local user: $username done!" 
            Write-Host (Get-Date)":Add local user: $username to cluster admin role" 
            $sshStream.WriteLine("~/prism/cli/ncli user grant-cluster-admin-role user-name=$($username)")
            Start-Sleep -Seconds 8
            Write-Host (Get-Date)":Add local user: $username to cluster admin role done!"
            $sshStream.Close()
            Remove-SSHSession -Name $Session | Out-Null 
        } Else {
            #Write-Host (Get-Date)":Local user already exists, quitting"
            Write-Host (Get-Date)":Local user already exists, assuming with the same password"
            Start-Sleep 2
            Remove-SSHSession -Name $Session | Out-Null
            #Exit
        }
    }
    End
    {
        Write-Host (Get-Date)":Finishing 'New-NutanixLocalUser'" 
    }
}
