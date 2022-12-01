<#
.Synopsis
    Creates a new VLAN
.DESCRIPTION
    Created a new VLAN
.EXAMPLE
    New-NutanixVlanV2 -IP "10.10.10.10" -UserName "admin" -Password "nutanix" -VLAN "164" -VlanName "VLAN164"
.INPUTS
    IP - The IP Address for the cluster
    UserName - The user name to mount the drive as
    Password - The password for the user
    VLAN - The VLAN for the network
    VLANName - The name for the VLAN

.NOTES
    Sven Huisman        29/11/2022          v1.0.0              Function Creation
    David Brett         29/11/2022          v1.0.1              Update error handling
.FUNCTIONALITY
    Created a new VLAN
#>

function New-NutanixVlanV2
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
        $VLAN,
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true
                   )]
        [string[]]
        $VLANName
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'New-NutanixVlanV2'" 
    }

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":VLAN: $VLAN" 
        Write-Host (Get-Date)":VLANName: $VLANName" 

        # Build JSON and connect to cluster for information
        $credPair = "$($UserName):$($Password)"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
        $headers = @{ Authorization = "Basic $encodedCredentials" }
        $URL = "https://$($IP):9440/PrismGateway/services/rest/v2.0/networks"

        $Payload = "{ `
            ""name"":""" + $VLANName + """, `
            ""vlan_id"":""" + $VLAN + """ `
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
        Write-Host (Get-Date)":Finishing 'New-NutanixVlanV2'" 
        Return $task
    }
}
