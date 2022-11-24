Function Remove-CDROMV2 {
    <#
    .Synopsis
        This function will remove CD-ROM of the VM using the V2 API.
    .Description
        This function will remove CD-ROM of the VM using REST API call based on Invoke-RestMethod. 
    #>

    Param (
        [string] $ClusterIP,
        [string] $nxPassword,
        [string] $nxusrname,
        [string] $VMUUID,
        [string] $debug
    )

    $credPair = "$($nxusrname):$($nxPassword)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    $URL = "https://$($ClusterIP):9440/PrismGateway/services/rest/v2.0/vms/$($VMUUID)/disks/detach"

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

    Return $task
}