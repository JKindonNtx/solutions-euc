Function Connect-VSIAz {
Param(
    $subscriptionId,
    $UserName,
    $Password
)
    # requires Azure CLI to be installed

    if ($(az account list) -eq '[]') {
        Write-Host "not logged in to az, logging in..."
        if ([string]::IsNullOrEmpty($UserName)) {
            az login 
        } else {
            az login -u $UserName -p $password
        }

}
    az account set --subscription $subscriptionId | out-Null
}