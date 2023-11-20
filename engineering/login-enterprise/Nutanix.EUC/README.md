# Executing a Test

The following components are required for executing a new test:

-  `Test-Script.ps1` is responsible for executing the validation and testing phases.
-  `ConfigFile.json` contains general information about the test, including what sort of test is being run. This file is unique to each test.
-  `LEConfigFile.json` contains information about the Login Enterprise Appliances and configuration. It is a global json file required for all tests. the `Test-Script.ps1` script will import this configuration file, and based on the specified Appliance Switch `LEAppliance` will consume and set the appropriate Login Enterprise details.


## Test-Script.Ps1 Parameters

-  `ConfigFile`. Mandatory **`String`**. Defines the path to the test configuration file.
-  `LEConfigFile`. Mandatory **`String`**. Defines the path for the Global Login Enterprise Configuration File
-  `ReportConfigFile`. Mandatory **`String`**.
-  `Type`. Mandatory **`String`**. Defines the type of test. `"CitrixVAD", "CitrixDaaS", "Horizon", "RAS"`
-  `SkipADUsers`. Optional. **`Switch`**. Retains the existing AD User Accounts and does not recreate the accounts.
-  `SkipLEUsers`. Optional. **`Switch`**. Retains the existing Login Enterprise Accounts and does not recreate the accounts.
-  `SkipWaitForIdleVMs`. Optional. **`Switch`**.
-  `SkipPDFExport`. Optional. **`Switch`**.
-  `Force`