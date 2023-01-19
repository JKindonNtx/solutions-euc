Function Set-VSIAzLaunchers{
    Param(
    $resourceGroup = "RD-CapacityPlanning",
    $Image = "Win2019Datacenter",
    $Size = "Standard_D2_v3",
    $location = "westeurope",
    $Amount = 1,
    $applianceUrl = "https://vappliance.westeurope.cloudapp.azure.com",
    $Admin = "loginvsi",
    $Password = "Password!123",
    $NamingPattern = "Launch_",
    [switch]$Force
)

if ($(az vm list --query "[? contains(name,'$NamingPattern')]") -ne '[]' ) {
    if ($Force){
        az vm delete --yes --ids $(az vm list --query "[? contains(name,'$NamingPattern')][].id" -o tsv -g $resourceGroup)
    }
    else {
        az vm restart --ids $(az vm list --query "[? contains(name,'$NamingPattern')][].id" -o tsv -g $resourceGroup)
        $skipCreate = $true        
    }
}

if (-not $skipCreate)
{
$launchers = @()
for ($i = 1; $i -le $Amount; $i++) {
    $launchers += "$NamingPattern{0:D4}" -f $i
}


$ScriptPath = "$PSScriptRoot\..\az\Install-Launcher.ps1"
if ($PSEdition -eq "Core")
{
$launchers | foreach-object -ThrottleLimit 10 -parallel {
    # local Admin credentials to be set on the VM
    az vm create -n $_ -g $using:resourcegroup --image Win2019Datacenter --authentication-type password --admin-password $using:Password --admin-username $using:Admin --size $using:Size --location $using:location --public-ip-address '""' --vnet-name "$using:resourceGroup-vnet" --subnet "default"
    az vm run-command invoke  --command-id RunPowerShellScript --name $_ -g $using:resourcegroup --scripts "@$using:ScriptPath" --parameters "applianceUrl=$($using:applianceUrl)" "credential=$($using:admin);$($using:Password)"
}
}
else {
    $launchers | foreach-object {
        # local Admin credentials to be set on the VM
        az vm create -n $_ -g $resourcegroup --image Win2019Datacenter --authentication-type password --admin-password $password --admin-username $Admin --size $Size --location $location --public-ip-address '""' --vnet-name "$resourceGroup-vnet" --subnet "default"
        az vm run-command invoke  --command-id RunPowerShellScript --name $_ -g $resourcegroup --scripts "@$ScriptPath" --parameters "applianceUrl=$($applianceUrl)" "credential=$($admin);$($Password)"
    }   
}

}
}