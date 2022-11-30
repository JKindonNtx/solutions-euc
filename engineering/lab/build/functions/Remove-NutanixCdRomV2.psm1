<#
.Synopsis
    Remove the CD-ROM Drive from a Nutanix VM
.DESCRIPTION
    Remove the CD-ROM Drive from a Nutanix VM
.EXAMPLE
    Remove-NutanixCdRomV2 -IP "10.10.10.10" -UserName "admin" -Password "Password" -VMUUID "{UUID}"
.INPUTS
    IP - The Cluster IP
    UserName - the cluster user name
    Password - the cluster password
    VMUUID - the UUID for the VM
.NOTES
    David Brett      28/11/2022         v1.0.0             Function Creation
.FUNCTIONALITY
    Remove the CD-ROM Drive from a Nutanix VM
#>

function Remove-NutanixCdRomV2
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
        $Password,
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
        $VMUUID
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'Remove-NutanixCdRomV2'" 
    }

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":VMUUID: $VMUUID" 

        $credPair = "$($UserName):$($Password)"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
        $headers = @{ Authorization = "Basic $encodedCredentials" }
        $URL = "https://$($IP):9440/PrismGateway/services/rest/v2.0/vms/$($VMUUID)/disks/detach"

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
        Write-Host (Get-Date)":Finishing 'Remove-NutanixCdRomV2'" 
        Return $task
    }
}