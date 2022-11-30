<#
.Synopsis
    Set a vTPM up on the VM
.DESCRIPTION
    Set a vTPM up on the VM
.EXAMPLE
    Set-NutanixvTpmAcli -ClusterIP "10.10.10.10" -CVMsshpassword "password" -VMname "VM"
.INPUTS
    ClusterIP - The Nutanix Cluster IP
    CVMsshpassword - The CVM SSH Password
    VMname - The VM Name
.NOTES
    Sven Huisman      28/11/2022         v1.0.0             Function Creation
.FUNCTIONALITY
    Set a vTPM up on the VM
#>

function Set-NutanixvTpmAcli
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
        $VMname
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'Set-NutanixvTpmAcli'" 
    }

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":VMname: $VMname" 

        # Install the Posh-SSH Module to enable vTPM Connection
        Install-Module -Name Posh-SSH -Force
        $command = "~/bin/acli vm.update $($VMname) virtual_tpm=true"
        $password = ConvertTo-SecureString "$CVMsshpassword" -AsPlainText -Force
        $HostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
        $session = New-SSHSession -ComputerName $ClusterIP -Credential $HostCredential -AcceptKey -KeepAliveInterval 5
        $SSHOutput = (Invoke-SSHCommand -Index $session.SessionId -Command $command -Timeout 7200).output
        Remove-SSHSession -Name $Session | Out-Null
    }
    
    End
    {
        Write-Host (Get-Date)":Finishing 'Set-NutanixvTpmAcli'" 
    }
}
