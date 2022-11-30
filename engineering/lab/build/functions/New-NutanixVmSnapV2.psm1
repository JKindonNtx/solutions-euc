<#
.Synopsis
    Create a VM Snapshot
.DESCRIPTION
    Create a VM Snapshot
.EXAMPLE
    New-NutanixVmSnapV2 -IP "10.10.10.10" -UserName "admin" -Password "Password" -VMUUID "{UUID}" -SnapName "Snapshot_VM"
.INPUTS
    IP - The IP Address for the cluster
    UserName - The user name to mount the drive as
    Password - The password for the user
    VMUUID - The VM UUID
    SnapName - The name of the snapshot
.NOTES
    Sven Huisman        29/11/2022          v1.0.0              Function Creation
    David Brett         29/11/2022          v1.0.1              Update error handling
.FUNCTIONALITY
    Create a VM Snapshot
#>

function New-NutanixVmSnapV2
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
        $VMUUID,
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true
                   )]
        [string[]]
        $SnapName
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'New-NutanixVmSnapV2'" 
    }

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":VMUUID: $VMUUID" 
        Write-Host (Get-Date)":SnapName: $SnapName" 

        # Build JSON and connect to create snapshot
        $credPair = "$($UserName):$($Password)"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
        $headers = @{ Authorization = "Basic $encodedCredentials" }
        $URL = "https://$($IP):9440/PrismGateway/services/rest/v2.0/snapshots"

        $Payload = "{ `
            ""snapshot_specs"":[ `
                {""snapshot_name"":""" + $Snapname + """, `
                ""vm_uuid"":""" + $VMUUID + """ `
            }] `
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
        Write-Host (Get-Date)":Finishing 'New-NutanixVmSnapV2'" 
        Return $task
    }
}
