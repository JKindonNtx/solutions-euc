function Get-OmnissaGroupSID {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$GroupName
    )

    $Path = "$($ApiEndpoint)/rest/external/v1/ad-users-or-groups?group_only=true"
    Write-Log -Message "Getting Group SID for $($GroupName)" -Level Info

    $groups = Invoke-PublicApiMethodOmnissa -ApiEndpoint $ApiEndpoint -UserName $UserName -Password $Password -Domain $Domain -Method "GET" -Path $Path
    
    foreach($group in $groups){
        if ($group.name -eq "$($GroupName)") {
            $Return = $group
        }
    }
    Return $Return
}