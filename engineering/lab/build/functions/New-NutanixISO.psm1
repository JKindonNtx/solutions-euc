function New-NutanixISO {
<#
    .SYNOPSIS
    Upload a new ISO file to a Nutanix Cluster.

    .DESCRIPTION
    This function will take an ISO image from a web server passed in and upload it to a Nutanix Cluster image library for use within that cluster.
    
    .PARAMETER IP
    The Nutanix Cluster IP

    .PARAMETER UserName
    The user name to use for connection

    .PARAMETER Password
    The password for the connection

    .PARAMETER StorageUUID
    The storage UUID for the ISO

    .PARAMETER ISOurl
    The ISO url to upload from

    .PARAMETER ISOname
    The name for the ISO

    .EXAMPLE
    PS> New-NutanixISO -IP "10.10.10.10" -UserName "admin" -Password "nutanix" -StorageUUID "1234223-321221" -ISOUrl "https://webserver/" -ISOName "build.iso" 

    .EXAMPLE
    PS> New-NutanixISO -IP "10.10.10.10" -User "admin" -Pass "nutanix" -StorageUUID "1234223-321221" -ISOUrl "https://webserver/" -ISOName "build.iso"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    Task variable containing the output of the Invoke-RestMethod command run

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/New-NutanixISO.md

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
        [system.string[]]$StorageUUID,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$ISOurl,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$ISOname
    )

    Begin
    {
        Set-StrictMode -Version Latest
        Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
    } # Begin

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":StorageUUID: $StorageUUID" 
        Write-Host (Get-Date)":ISOurl: $ISOurl" 
        Write-Host (Get-Date)":ISOname: $ISOname" 

        # Build JSON and connect to cluster for information
        $credPair = "$($UserName):$($Password)"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
        $headers = @{ Authorization = "Basic $encodedCredentials" }
        $URL = "https://$($IP):9440/PrismGateway/services/rest/v2.0/images"

        # Build JSON Payload
        $Payload = "{ `
            ""image_import_spec"": `
                {""storage_container_uuid"":""" + $StorageUUID + """ , `
                ""url"":""" + $ISOurl + """ `
            }, `
            ""image_type"": ""ISO_IMAGE"", `
            ""name"":""" + $ISOname + """ `
        }"

        # Invoke the RestMethod
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

} # New-NutanixISO
