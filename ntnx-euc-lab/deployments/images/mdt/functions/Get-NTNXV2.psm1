Function Get-NTNXV2 {
    <#
    .Synopsis
        This function will collect information using the V2 API.
    .Description
        This function will collect the information using REST API call based on Invoke-RestMethod
    #>

    Param (
        [string] $ClusterIP,
        [string] $nxPassword,
        [string] $nxusrname,
        [string] $APIpath,
        [string] $debug
    )

    $credPair = "$($nxusrname):$($nxPassword)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    $URL = "https://$($ClusterIP):9440/PrismGateway/services/rest/v2.0/$APIpath"

    try {
        $task = Invoke-RestMethod -Uri $URL -method "get" -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
    }
    catch {
        Start-Sleep 10
        Write-Host (Get-Date) ": Going once"
        $task = Invoke-RestMethod -Uri $URL -method "get" -ContentType 'application/json' -SkipCertificateCheck -headers $headers;
    }

    Return $task
}