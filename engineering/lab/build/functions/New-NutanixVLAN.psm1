function New-NutanixVLAN {
<#
    .SYNOPSIS
    Creates a VLAN.

    .DESCRIPTION
    This function will create a new VLAN on a Nutanix Cluster.
    
    .PARAMETER IP
    The Nutanix Cluster IP

    .PARAMETER UserName
    The user name to use for connection

    .PARAMETER Password
    The password for the connection

    .PARAMETER VLAN
    The VLAN Number

    .PARAMETER VLANName
    The VLAN Description

    .EXAMPLE
    PS> New-NutanixVLAN -IP "10.10.10.10" -UserName "admin" -Password "nutanix" -VLAN "164" -VLANName "VLAN164"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    Task variable containing the output of the Invoke-RestMethod command run

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/New-NutanixVLAN.md

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
        [system.string[]]$VLANName
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
        Write-Host (Get-Date)":VLANName: $VLANName" 

        # Create JSON Payload
        $Payload = "{ `
            ""name"":""" + $VLANName + """, `
            ""vlan_id"":""" + $VLAN + """ `
        }"

        # Invoke RestMethod
        try {
            $task = Invoke-NutanixAPI -IP "$($IP)" -Password "$($Password)" -UserName "$($UserName)" -APIpath "networks" -method "POST" -body $Payload 
        }
        catch {
            write-host "Error creating VLAN $($VLANName) - quitting"
            Break
        }
    } # Process
    
    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        Return $task
    } # End

} # New-NutanixVLAN
