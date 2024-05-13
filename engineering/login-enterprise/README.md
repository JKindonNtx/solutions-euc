# About the Nutanix.EUC Module

The `Nutanix.EUC` Module is a collection of PowerShell functions written to allow a modular approach to action the following tasks:

-  Configuring and managing `Active Directory` accounts.
-  Configuring and managing `Login Enterprise` Appliance and test configurations.
-  Configuring and monitoring `Nutanix AOS` Metrics.
-  Configuring and monitoring `Nutanix Files` deployments.
-  Configuring and managing `Citrix Virtual Apps and Desktops` and `Citrix DaaS` deployments (for performance testing).
-  Configuring and managing `VMware Horizon` deployments (for performance testing).
-  Configuring and monitoring of Windows Infrastructure via `Telegraf`.
-  Managing data manipulation for ingestion into `InfluxDB`.
-  Download of images from `Grafana` dashboards created from `InfluxDB` data.
-  Integration with `Slack` for status reporting.
-  Integration with `Grafana` for real time test monitoring and status, along with real time metric `reporting`.

These modules allow us to write PowerShell scripts to execute performance tests on a range of different configurations and requirements. The modular approach allows to add technologies and capabilities in a reusable fashion.

## Configuration vs Execution

We use the following logic to write, manage and enhance our modules and scripts:

-  A `function` should be reusable across multiple different use cases.
-  A `script` should coordinate the use of `functions`.
-  A `script` should pull configuration or control options from a `JSONC` based control file. Some parameters are required to control the import of `JSONC` control files.
-  Github repositories should not contain secrets, passwords, usernames or anything sensitive. We only store example configuration files with placeholder values in github. Other `JSONC` files not named as `Example-*` are excluded from Sync within our repository. This allows you to store your personalized test configuration files locally to your machine.

## Fail Fast. Always

We on principal do our best to **fail fast**. As we add functions, scripts and additional capability, we think upfront about how things can fail. We try and cater for this at the start, even if it means adding additional functions.

As an example, a `Nutanix Files` monitoring job requires a `Files IP`, and an `API User`. The `Files` monitoring portion of the script does not start until the environment has been refreshed, workloads deployed, launcher vms confirmed, and idle wait times completed. This could be an hour worth of wait time before actually starting a test, and thus starting metric collection from Files. We want to know that Files is going to start being monitored successfully or not upfront, so we have a specific `Invoke-NutanixFilesAuthCheck` function which checks everything is OK as part of the validation phase. If it's not going work, then we exit early. And don't waste time.

This type of logic is critical to efficiency. As we learn more, we should and will add more upfront validation.

## Continuous Improvement

The Module and associated scripts can be improved as we test more scenarios. If there are gaps, or opportunities to improve, consider using [Github Issues](https://github.com/nutanix-enterprise/solutions-euc/issues) to identify what went wrong, or what could be better.

We have a central update file that can be [referenced for major changes and additions](https://github.com/nutanix-enterprise/solutions-euc/tree/main/engineering/login-enterprise/Invoke-Test-ChangeLog.md).

## Invoke-Test.ps1

`Invoke-Test.ps1` is an example of a `script` built to consume the `Nutanix.EUC` module. The purpose of this script is to validate, orchestrate, and manage and end to end performance test across a range of different scenarios.

To execute a test, there are four key pieces of information required by the script. These are input as Mandatory parameters:

-  `ConfigFile.jsonc` contains general information about the test, including what sort of test is being run. This file is unique to each test. This file contains what you are testing (Citrix, Horizon, Parallels etc) along with where the tests are being run, and what specific components are needed. This file contains sensitive information, so will exists on your local machine only. An example exists in the root repository as `ExampleConfig-Test-Template.jsonc`. The example contains all configuration options for all tests with placeholder values. You should copy this file and input relevant information for your test requirements.
-  `LEConfigFile.jsonc` contains information about the Login Enterprise Appliances and configuration. It is a global json file required for all tests. the `Invoke-Test.ps1` script will import this configuration file, and based on the specified Appliance in either `ConfigFile.jsonc` or the Script parameter `LEAppliance`, will consume and set the appropriate Login Enterprise details. This file contains sensitive information, so will exists on your local machine only. An example exists in the root repository as `ExampleConfig-LoginEnterpriseGlobal.jsonc`
-  `Type` defines the sort of test we are running. This could be `CitrixVAD`, `CitrixDaaS`, `Horizon`, `Parallels`. The script logic executes based on the provided value.

### Invoke-Test.Ps1 Mandatory Parameters

-  `ConfigFile`. Mandatory **`String`**. Defines the path to the test configuration file.
-  `LEConfigFile`. Mandatory **`String`**. Defines the path for the Global Login Enterprise Configuration File.
-  `ReportConfigFile`. Mandatory **`String`**. Defines the default report configuration file.
-  `Type`. Mandatory **`String`**. Defines the type of test. `"CitrixVAD", "CitrixDaaS", "Horizon", "RAS", "RDP"`

### Invoke-Test.ps1 Optional Parameters

The below parameters should be set in the `ConfigFile` as a preferential configuration point, however can be set via script Parameter which will **Override** whatever is set in the `ConfigFile`.

-  `SkipADUsers`. Optional. **`Switch`**. Retains the existing AD User Accounts and does not recreate the accounts.
-  `SkipLEUsers`. Optional. **`Switch`**. Retains the existing Login Enterprise Accounts and does not recreate the accounts.
-  `SkipLaunchers`. Optional. **`Switch`**. TBD. Can be set in `LEConfigFile.jsonc`.
-  `SkipWaitForIdleVMs`. Optional. **`Switch`**. Do not wait for test VMs to become Idle. Can be set in `LEConfigFile.jsonc`.
-  `SkipPDFExport`. Optional. **`Switch`**. TBD. Can be set in `LEConfigFile.jsonc`.
-  `Force`. Optional. **`Switch`**. Forces a recreation of the desktop pool. Can be set in `LEConfigFile.jsonc`.
-  `LEAppliance`. Optional. **`String`**. The Login Enterprise Appliance to use. `LE1`,`LE2`,`LE3`,`LE4`. Can be set in `LEConfigFile.jsonc`.
-  `ValidateOnly`. Optional. **`Switch`**. Will process only the inputs and pre-execution tasks. Will not process any testing. Use for making sure things look good.
-   `AzureMode`. Optional. **`Switch`**. Will function with an understanding that the script is in Azure and not Nutanix. Nutanix components are excluded. Different data is gathered for influx.

### Step 1: Getting Started: Planning

You will need some advanced planning for test execution. Some things to consider below:

-  Who else is running tests, and which Login Enterprise appliance can you use? Our testing dashboard can show you some current statuses and planned tests.
-  What are you going to test and where. Which cluster(s) do you need?
-  Do you need Nutanix Files? If so, is a dedicated cluster required? How many?
-  Do you need to alter any image builds from the standard? We use Ansible to build our images, is there anything custom that needs to be added to the playbooks?
-  Do you need to monitor any infrastructure components or just Nutanix Core Services (Cluster, Files, Cluster Hosting Files etc)?
-  Have you created a test map runbook? You can use [this template](https://github.com/nutanix-enterprise/solutions-euc/blob/main/documentation/_documentation_template/Test%20Report%20Map.md) to help you plan your way through tests and outcomes.

### Step 2: Getting Started with the Script

To get started with the script structure, you need to action the following:

1. Copy the `ExampleConfig-Test-Template.jsonc` and rename it to something appropriate. For example: `LoginEnterpriseGlobalConfig.jsonc`. Alter the file with the appropriate values, including URLS, Tokens etc. This file is now unique to you, and can be used across all tests using Login Enterprise. This will be used by the `LEConfigFile.jsonc` parameter.
2. Copy the `ExampleConfig-Test-Template.jsonc` and rename it something appropriate. For example: `LE-Citrix-FSLogix.jsonc`. Alter the file with the appropriate values and remove what is not required. For example, remove the Horizon components from a Citrix VAD test You will need to add usernames, passwords, cluster details, slack information etc. This file is now unique to your test. You can have as many as required. This will be used by the `ConfigFile.jsonc` parameter.

### Infrastructure Monitoring with Telegraf

To extend monitoring to non-specific infrastructure services, we use `telegraf`, `InfluxDB` and `Grafana`. It is important to note the following:

-  For `telegraf` based monitoring to work, you must both install `telegraf`, and deploy and appropriate `configuration file` with the `metrics` you are interested in on the server you want to monitor. For example, in a Citrix Session Recording test, we may want to capture, monitor and report on **Microsoft Perfmon Counters** and **Event Log Entries**. To do this, we need a telegraf configuration file on ***each*** Session Recording Server with the appropriate metrics defined. We also need the Telegraf Service installed with the **default** service name (`telegraf`).
-  For each non-standard server you want to monitor, you will can either start the service manually, or allow the script to do so by defining the appropriate values in the `ConfigFile.jsonc` configuration file. This will both start and stop the service on the defined machines as part of the test run.
-  Given that this data is custom, there are no pre-defined grafana reports. You will need to identify what you would like to see, and how you would like the data presented. We capture the data into `InfluxDB` in a specific bucket.

### Azure VM Monitoring

If testing Azure VMs, we have some changes to data capturing and reporting. There are multiple touchpoints for controlling Azure Data capturing listed below:

1. The `test.json` file must be updated to include `AzureGuestDetails` components including `IsAzureVM` which is boolean value.
2. The image tattoo job must have been run inside the Azure Image. This will poll the IMDS service along with additional in-guest tasks to write the appropriate values to the registry.

The following logic applies to Azure VM Metric gathering and reporting:

1. The `test.json` file is set to enable Azure VM Guest mode (Boolean).
2. The `cust-image-tattoo.ps1` script captures and sets Azure specific guest details in-guest.
3. The `Invoke-Test.ps1` retrieves the registry details for the VM. It then updates that `$NTNXInfra` with the appropriate values and exports to `testconfig.json`.
4. The `Start-InfluxUpload.ps1` function imports the `testconfig.json`. It checks to see if the `$IsAzureVM` is `true` (via a parameter). If so, a new set of Tags are written to map existing Tags to the new values imported from the `testconfig.json`. If not, the existing Tag logic is used.

To add metrics, the following touch points apply:

1.  Build the logic into the tattoo script to create the reg value: for example, `Azure_VM_Bios_Name`
2.  Define the Item Name in the `config.json` file under the `AzureGuestDetails` Block. For example, `"VM_Bios_Name": "", //Filled via Image Tattoo job`. This is JSON format, so be careful.
3.  Add the value into the `Invoke-Test.ps1` script. For example, `$NTNX.Infra.AzureGuestDetails.VM_Bios_Name = $Tattoo.Azure_VM_Bios_Name`
4.  Add the tag into the `Start-InfluxUpload.ps1` Function Eg: `"InfraBIOS=$($JSON.AzureGuestDetails.VM_Bios_Name)," +`

Azure specific testing data is sent to a different Influx Bucket and new Grafana reports are created accordingly.

### Useful URLS

-  The `Invoke-Script.ps1` script will update an [operational dashboard](http://10.57.64.101:3000/d/EN4BGISSk/testing-status?orgId=1&refresh=10s&from=now-24h&to=now). You can view current tests progress and status, along with some basic infrastructure metrics at this dashboard.
-  The default [document reporting dashboard](http://10.57.64.101:3000/d/N5tnL9EVk/login-documents-v3) is available with data as soon as the test has finished.
-  You can generate automated documentation from a specific grafana report using the [New-GrafanaReport.ps1 script](https://github.com/nutanix-enterprise/solutions-euc/blob/main/collateral/scripts/Misc/Grafana/New-GrafanaReport.ps1). You can convert the output of the `New-GrafanaReport.ps1` file to a Nutanix Markdown standard using the [FixMDOutput.ps1 script](https://github.com/nutanix-enterprise/solutions-euc/blob/main/collateral/scripts/Misc/Grafana/FixMDOutput.ps1). Read the [readme](https://github.com/nutanix-enterprise/solutions-euc/blob/main/collateral/scripts/Misc/Grafana/README.MD) for instructions.

# Invoke-TestUpload.ps1

# Remove-Test.ps1

The script removes test data from an InfluxDB. There are 4 main components required to drive the script.

The `Remove-Test.ps1` requires a `ConfigFile.jsonc` file. This file contains the authentication detail for InfluxDB. You will also need to know the test `ID` (for example `a4df64_8n_A6.5.2.7_AHV_1000V_1000U_KW`), the `run` number if you only want to delete a single run, and the Influx Bucket, `Documents`, `Regression`, `Test` etc.

### Remove-Test.Ps1 Mandatory Parameters

-  `ConfigFile`. Mandatory **`String`**. Defines the path to the removal configuration file.
-  `Bucket`. Mandatory **`String`**. Defines the Influx bucket hosting the data.
-  `Test`. Mandatory **`String`**. Defines the test ID you wish to delete.

### Remove-Test.Ps1 Optional Parameters

-  `Run`. Optional **`String`**. Defines the run ID to delete if you only want to delete a single run. If not set, all runs will be deleted associated with the defined `Test`.

### Example. Delete all runs of a problematic Test with ID a4df64_8n_A6.5.2.7_AHV_1000V_1000U_KW

`.\Remove-Test.ps1 -ConfigFile .\Test-Removal.jsonc -Bucket LoginDocuments -Test a4df64_8n_A6.5.2.7_AHV_1000V_1000U_KW`

## Archiving Test Data

Test results are stored on the local machine executing the tests. Over time, this data can become tedious to navigate. Additionally, sometimes tests fail, resulting in orphaned data structures.

Two scripts exist to manage this data. Both can be configured as a scheduled tasks on the appropriate jump host.

### DeleteOrphanedTests.ps1

This script will remove orphaned test data. Its criteria for maching is as follows:

-  Traul the source folder specified by the `TestDirectory` parameter for any folder containing a sub folder specified by the `BootFolder` parameter (defaults to boot) with no other files present in the root folder
-  Matches based on the `DaysOlderThan` parameter (defaults to 30)

Any data meeting this criteria set will be deleted.

#### Schedule task creation

You can use the following snippet to create a scheduled task which will be actioned under the system context. Adjust your inputs accordingly

```
$ScriptPath = "C:\DevOps\solutions-euc\engineering\login-enterprise\DeleteOrphanedTests.ps1"
$TestResultsPath = "C:\devops\solutions-euc\engineering\login-enterprise\results"
$Trigger = New-ScheduledTaskTrigger -Daily -At 9:00pm
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -File `"$scriptPath`" -TestDirectory `"$TestResultsPath`" -DaysOlderThan `"30`" "
Register-ScheduledTask -TaskName "Delete Orphaned Tests" -Trigger $Trigger -Action $action -Description "Deletes Oprhaned Test Results" -User "System" -RunLevel Highest
```

### ArchiveTestData.ps1

This script will archive test data to a central share so that it can be retrieved at a later date as required. Its criteria for maching is as follows:

-  Traul the source folders specified by the `TestSourceDirectory` and `TestResultsSourceDirectory` parameters
-  Matches based on the `DaysOlderThan` parameter (defaults to 30)
-  Moves the data to the central location as specified by the `TestTargetDirectory` (defaults to `\\WS-Files\Automation\Test-Archive\results`) and `TestResultsTargetDirectory` (defaults to `\\WS-Files\Automation\Test-Archive\testresults`) parameters. 

#### Schedule task creation

You can use the following snippet to create a scheduled task which will be actioned under the system context. Adjust your inputs accordingly

```
$ScriptPath = "C:\DevOps\solutions-euc\engineering\login-enterprise\ArchiveTestData.ps1"
$TestSourceDirectory = "C:\devops\solutions-euc\engineering\login-enterprise\results"
$TestResultsSourceDirectory = "C:\devops\solutions-euc\engineering\login-enterprise\testresults"
$Trigger = New-ScheduledTaskTrigger -Daily -At 9:00pm
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -File `"$scriptPath`" -TestSourceDirectory `"$TestSourceDirectory`" -TestResultsSourceDirectory `"$TestResultsSourceDirectory`" -DaysOlderThan `"30`" "
Register-ScheduledTask -TaskName "Archive Tests" -Trigger $Trigger -Action $action -Description "Archive Test Results" -User "System" -RunLevel Highest
```