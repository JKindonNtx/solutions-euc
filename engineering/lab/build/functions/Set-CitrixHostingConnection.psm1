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
            [Parameter(
                Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true
            )]
            [Alias('ClusterIP')]
            [system.string[]]$IP,
    
            [Parameter(
                Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true
            )]
            [Alias('User')]
            [system.string[]]$UserName,
    
            [Parameter(
                Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true
            )]
            [Alias('Pass')]
            [system.string[]]$Password,
    
            [Parameter(
                Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true
            )]
            [system.string[]]$VLAN,
    
            [Parameter(
                Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true
            )]
            [ValidateSet("Create", "Delete")]
            [system.string[]]$Action
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
            Write-Host (Get-Date)":Action: $Action" 
    
            $credPair = "$($UserName):$($Password)"
            $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
            $headers = @{ Authorization = "Basic $encodedCredentials" }
            $URL = "https://$($IP):9440/PrismGateway/services/rest/v2.0/$APIpath"
    
            # Build Payload
            $Payload = @{
                "transition"="$($Action)"
            } 
            $JSON = $Payload | convertto-json
    
            # Invoke Rest Method
            try {
                $task = Invoke-RestMethod -Uri $URL -method "POST" -body $JSON -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
            }
            catch {
                Start-Sleep 10
                Write-Host (Get-Date) ": Going once"
                $task = Invoke-RestMethod -Uri $URL -method "POST" -body $JSON -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
            }
            Add-PSSnapin Citrix.*
            $NetName = "vlan_100"
            $ConnectionName = "nutanix_ahv"
            $ResourceName = "$NetName"
            $Pwd = $Pwd | ConvertTo-SecureString -asPlainText -Force
            $RootPath = "XDHyp:\Connections\$ConnectionName\"
            $NetworkPath = "$RootPath" + "$Netname.network"

            # Adding Nutanix Connection
            Write-Verbose "Adding Nutanix Configuration" -Verbose
            Set-HypAdminConnection -AdminAddress "$XDC01:443"
            New-Item -ConnectionType "Custom" -CustomProperties "" -HypervisorAddress @("$CVM") -Path @("$RootPath") -Persist -PluginId "AcropolisFactory" -Scope @() -SecurePassword $Pwd -UserName $User
            $Hyp = Get-ChildItem -Path @('XDHyp:\Connections')
            $HypGUID = $Hyp.HypervisorConnectionUid.Guid
            New-BrokerHypervisorConnection -AdminAddress "$XDC01:443" -HypHypervisorConnectionUid "$HypGUID"
            $job = [Guid]::NewGuid()
            New-Item -HypervisorConnectionName $ConnectionName -JobGroup $job -NetworkPath @("$NetworkPath") -Path @("XDHyp:\HostingUnits\$ResourceName") -PersonalvDiskStoragePath @() -RootPath $RootPath -StoragePath @()

        } # Process
        
        End
        {
            Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
            Return $task
        } # End
    
    } # Set-NutanixVMPower
    