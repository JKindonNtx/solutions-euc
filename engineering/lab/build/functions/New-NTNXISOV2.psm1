Function New-NTNXISOV2 {
    <#
    .Synopsis
        This function will create a ISO on the provided container using the V2 API.
    .Description
        This function will create a ISO on the provided container using the V2 API.
    #>
    Param (
        [string] $ClusterIP,
        [string] $nxPassword,
        [string] $nxusrname,
        [string] $StorageUUID,
        [string] $ISOurl,
        [string] $ISOname,
        [string] $debug
    )
    $credPair = "$($nxusrname):$($nxPassword)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    $URL = "https://$($ClusterIP):9440/PrismGateway/services/rest/v2.0/images"

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

    Return $task
}