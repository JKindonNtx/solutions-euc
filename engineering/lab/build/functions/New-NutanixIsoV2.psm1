<#
.Synopsis
    Upload a new ISO file to the cluster
.DESCRIPTION
    TUpload a new ISO file to the cluster
.EXAMPLE
    Get-NutanixV2 -IP "10.10.10.10" -UserName "admin" -Password "nutanix" -APIPath "containers"
.INPUTS
    IP - The IP Address for the cluster
    UserName - The user name to mount the drive as
    Password - The password for the user
    StorageUUID - The storage UUID for the ISO
    ISOurl - The ISO url to upload from
    ISOname - The name for the ISO

.NOTES
    Sven Huisman        29/11/2022          v1.0.0              Function Creation
    David Brett         29/11/2022          v1.0.1              Update error handling
.FUNCTIONALITY
    Upload a new ISO file to the cluster
#>

function New-NutanixIsoV2
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
        $IP,
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true
                   )]
        [string[]]
        $UserName,
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true
                   )]
        [string[]]
        $Password,
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true
                   )]
        [string[]]
        $StorageUUID,
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true
                   )]
        [string[]]
        $ISOurl,
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true
                   )]
        [string[]]
        $ISOname
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'New-NutanixIsoV2'" 
    }

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

        $Payload = "{ `
            ""image_import_spec"": `
                {""storage_container_uuid"":""" + $StorageUUID + """ , `
                ""url"":""" + $ISOurl + """ `
            }, `
            ""image_type"": ""ISO_IMAGE"", `
            ""name"":""" + $ISOname + """ `
        }"

        try {
            $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
        }
        catch {
            Start-Sleep 10
            Write-Host (Get-Date) ": Going once"
            $task = Invoke-RestMethod -Uri $URL -method "POST" -body $Payload -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
        }
    }
    
    End
    {
        Write-Host (Get-Date)":Finishing 'New-NutanixIsoV2'" 
        Return $task
    }
}