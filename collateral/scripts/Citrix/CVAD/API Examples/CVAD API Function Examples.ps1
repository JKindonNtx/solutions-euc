# Must be PowerShell Core. Not looking at PS 5.1.

# Can use Invoke-WebRequest if needed as follows: ((Invoke-WebRequest -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Content | ConvertFrom-Json).Items
# Prefer Invoke-RestMethod for Simplicity as follows: (Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Items

## ------Variables------
$DDC = "10.68.68.90" #Controller Address
$Username = "jkindon_admin@contoso.local"
$Password = 'VeryComplexPassword11'

## ------Functions------

function Get-CVADAccessToken {
    param (
        [string]$DDC,
        [string]$AdminCredential
    )

    $TokenURL = "https://$DDC/cvad/manage/Tokens"
    $Headers = @{
        Accept = "application/json"
        Authorization = "Basic $EncodedAdminCredential"
    }
    try {
        $Response = Invoke-WebRequest -Uri $TokenURL -Method Post -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
    }
    catch {
        <#Do this if a terminating exception happens#>
    }
    
    $AccessToken = $Response.Content | ConvertFrom-Json
    return $AccessToken.Token
} #Get the access Token for the CVAD Site based on Credentials Defined

function Get-CVADSiteID {
    param (
        [string]$DDC,
        [string]$AccessToken
    )

    $URL = "https://$DDC/cvad/manage/Me"
    $Headers = @{
        "Accept"            = "application/json";
        "Authorization"     = "CWSAuth Bearer=$AccessToken";
        "Citrix-CustomerId" = "CitrixOnPremises";
    }

    try {
        $Response = Invoke-WebRequest -Uri $URL -Method Get -Header $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
    }
    catch {
        <#Do this if a terminating exception happens#>
    }

    $SiteID = $Response.Content | ConvertFrom-Json
    
    return $SiteID.Customers.Sites.Id
} #Get the CVAD SIte ID for all calls


## ------Execution Examples------

$AccessToken = Get-CVADAccessToken -DDC $DDC -AdminCredential $EncodedAdminCredential
# Make sure this is never #$null
$cvad_site_id = Get-CVADSiteID -DDC $DDC -AccessToken $AccessToken
# Make sure this is never #$null

# Create new Headers for CVAD calls moving forward including Site ID
$Headers = @{
    "Accept"            = "application/json";
    "Authorization"     = "CWSAuth Bearer=$AccessToken";
    "Citrix-CustomerId" = "CitrixOnPremises";
    "Citrix-InstanceId" = "$cvad_site_id";
}

## EXAMPLE: Get Catalogs
#----------------------------------------------------------------------------------------------------------------------------
# Set API call detail
#----------------------------------------------------------------------------------------------------------------------------
$Method = "Get"
$RequestUri = "https://$DDC/cvad/manage/MachineCatalogs/"
#----------------------------------------------------------------------------------------------------------------------------

try {
    #$cvad_machine_catalogs = ((Invoke-WebRequest -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Content | ConvertFrom-Json).Items
    $cvad_machine_catalogs = (Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Items
}
catch {
    <#Do this if a terminating exception happens#>
}

## EXAMPLE Get Hypervisors
#----------------------------------------------------------------------------------------------------------------------------
# Set API call detail
#----------------------------------------------------------------------------------------------------------------------------
$Method = "Get"
$RequestUri = "https://$DDC/cvad/manage/Hypervisors/"
#----------------------------------------------------------------------------------------------------------------------------

try {
    #$cvad_hypervisors = ((Invoke-WebRequest -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Content | ConvertFrom-Json).Items
    $cvad_hypervisors = (Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Items
}
catch {
    <#Do this if a terminating exception happens#>
}

## EXAMPLE Get Delivery Groups
#----------------------------------------------------------------------------------------------------------------------------
# Set API call detail
#----------------------------------------------------------------------------------------------------------------------------
$Method = "Get"
$RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/"
#----------------------------------------------------------------------------------------------------------------------------

try {
    #$cvad_delivery_groups = ((Invoke-WebRequest -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Content | ConvertFrom-Json).Items
    $cvad_delivery_groups = (Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Items
}
catch {
    <#Do this if a terminating exception happens#>
}


## EXAMPLE Set Maintenance Mode on a Delivery Group
$cvad_target_delivery_group = $cvad_delivery_groups | Where-Object {$_.name -eq "W10 Dedicated Demo"}

#----------------------------------------------------------------------------------------------------------------------------
# Set API call detail
#----------------------------------------------------------------------------------------------------------------------------
$Method = "Patch"
$RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($cvad_target_delivery_group.Id)"
$ContentType = "application/json"
$PayloadContent = @{
    InMaintenanceMode = $False
}
$Payload = (ConvertTo-Json $PayloadContent)
#----------------------------------------------------------------------------------------------------------------------------

try {
    Invoke-RestMethod -Method $Method -Headers $headers -Body $Payload -Uri $RequestUri -SkipCertificateCheck -ContentType $ContentType -ErrorAction Stop
}
catch {
    <#Do this if a terminating exception happens#>
}
