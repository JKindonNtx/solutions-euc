<#
.Synopsis
    Get AHV Cluster Details
.DESCRIPTION
    This function will connect to and gather information about an AHV cluster
.EXAMPLE
    Get-Cluster -IP "10.10.10.10" -UserName "admin" -Password "nutanix"
.INPUTS
    IP - The IP Address for the cluster
    UserName - The user name to mount the drive as
    Password - The password for the user
.NOTES
    Sven Huisman        29/11/2022          v1.0.0              Function Creation
    David Brett         29/11/2022          v1.0.1              Update error handling
.FUNCTIONALITY
    This is used to connect to and gather information about an AHV Cluster
#>

function Get-Cluster
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
        $Password
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'Get-Cluster'" 
    }

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":IP: $IP" 
        Write-Host (Get-Date)":Username: $UserName" 
        Write-Host (Get-Date)":Password: <Not Displayed>" 

        # Build JSON and connect to cluster for information
        $credPair = "$($UserName):$($Password)"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
        $headers = @{ Authorization = "Basic $encodedCredentials" }
        $URL = "https://$($IP):9440/api/nutanix/v3/clusters/list"

        $Payload = @{
            kind   = "cluster"
            offset = 0
            length = 999
        } 
        $JSON = $Payload | convertto-json
        
        try {
            $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
        }
        catch {
            Start-Sleep 10
            Write-Host (Get-Date) ": Going once"
            $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
        }
    }
    
    End
    {
        Write-Host (Get-Date)":Finishing 'Get-Cluster'" 
        Return $task
    }
}