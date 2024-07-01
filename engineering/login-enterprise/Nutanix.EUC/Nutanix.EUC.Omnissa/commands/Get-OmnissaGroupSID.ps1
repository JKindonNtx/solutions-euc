function Get-OmnissaGroupSID {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$GroupName
    )

    $OmnissaConnection = Connect-OmnissaApi -url $ApiEndpoint -username $UserName -password $Password -domain $Domain
    
    $header = @{
            'Authorization' = "Bearer " + $OmnissaConnection.access_token
            'Accept' = "application/json"
            'Content-Type' = "application/json"
        }

    $URL = "$($ApiEndpoint)/rest/external/v1/ad-users-or-groups?group_only=true"

    Write-Log -Message "Getting Group SID for $($GroupName)" -Level Info

    $groups = invoke-restmethod -Method Get -uri $url -Headers $header -SkipCertificateCheck
    
    foreach($group in $groups){
        if ($group.name -eq "$($GroupName)") {
            $Return = $group
        }
    }
    Return $Return
}