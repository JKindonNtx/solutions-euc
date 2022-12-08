function Remove-NutanixCdRomV2 {
<#
    .SYNOPSIS
    Removes a CD-ROM.

    .DESCRIPTION
    This function will remove the CD-ROM drive from a Virtual Machine on the Nutanix Cluster.
    
    .PARAMETER IP
    The Nutanix Cluster IP

    .PARAMETER UserName
    The user name to use for connection

    .PARAMETER Password
    The password for the connection

    .PARAMETER VMUUID
    The UUID of the Virtual Machine

    .EXAMPLE
    PS> Remove-NutanixCDROM -IP "10.10.10.10" -UserName "admin" -Password "Password" -VMUUID "{UUID}"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    Task variable containing the output of the Invoke-RestMethod command run

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Remove-NutanixCDROM.md

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
        [system.string[]]$VMUUID
    )

    Begin
    {
        Set-StrictMode -Version Latest
        Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
    } # Begin

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":VMUUID: $VMUUID" 

        $credPair = "$($UserName):$($Password)"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
        $headers = @{ Authorization = "Basic $encodedCredentials" }
        $URL = "https://$($IP):9440/PrismGateway/services/rest/v2.0/vms/$($VMUUID)/disks/detach"

        # Create Payload
        $Payload = "{ `
            ""vm_disks"":[ `
                { `
                    ""disk_address"": `
                    { `
                        ""device_bus"":""SATA"", `
                        ""device_index"":0 `
                    } `
                }] `
        }"

        # Invoke Rest Method
        try {
            $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
        }
        catch {
            Start-Sleep 10
            Write-Host (Get-Date) ": Going once"
            $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
        }
    } # Process
    
    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        Return $task
    } # End

} # Remove-NutanixCDROM