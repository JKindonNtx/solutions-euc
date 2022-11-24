Function Set-VMpowerV2 {
    <#
    .Synopsis
        This function will set Power state of VM using the V2 API.
    .Description
        This function will set Power state using REST API call based on Invoke-RestMethod.
        Allowed actions: "ON", "OFF", POWERCYCLE", "RESET", "PAUSE", "SUSPEND", "RESUME", "SAVE", "ACPI_SHUTDOWN", "ACPI_REBOOT" 
    #>

    Param (
        [string] $ClusterIP,
        [string] $nxPassword,
        [string] $nxusrname,
        [string] $APIpath,
        [string] $Action,
        [string] $debug
    )

    $credPair = "$($nxusrname):$($nxPassword)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    $URL = "https://$($ClusterIP):9440/PrismGateway/services/rest/v2.0/$APIpath"

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

    Return $task
}