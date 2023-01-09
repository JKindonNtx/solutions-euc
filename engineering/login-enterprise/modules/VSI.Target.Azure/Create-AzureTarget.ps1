Param(
    $subscriptionId = "047db6ab-9baa-49fc-b7da-8317dfe5ea36",
    $resourceGroupName = "RD-CapacityPlanning",
    $targetImage = "MicrosoftWindowsDesktop:windows-ent-cpc:win10-21h2-ent-cpc-m365-g2:latest", #19044.1348.2111180034
    $targetSize = "Standard_F8s_v2",
    $location = "westeurope"#,
    #$applianceUrl = "https://vappliance.westeurope.cloudapp.azure.com"
)
# requires Azure CLI to be installed
if ($(az account list) -eq '[]') {
    Write-Host "not logged in to az, logging in..."
    az login
}
az account set --subscription $subscriptionId

az vm delete --yes --ids $(az vm list --query "[? contains(name,'Target')][].id" -o tsv -g $resourceGroupName)



$admin = "loginvsi"
$password = "Password!123"

#$ScriptPath = "$PSScriptRoot\az\Install-Launcher.ps1"
$vnetName = "$($resourceGroupName)-vnet"
az vm create -n "Target" -g $resourcegroupName --image $targetImage --authentication-type password --admin-password $password --admin-username $admin --size $targetSize --location $location --vnet-name $vnetName --subnet "default" --public-ip-address """"
#az vm run-command invoke  --command-id RunPowerShellScript --name "Target" -g $resourceGroupName --scripts $PSScriptRoot\az\Install-Launcher.ps1 --parameters "applianceUrl=$($applianceUrl)" "credential=$($admin);$($Password)"