Param(
    $subscriptionId = "047db6ab-9baa-49fc-b7da-8317dfe5ea36",
    $resourceGroupName = "RD-CapacityPlanning",
    $launcherImage = "Win2019Datacenter",
    $launcherSize = "Standard_D2_v3",
    $location = "westeurope",
    $numLaunchers = 1,
    $applianceUrl = "https://vappliance.westeurope.cloudapp.azure.com"
)
# requires Azure CLI to be installed
if ($(az account list) -eq '[]') {
    Write-Host "not logged in to az, logging in..."
    az login
}
az account set --subscription $subscriptionId
if ($(az vm list --query "[? contains(name,'Launch')]") -ne '[]' ) {
    az vm delete --yes --ids $(az vm list --query "[? contains(name,'Launch')][].id" -o tsv -g $resourceGroupName)
}


$launchers = @()
for ($i = 1; $i -le $numLaunchers; $i++) {
    $launchers += "Launch{0:D4}" -f $i
}

$admin = "loginvsi"
$password = "Password!123"
$ScriptPath = "$PSScriptRoot\az\Install-Launcher.ps1"
$launchers | foreach-object -ThrottleLimit 10 -parallel {
    # local Admin credentials to be set on the VM
    az vm create -n $_ -g $using:resourcegroupName --image Win2019Datacenter --authentication-type password --admin-password $using:password --admin-username $using:admin --size $using:launcherSize --location $using:location --public-ip-address """" --vnet-name "$resourceGroupName-vnet" --subnet "default"
    az vm run-command invoke  --command-id RunPowerShellScript --name $_ -g $using:resourcegroupName --scripts "@$using:ScriptPath" --parameters "applianceUrl=$($using:applianceUrl)" "credential=$($using:admin);$($using:Password)"
}
