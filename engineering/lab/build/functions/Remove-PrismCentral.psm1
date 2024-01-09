function Remove-PrismCentral {
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
            $PCIP,
            $PCPassword,
            $ClusterName
        )
    
        Begin
        {
            Set-StrictMode -Version Latest
            Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
        } # Begin
    
        Process
        {
            # Display Function Parameters
            Write-Host (Get-Date)":Checking for existing Prism Central Registration" 
    
            # Install the Posh-SSH Module to enable vTPM Connection
            Install-Module -Name Posh-SSH -RequiredVersion 3.1.1 -Force
            Import-Module Posh-SSH -RequiredVersion 3.1.1

            $pswd = ConvertTo-SecureString "$($PCPassword)" -AsPlainText -Force
            $HostCredential = New-Object System.Management.Automation.PSCredential ("admin", $pswd)
            $session = New-SSHSession -ComputerName "$($PCIP)" -Credential $HostCredential -AcceptKey -KeepAliveInterval 5 -Force

            # Check for existing registration
            $command = "ncli multicluster get-cluster-state"
            $ClusterState = (Invoke-SSHCommand -Index $session.SessionId -Command $command).output
            ForEach ($line in $($ClusterState -split "`r`n"))
            {
                if($Line -like "*$($ClusterName)*"){
                    $ClusterFound = $true
                    $ClusterUUIDLine = $PreviousLine
                }
                $PreviousLine = $Line
            }
            if(Test-Path variable:ClusterFound){
                Write-Host (Get-Date)":Cluster found - removing registration" 
                $ClusterUUID = $ClusterUUIDLine.Split(":")
                $UUID = $ClusterUUID[1].Trim()
                $command = "ncli multicluster delete-cluster-state cluster-id=$($UUID)"
                $ClusterDelete = (Invoke-SSHCommand -Index $session.SessionId -Command $command).output
            }
            
            $null = Get-SSHSession | Remove-SSHSession

        } # Process
        
        End
        {
            Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        } # End
    
    } # Set-NutanixVMPower
    