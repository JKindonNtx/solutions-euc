# Document Name Test Matrix

## Test Naming Convention

The following naming convention will be used (if possible) when running the tests, comments should be added to display real world test information in the document as these will get exported as part of the graphs.

``<random_6_digit_guid>_<nodes>n_<hv_version>_<hv_type>_<number_of_vms>V_<number_of_users>U_<workload_type>``

for example ``c10289_1n_A6.5.4_AHV_120V_120U_KW``

## Icon Set

| Running | Completed | Not Started | Problem |
| :---: | :---: | :---: | :---: |
| 🏃🏻‍♂️ | ✅ | ❌ | ⚠️ |

## Warnings / Details

Details any warnings or considerations that need to be reviewed as part of the testing schedule for this document.

| Warning | Detail |
| :---: | :--- |
| ⚠️ | `TBD` |

## Custom Telegraf Configuration

Details any custom Telegraf configuration over and above the default required before the test.

| Server | Detail | Status |
| :---: | :--- | :---: |
| WS-PVS1 | Enable Perfmon Counters | ✅ |
| WS-PVS2 | Enable Perfmon Counters | ✅ |
| WS-PVS3 | Enable Perfmon Counters | ✅ |
| WS-PVS4 | Enable Perfmon Counters | ✅ |

## Test to Delete

Any tests run as part of the document that require deleting before producing the final document.

| | Test ID | Detail |
| :---: | --- | :--- |
| ❌ | `TBD` |`TBD` |

## Test Infrastructure Components

Infrastructure Components in place for the testing. Detail any additional components that are required such as scripts, file copy jobs etc that are part of the testing.

| Component | Info | Status | Detail | Owner | Tested | 
| :-- | :-- | :-- | :-- | :-- | :-- |
| Workload Cluster | 10.56.68.135 | ✅ | 6-node cluster | `TBD` | ❌ |
| LE Appliance | WS-LE1 | ✅ | Good to go | `TBD` | ✅ |
| Image | W11-XXXX-XXXX_Snap_Optimized | ❌ | Windows 11 23H2 | Username | ❌ |
| Image | W10-XXXX-XXXX_Snap_Optimized | ❌ | Windows 10 22H2 | Username | ❌ |

## Group Policy Configurations

Detail any group policies that you will be using as part of the testing.

| Policy | Detail | Test Info |
| :-- | :-- | :-- |
| GPO Name - General Settings | General behaviors | All Tests |
| GPO Name - Specific Settings | Specific behavior details | All Specific Tests |

## Test Details

Testing due to finding extremely high CPU on new LTSR 2402 Servers with Windows 11 23H2. Around 45 minute boot times with manual intervention required. Unable to get all VMs registered.

Booted 900 VMs. Each VM was pinned to a host in blocks of 150. Used Lenovo AMD clusters and standard management cluster.

Boot times are reduced to 20 minutes with LSA disabled and Defender Cache Scheduled tasks disabled. Unsure which had the bigger impacts.

Defender: ```Get-ScheduledTask -TaskPath '\Microsoft\Windows\Windows Defender\' | Disable-ScheduledTask```
LSA: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa   Value: RunAsPPL = dword:00000000

Both are configured in the `workstation_loginent-def-ctx-2402-pvs-co-O21.yml` playbook

We need to monitor and measure CPU, along with relevant PVS counters on the PVS servers during the tests. Use telegraf. (✅)

We should also use telegraf to monitor PVS Event logs or VM boot times and compare against CPU load. Each Target boot time is tracked in the PVS log. (✅)

We may want a separate dashboard for this testing.

### LTSR 2203

Test count: 2

Baseline configuration causing issues in 2402, attempting to replicate challenges found in 2203

| Setting | Configuration | Detail |
| :-- | :-- | :-- |
| PVS Server: Count | 2 | Even Streaming |
| PVS Server: Spec | 4 vCPU, 12 GiB RAM | Current PVS Server Configuration |
| Windows 10: Version | 22H2 | Current windows 10 Version |
| Windows 11: Version | 23H2 | Current Windows 11 Version |
| Target Device: BIOS or UEFI | UEFI | Standard Build Defaults |
| Target Device: Secure Boot | Enabled | Standard Build Defaults |
| Target Device: Version | 2203 | Old LTSR |
| Target Device: Defender cache Scheduled Tasks | Enabled | Out of Box Setting |
| Target Device: LSA | Enabled | Windows 11 23H2 Out Of Box Setting |
| Target Device: Boot | ISO | Standard Boot Config |
| vDisk: Storage | Local | Current Common Deployment |
| vDisk: Cache Size | 0 | Current Nutanix Best Practice |
| vDisk: Async IO | Disabled | Not tested in happy load state |

Test Details:

| Test Details | Run Count | Completed | By | Comment | Test ID | Logic |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| Windows 10 | 1 | ❌ | `TBD` | w10_amd_pvs_6n_A6.5.5_AHV_900V_900U_KW_2203_Base | `TBD` | Untested on 2402 currently|
| Windows 11 | 1 | ❌ | `TBD` | w11_amd_pvs_6n_A6.5.5_AHV_900V_900U_KW_2203_Base | `TBD` | This broke on 2402 |

Logic:

-  IF Windows 11 shows issues, we know this is not a PVS version issue, rather a Windows 11 Build issue.
-  IF Windows 11 does _not_ show issues, we have a PVS version issue.

### LTSR 2402 Testing

Test count: 4

Baseline configuration causing issues:

| Setting | Configuration | Detail |
| :-- | :-- | :-- |
| PVS Server: Count | 2 | Even Streaming |
| PVS Server: Spec | 8 vCPU, 16 GiB RAM | Current PVS Server Configuration showing vCPU issues |
| Windows 10: Version | 22H2 | Current windows 10 Version |
| Windows 11: Version | 23H2 | Current Windows 11 Version |
| Target Device: BIOS or UEFI | UEFI | Standard Build Defaults |
| Target Device: Secure Boot | Enabled | Standard Build Defaults |
| Target Device: Version | 2402 | Current LTSR |
| Target Device: Defender cache Scheduled Tasks | Enabled | Out of Box Setting |
| Target Device: LSA | Enabled | Windows 11 23H2 Out Of Box Setting |
| Target Device: Boot | ISO | Standard Boot Config |
| vDisk: Storage | Local | Current Common Deployment |
| vDisk: Cache Size | 0 | Current Nutanix Best Practice |
| vDisk: Async IO | Disabled | Not tested in happy load state |

Test Details:

| Test Details | Run Count | Completed | By | Comment | Test ID | Logic |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| Windows 10 | 1 | ❌ | `TBD` | w10_amd_pvs_6n_A6.5.5_AHV_900V_900U_KW_2402_Base | `TBD` | Should be OK |
| Windows 11 | 1 | ❌ | `TBD` | w11_amd_pvs_6n_A6.5.5_AHV_900V_900U_KW_2402_Base | `TBD` | Should be no good - broken CPU on PVS Servers |
| - | - | - | - | - | - | - |
| Windows 11 - Defender Cache Tasks `DISABLED` | 1 | ❌ | `TBD` | w11_amd_pvs_6n_A6.5.5_AHV_900V_900U_KW_2402_defcache_disabed | `TBD` | Unknown Impact |
| Windows 11 - Defender Cache Tasks `DISABLED` + LSA `DISABLED` | 1 | ❌ | `TBD` | w11_amd_pvs_6n_A6.5.5_AHV_900V_900U_KW_2402_newbase | `TBD` | Expected to reduce CPU issues |

Logic:

- IF Windows 10 has issues, we have a PVS version Issue
- We now have a new baseline configuration to compare future `feature` testing against below

### LTSR 2402 Testing: Feature changes

Test Count: 3

Baseline configuration post above testing:

| Setting | Configuration | Detail |
| :-- | :-- | :-- |
| PVS Server: Count | 2 | Even Streaming |
| PVS Server: Spec | 8 vCPU, 16 GiB RAM | Current PVS Server Configuration showing vCPU issues |
| Windows 10: Version | 22H2 | Current windows 10 Version |
| Windows 11: Version | 23H2 | Current Windows 11 Version |
| Target Device: BIOS or UEFI | UEFI | Standard Build Defaults |
| Target Device: Secure Boot | Enabled | Standard Build Defaults |
| Target Device Version | 2402 | Current LTSR |
| Target Device Defender cache Scheduled Tasks | Disabled | Ansible Delivered on Image build |
| Target Device LSA | Disabled | Windows 11 23H2 Configuration Change by us - Ansible Delivered or Policy Delivered |
| Target Device: Boot | ISO | Standard Boot Config |
| vDisk: Storage | Local | Current Common Deployment |
| vDisk: Cache Size | 0 | Current Nutanix Best Practice |
| vDisk: Async IO | Disabled | Not tested in happy load state |

Now we can test a known state with interesting changes of note. Test Details:

| Test Details | Run Count | Completed | By | Comment | Test ID | Logic |
| - | - | - | - | - | - | - |
| Windows 11 - 1 GiB Write cache | 1 | ❌ | `TBD` | w11_amd_pvs_6n_A6.5.5_AHV_900V_900U_KW_2402_wc_1gb | `TBD` |
| Windows 11 - Async IO Enabled | 1 | ❌ | `TBD` | w11_amd_pvs_6n_A6.5.5_AHV_900V_900U_KW_2402_asyncio_enabled | `TBD` |
| Windows 11 - Files Storage | 1 | ❌ | `TBD` | w11_amd_pvs_6n_A6.5.5_AHV_900V_900U_KW_2402_ntxfiles | `TBD` |

Logic: 

- Do we need to test Async IO with Write cache set to `0` vs write cache set to `1 GIB`?

## Test Comparisons

Any specific test comparisons made and a report link to the Grafana dashboard with those tests selected.

| Operating System | Detail | Report URL | Test Comparison | Completed |
| :-- | :-- | :-- | :-- | :-- |
| Windows 10 | 2203 vs 2402 PVS | [Report]() | Any negative difference  | ❌ |
| | | | |
| Windows 11 | 2203 vs 2402 PVS | [Report]() | Any improvement in old LTSR | ❌ |
| | | | |
| Windows 11 | 2402 Defender Cache Tasks Enabled vs Defender Cache Tasks Disabled | [Report]() | Any Improvement/change. Leave off moving forward | ❌ |
| | | | |
| Windows 11 | 2402 LSE Enabled vs LSA Disabled | [Report]() | Expecting this to be the big one. New baseline configuration will have this off moving forward. | ❌ |
| | | | |
| Windows 11 | 0 Cache vs 1 GiB Cache | [Report]() | Any negatives on Nutanix? Compare against w11_amd_pvs_6n_A6.5.5_AHV_900V_900U_KW_2402_newbase | ❌ |
| | | | |
| Windows 11 | Async IO Enabled vs Async IO Disabled | [Report]() | Any negatives on Nutanix? Compare against w11_amd_pvs_6n_A6.5.5_AHV_900V_900U_KW_2402_newbase | ❌ |
| | | | |
| Windows 11 | vDisk Local to PVS vs vDisk on Nutanix Files | [Report]() | Any negatives on Nutanix? Compare against w11_amd_pvs_6n_A6.5.5_AHV_900V_900U_KW_2402_newbase | ❌ |
| | | | |
