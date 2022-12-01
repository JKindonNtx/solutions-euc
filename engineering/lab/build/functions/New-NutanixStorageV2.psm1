<#
.Synopsis
    Creates a new Storage Container
.DESCRIPTION
    Creates a new Storage Container
.EXAMPLE
    New-NutanixStorageV2 -IP "10.10.10.10" -UserName "admin" -Password "nutanix" -VLAN "164" -Container "VDI"
.INPUTS
    IP - The IP Address for the cluster
    UserName - The user name to mount the drive as
    Password - The password for the user
    Container - The name of the storage container

.NOTES
    Sven Huisman        29/11/2022          v1.0.0              Function Creation
    David Brett         29/11/2022          v1.0.1              Update error handling
.FUNCTIONALITY
    Creates a new Storage Container
#>

function New-NutanixStorageV2
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
        $Container
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'New-NutanixStorageV2'" 
    }

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":Container: $Container" 

        # Build JSON and connect to cluster for information
        $credPair = "$($UserName):$($Password)"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
        $headers = @{ Authorization = "Basic $encodedCredentials" }
        $URL = "https://$($IP):9440/PrismGateway/services/rest/v2.0/storage_containers"

        $Payload = "{ `
            ""compression_delay_in_secs"":""" + "0" + """, `
            ""compression_enabled"":""" + "true" + """, `
            ""enable_software_encryption"":""" + "false" + """, `
            ""encrypted"":""" + "false" + """, `
            ""name"":""" + $Container + """ `
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
        Write-Host (Get-Date)":Finishing 'New-NutanixStorageV2'" 
        Return $task
    }
}





