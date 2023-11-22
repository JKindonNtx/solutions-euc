function Set-PrismCentral {
    <#
        .SYNOPSIS
        Creates or deletes the Citrix Hosting Connection.
    
        .DESCRIPTION
        This function will either Create or Delete a Citrix Hosting COnnection based on the parameters passed in.
        
        .PARAMETER IP
        The Nutanix Cluster IP
    
        .PARAMETER UserName
        The user name to use for connection
    
        .PARAMETER Password
        The password for the connection
    
        .PARAMETER VLAN
        The VLAN to use for the connection
    
        .PARAMETER Action
        The Hosting Connection Action to take
    
        .EXAMPLE
        PS> Set-CitrixHostingConnection -IP "10.10.10.10" -UserName "admin" -Password "nutanix" -VLAN "VLAN164" -Action "Create"
    
        .INPUTS
        This function will take inputs via pipeline by property
    
        .OUTPUTS
        Boolean Value with the result of the Hosting Connection Call
    
        .NOTES
        Author          Version         Date            Detail
        David Brett     v1.0.0          21/11/2023      Function creation
    
    #>
    
    
        [CmdletBinding()]
    
        Param
        (
            $IP,
            $Password,
            $PCIP,
            $PCPassword
        )
    
        Begin
        {
            Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
        } # Begin
    
        Process
        {
            # Display Function Parameters
            Write-Host (Get-Date)":Registering $($IP) with Prism Central" 
            $cvmpassword = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
            $peHostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $cvmpassword)
            $pesession = New-SSHSession -ComputerName $IP -Credential $peHostCredential -AcceptKey -KeepAliveInterval 5 -Force

            $command = "~/prism/cli/ncli multicluster register-to-prism-central external-ip-address-or-svm-ips=$($PCIP) username='admin' password='$($PCPassword)'"
            $PERegister = (Invoke-SSHCommand -Index $pesession.SessionId -Command $command).output

            $null = Get-SSHSession | Remove-SSHSession

        } # Process
        
        End
        {
            Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        } # End
    
    } # Set-NutanixVMPower
    