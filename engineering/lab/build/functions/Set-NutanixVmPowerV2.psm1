<#
.Synopsis
    Set Power state for a Nutanix VM
.DESCRIPTION
    Set Power state for a Nutanix VM
.EXAMPLE
    Set-NutanixvTpmAcli -ClusterIP "10.10.10.10" -CVMsshpassword "password" -VMname "VM"
.INPUTS
    ClusterIP - The Nutanix Cluster IP
    CVMsshpassword - The CVM SSH Password
    VMname - The VM Name
.NOTES
    Sven Huisman      28/11/2022         v1.0.0             Function Creation
.FUNCTIONALITY
    Set Power state for a Nutanix VM
#>

function Set-NutanixVmPowerV2
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
        $APIpath,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string[]]
        $Action
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'Set-NutanixVmPowerV2'" 
    }

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":APIpath: $APIpath" 
        Write-Host (Get-Date)":Action: $Action" 

        $credPair = "$($UserName):$($Password)"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
        $headers = @{ Authorization = "Basic $encodedCredentials" }
        $URL = "https://$($IP):9440/PrismGateway/services/rest/v2.0/$APIpath"

        $Payload = @{
            "transition"="$($Action)"
        } 
        $JSON = $Payload | convertto-json

        try {
            $task = Invoke-RestMethod -Uri $URL -method "POST" -body $JSON -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
        }
        catch {
            Start-Sleep 10
            Write-Host (Get-Date) ": Going once"
            $task = Invoke-RestMethod -Uri $URL -method "POST" -body $JSON -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
        }
    }
    
    End
    {
        Write-Host (Get-Date)":Finishing 'Set-NutanixVmPowerV2'" 
        Return $task
    }
}
