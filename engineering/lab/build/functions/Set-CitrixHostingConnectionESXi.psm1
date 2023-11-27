function Set-CitrixHostingConnectionESXi {
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
            $VLAN,
            $DDC,
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
            Write-Host (Get-Date)":Creating Hosting Connection" 
    
            Add-PSSnapin Citrix.*
            Set-XDCredentials -ProfileType OnPrem -StoreAs ctxonprem -ErrorAction Stop
            Get-XDAuthentication -ProfileName ctxonprem -ErrorAction Stop

            $MasterName = "Shared-vCenter"
    
            $Connection = Get-BrokerHypervisorConnection -AdminAddress "$($DDC)" | Where-Object {$_.name -like "*$($MasterName)*" }
            $task = Set-HypAdminConnection -AdminAddress "$($DDC)"
            if($null -eq $Connection){
                Write-Host (Get-Date)":Connection $($ClusterName)-ESXi Does Not Exist" 
            } else {
                Write-Host (Get-Date)":Connection $($ClusterName)-ESXi Exists - Deleting Connection" 
                try {
                    if(Test-Path -Path "XDHyp:\HostingUnits\$($ClusterName)-ESXi"){
                        $task = Remove-Item -AdminAddress "$($DDC)" -path "XDHyp:\HostingUnits\$($ClusterName)-ESXi"
                    } else {
                        Write-Host (Get-Date)":Connection $($ClusterName)-ESXi Does Not Exist" 
                    }
                } catch {
                    write-host "Error removing Hypervisor Connection"
                    write-host $_
                    
                }
            }

            # Adding Nutanix Connection
            Write-Host (Get-Date)":Adding Nutanix Hosting Configuration" -Verbose
            $job = [Guid]::NewGuid()
            $task = New-HypStorage -JobGroup $job -StoragePath @("XDHyp:\Connections\Shared-vCenter\EUC-Solutions.datacenter\$($ClusterName).cluster\EUC-$($ClusterName).storage") -StorageType "TemporaryStorage"
            $task = New-Item -JobGroup $job -CustomProperties "" -HypervisorConnectionName "Shared-vCenter" -NetworkPath @("XDHyp:\Connections\Shared-vCenter\EUC-Solutions.datacenter\$($ClusterName).cluster\$($VLAN).network") -Path @("XDHyp:\HostingUnits\$($ClusterName)-ESXi") -PersonalvDiskStoragePath @() -RootPath "XDHyp:\Connections\Shared-vCenter\EUC-Solutions.datacenter\$($ClusterName).cluster" -StoragePath @("XDHyp:\Connections\Shared-vCenter\EUC-Solutions.datacenter\$($ClusterName).cluster\EUC-$($ClusterName).storage")
            
            Write-Host (Get-Date)":Added Hosting Connection for $($ClusterName)-ESXi"
        } # Process
        
        End
        {
            Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        } # End
    
    } # Set-NutanixVMPower
    