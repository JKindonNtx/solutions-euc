Function New-VMSnapV2 {
    <#
    .Synopsis
        This function will create a snapshot of the VM using the V2 API.
    .Description
        This function will create a snapshot of the VM using REST API call based on Invoke-RestMethod. 
    #>

    Param (
        [string] $ClusterIP,
        [string] $nxPassword,
        [string] $nxusrname,
        [string] $VMUUID,
        [string] $SnapName,
        [string] $debug
    )

    $credPair = "$($nxusrname):$($nxPassword)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    $URL = "https://$($ClusterIP):9440/PrismGateway/services/rest/v2.0/snapshots"

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

    Return $task
}