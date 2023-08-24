# Lock Down Unsecure Delivery Groups in Citrix DaaS

## Objective

Reviews Citrix DaaS Delivery Groups for Adaptive Access configurations (Network Locations) and disables any open Delivery Groups. https://docs.citrix.com/en-us/citrix-daas/manage-deployment/adaptive-access/adaptive-access-based-on-users-network-location

## Technical requirements for running the script

The script is compatible with Windows PowerShell 5.1 onwards.

This means that the technical requirements for the workstation or server running the script are as follows:

- Any Windows version which can run Windows PowerShell 5.1.
- A Citrix Cloud DaaS [Secure Client](https://docs.citrix.com/en-us/citrix-cloud/sdk-api.html#secure-clients).

## Parameter Details

The following parameters exist to drive the behaviour of the script:

#### Mandatory and recommended parameters:

- `Region`: Mandatory **`String`**. The Citrix Cloud DaaS Tenant Region. Either AP-S (Asia Pacific), US (USA), EU (Europe) or JP (Japan).
- `CustomerID`: Mandatory **`String`**. The Citrix Cloud Customer ID.
- `SecureClientFile`: Optional **`String`**. The path to the Citrix Cloud Secure Client CSV. Cannot be used with `ClientID` or `ClientSecret` parameters.

#### Optional Parameters

- `LockdownOpenDeliveryGroups`: Optional **`switch`**. If specified, will disable any Delivery Group that does not have an Smart Access Control defined. Will Tag the Delivery Group with a `DisabledBySecurityScript` Tag. The Tag will be created if it does not exist.
- `RemediateDisabledDeliveryGroups`: Optional **`switch`**. If specified, will re-enable any Delivery Group that is tagged with `DisabledBySecurityScript` and now has an appropriate Smart Access Control defined.
- `ClientID`: Optional **`String`**. The Citrix Cloud Secure Client ID. Cannot be used with the `SecureClientFile` Parameter. Must be combined with the `ClientSecret` parameter.
- `ClientSecret`: Optional **`String`**. The Citrix Cloud Secure Client Secret. Cannot be used with the `SecureClientFile` Parameter. Must be used with the `ClientID` parameter.
- `LogPath`: Optional **`String`**. Log path output for all operations. The default is `C:\Logs\UpdateDaaSHostedMachineId.log`
- `LogRollover`: Optional **`Int`**.Number of days before log files are rolled over. Default is 5.
- `Whatif`: Optional. **`Switch`**. Will action the script in a whatif processing mode only.

## Examples

### Manage both the disable and enabling of Delivery Groups based on appropriate Smart Access Controls

Param Splatting:

```
$Params = @{
    Region                          = "US"
    CustomerID                      = "fakecustID"
    SecureClientFile                = "C:\SecureFolder\secureclient.csv"
    LockdownOpenDeliveryGroups      = $true
    RemediateDisabledDeliveryGroups = $true
    Whatif                          = $true
}

& .\ValidateDaaSEnumerationLockdown.ps1 @params
```

The direct script invocation via the command line with defined arguments would be:

```
.\ValidateDaaSEnumerationLockdown.ps1 -Region US -SecureClientFile "C:\SecureFolder\secureclient.csv" -CustomerID "fakecustID" -LockdownOpenDeliveryGroups -RemediateDisabledDeliveryGroups -Whatif
```

The script will:

- Use the Citrix Cloud DaaS `US` region.
- Use the provided Customer ID `fakecustID` and Secure Client File in `c:\SecureFolder\secureclient.csv`.
- Look for appropriate LOCATION_TAG_* Controls on each Delivery Group Access Policies. If not suitable, the Delivery Group will be disabled and Tagged with `DisabledBySecurityScript`
- Look for any Delivery Groups tagged previously with `DisabledBySecurityScript` and if appropriate Smart Access Filters are now enabled, enable the Delivery Group.
- Process in a `whatif` mode with no changes made. Remove this switch to process the changes.

### Report on Status of the DaaS Delivery Groups Only

Param Splatting:

```
$Params = @{
    Region                          = "US"
    CustomerID                      = "fakecustID"
    SecureClientFile                = "C:\SecureFolder\secureclient.csv"
}

& .\ValidateDaaSEnumerationLockdown.ps1 @params
```

The direct script invocation via the command line with defined arguments would be:

```
.\ValidateDaaSEnumerationLockdown.ps1 -Region US -SecureClientFile "C:\SecureFolder\secureclient.csv" -CustomerID "fakecustID"
```

The script will:

- Use the Citrix Cloud DaaS `US` region.
- Use the provided Customer ID `fakecustID` and Secure Client File in `c:\SecureFolder\secureclient.csv`.
- Look for appropriate LOCATION_TAG_* Controls on each Delivery Group Access Policies.
- Report and log Findings only.

### Report on Status of the DaaS Delivery Groups Only - Specify Credentials

Param Splatting:

```
$Params = @{
    Region                          = "US"
    CustomerID                      = "fakecustID"
    ClientID                        = "fakeclientID"
    ClientSecret                    = "fakeSecret"
}

& .\ValidateDaaSEnumerationLockdown.ps1 @params
```

The direct script invocation via the command line with defined arguments would be:

```
.\ValidateDaaSEnumerationLockdown.ps1 -Region US -CustomerID "fakecustID" -ClientID "fakeclientID" -ClientSecret "fakeSecret"
```

The script will:

- Use the Citrix Cloud DaaS `US` region.
- Use the provided Customer ID `fakecustID` and `fakeclientID` and `fakeSecret`
- Look for appropriate LOCATION_TAG_* Controls on each Delivery Group Access Policies.
- Report and log Findings only.

