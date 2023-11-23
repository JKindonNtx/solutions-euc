# Executing a Test

The following components are required for executing a new test:

-  `Test-Script.ps1` is responsible for executing the validation and testing phases.
-  `ConfigFile.json` contains general information about the test, including what sort of test is being run. This file is unique to each test.
-  `LEConfigFile.json` contains information about the Login Enterprise Appliances and configuration. It is a global json file required for all tests. the `Test-Script.ps1` script will import this configuration file, and based on the specified Appliance Switch `LEAppliance` will consume and set the appropriate Login Enterprise details.


## Test-Script.Ps1 Mandatory Parameters

-  `ConfigFile`. Mandatory **`String`**. Defines the path to the test configuration file.
-  `LEConfigFile`. Mandatory **`String`**. Defines the path for the Global Login Enterprise Configuration File
-  `ReportConfigFile`. Mandatory **`String`**.
-  `Type`. Mandatory **`String`**. Defines the type of test. `"CitrixVAD", "CitrixDaaS", "Horizon", "RAS"`

## Test-Script.Ps1 Optional Parameters

The below parameters should be set in the `ConfigFile` as a preferential configuration point, however can be set via script Parameter which will **Override** whatever is set in the `ConfigFile`.

-  `SkipADUsers`. Optional. **`Switch`**. Retains the existing AD User Accounts and does not recreate the accounts.
-  `SkipLEUsers`. Optional. **`Switch`**. Retains the existing Login Enterprise Accounts and does not recreate the accounts.
-  `SkipLaunchers`. Optional. **`Switch`**.
-  `SkipWaitForIdleVMs`. Optional. **`Switch`**.
-  `SkipPDFExport`. Optional. **`Switch`**.
-  `Force`. Optional. **`Switch`**.
-  `LEAppliance`. Optional. **`String`**.
