Function Get-NTNXTasks {
    <#
    .Synopsis
        This function will get the running Nutanix Tasks
    .Description
        This function will get the running Nutanix Tasks
    #>
    Param (
        [string] $ClusterIP,
        [string] $nxPassword,
        [string] $nxusrname,
        [string] $ISOtask,
        [string] $debug
    )
    
    $credPair = "$($nxusrname):$($nxPassword)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    $URL = "https://$($ClusterIP):9440/PrismGateway/services/rest/v2.0/tasks/poll"
    $Payload = "{ `
        ""completed_tasks"": [`
            """ + $ISOtask + """
          ]
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