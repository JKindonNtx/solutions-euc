function Get-NutanixAPI {
<#
    .SYNOPSIS
    Gets Nutanix details based on incoming API path.

    .DESCRIPTION
    This function will connect to and gather information about a specific API path being passed into the function.
    
    .PARAMETER IP
    The Nutanix Cluster IP

    .PARAMETER UserName
    The user name to use for connection

    .PARAMETER Password
    The password for the connection

    .PARAMETER APIPath
    The path of the API to query

    .PARAMETER Silent
    Supress the output of the function

    .EXAMPLE
    PS> Get-NutanixAPI -IP "10.10.10.10" -UserName "admin" -Password "nutanix" -APIPath "containers"

    .EXAMPLE
    PS> Get-NutanixAPI -ClusterIP "10.10.10.10" -User "admin" -Pass "nutanix" -APIPath "networks" -Silent

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    Task variable containing the output of the Invoke-RestMethod command run

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Get-NutanixAPI.md

    .NOTES
    Author          Version         Date            Detail
    Sven Huisman    v1.0.0          28/11/2022      Function creation
    David Brett     v1.0.1          06/12/2022      Updated Parameter definition and added Alias' for UserName, Password, IP and APIPath
                                                    Updated function header to include MD help file
                                                    Changed Write-Host from hardcoded function name to $($PSCmdlet.MyInvocation.MyCommand.Name)
                                                    Added -Silent switch to supress the output to the console if required

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
        [Alias('API')]
        [system.string[]]$APIPath,

        [Parameter(
            Mandatory=$false, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [Switch[]]$Silent
    )

    Begin
    {
        Set-StrictMode -Version Latest
        if(!$Silent){ Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" }
    } # Begin

    Process
    {
        # Display Function Parameters
        if(!$Silent){ Write-Host (Get-Date)":API Path: $APIPath" }

        # Build JSON and connect to cluster for information
        $credPair = "$($UserName):$($Password)"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
        $headers = @{ Authorization = "Basic $encodedCredentials" }
        $URL = "https://$($IP):9440/PrismGateway/services/rest/v2.0/$APIPath"

        try {
            $task = Invoke-RestMethod -Uri $URL -method "get" -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
        }
        catch {
            Start-Sleep 10
            if(!$Silent){ Write-Host (Get-Date) ": Going once" }
            $task = Invoke-RestMethod -Uri $URL -method "get" -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
        }
    } # Process
    
    End
    {
        if(!$Silent){ Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" }
        Return $task
    } # End

} # Get-NutanixAPI