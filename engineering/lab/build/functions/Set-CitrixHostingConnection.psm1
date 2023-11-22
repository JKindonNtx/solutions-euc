function Set-CitrixHostingConnection {
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
            $UserName,
            $Password,
            $VLAN,
            $DDC
        )
    
        Begin
        {
            Set-StrictMode -Version Latest
            Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
        } # Begin
    
        Process
        {
            # Display Function Parameters
            Write-Host (Get-Date)":VLAN: $VLAN" 
    
            Add-PSSnapin Citrix.*
            Set-XDCredentials -ProfileType OnPrem -StoreAs ctxonprem -ErrorAction Stop
            Get-XDAuthentication -ProfileName ctxonprem -ErrorAction Stop

            $ClusterName = (Get-NutanixApiv2 -IP $IP -UserName $UserName -Password $Password -APIPath "cluster").name
    
            $Connection = Get-BrokerHypervisorConnection -AdminAddress "$($DDC)" | Where-Object {$_.name -like "*$($ClusterName)*" }
            if($null -eq $Connection){
                Write-Host (Get-Date)":Connection $($ClusterName) Does Not Exist" 
            } else {
                Write-Host (Get-Date)":Connection $($ClusterName) Exists - Deleting" 
                try {
                    Remove-Item -AdminAddress "$($DDC)" -path "xdhyp:\HostingUnits\$($ClusterName)-AHV"
                    Remove-BrokerHypervisorConnection -Name $ClusterName
                    Remove-Item -AdminAddress "$($DDC)" -path "xdhyp:\Connections\$($ClusterName)"
                } catch {
                    write-host "Error removing Hypervisor Connection"
                    write-host $_
                    
                }
            }
            
            $Pwd = $Password | ConvertTo-SecureString -asPlainText -Force
            $RootPath = "XDHyp:\Connections\$ClusterName"
            $NetworkPath = "$RootPath\" + "$VLAN.network"

    
            # Adding Nutanix Connection
            Write-Host "Adding Nutanix Hosting Configuration" -Verbose
            Set-HypAdminConnection -AdminAddress "$($DDC)"
            $Connection = New-Item -ConnectionType "Custom" -CustomProperties "" -HypervisorAddress @("$IP")  -Metadata @{"Citrix_Broker_ExtraSpinUpTime"="120";"Citrix_Broker_MaxAbsoluteNewActionsPerMinute"="50";"Citrix_Broker_MaxAbsolutePvDPowerActions"="50";"Citrix_Broker_MaxPvdPowerActionsPercentageOfDesktops"="25";"Citrix_Broker_MaxPowerActionsPercentageOfDesktops"="20";"Citrix_Broker_MaxAbsoluteActiveActions"="100"} -Path @("XDHyp:\Connections\$($ClusterName)") -Persist -PluginId "AcropolisFactory" -Scope @() -SecurePassword $Pwd -UserName $UserName
            $NewConnection = New-BrokerHypervisorConnection  -AdminAddress "$($DDC)" -HypHypervisorConnectionUid $Connection.HypervisorConnectionUid
            $NewItem = New-Item -HypervisorConnectionName $ClusterName -NetworkPath @("$NetworkPath") -Path @("XDHyp:\HostingUnits\$($ClusterName)-AHV") -PersonalvDiskStoragePath @() -RootPath $RootPath -StoragePath @("XDHyp:\Connections\$($ClusterName)\VDI.storage")
            
            write-host "Added Hosting Connection for $($ClusterName)"
        } # Process
        
        End
        {
            Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        } # End
    
    } # Set-NutanixVMPower
    