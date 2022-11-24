Function Get-Cluster {
    <#
    .Synopsis
        This function will collect cluster information.
    .Description
        This function will collect the cluster information using REST API call based on Invoke-RestMethod
    #>

    Param (
    [string] $debug
    )

    $credPair = "$($mgmtUser):$($mgmtPassword)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    $URL = "https://$($mgmtIP):9440/api/nutanix/v3/clusters/list"

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

    Return $task
}