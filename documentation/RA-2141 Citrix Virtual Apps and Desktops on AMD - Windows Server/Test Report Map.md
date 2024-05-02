# Citrix VAD AMD Desktops Test Matrix

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
| ⚠️ | `TBD`|

## Custom Telegraf Configuration

Details any custom Telegraf configuration over and above the default required before the test.

| Server | Detail |
| :---: | :--- |
| `TBD` | Enable Perfmon Counters |

## Test to Delete

Any tests run as part of the document that require deleting before producing the final document.

| | Test ID | Detail |
| :---: | --- | :--- |
| ❌ | `TBD` | Delete |
| ❌ | 1e27b0_6n_A6.5.5.1_AHV_60V_1080U_KW | Delete - had MCS machines still running |

## Test Infrastructure Components

Infrastructure Components in place for the testing. Detail any additional components that are required such as scripts, file copy jobs etc that are part of the testing.

| Component | Info | Status | Detail | Owner | Tested | 
| :-- | :-- | :-- | :-- | :-- | :-- |
| Workload Cluster | 10.56.68.135 | ✅ | 6-node cluster | jameskindon | ✅ |
| LE Appliance | WS-LE1 | ✅ | `TBD` | jameskindon |  ✅ |
| Image | SRV-2022-ee1f_Snap_Optimized | ✅ | Windows Server 2022 Base Image | jameskindon | ✅ |

## Group Policy Configurations

Detail any group policies that you will be using as part of the testing.

| Policy | Detail | Test Info |
| :-- | :-- | :-- |
| GPO Name - General Settings | General behaviors | All Tests |
| GPO Name - Specific Settings | Specific behavior details | All Specific Tests |

## Test Names

Detail the tests you are planning to run as part of the document.

| Test Name | Run Count | Completed | By | Info | Test ID | Comment |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| Windows Server 2022 MCS 1n | 1 | ✅ | jameskindon | Windows Server 2022 MCS 1n | 93b24b_1n_A6.5.5.1_AHV_10V_180U_KW | ws2022_amd_mcs_1n_A6.5.5_AHV_10V_180U_KW_dt |
| - | - | - | - | - | - | - |
| Windows Server 2022 MCS 1n | 3 | ✅ | jameskindon | Windows Server 2022 MCS 1n | ff78e1_1n_A6.5.5.1_AHV_10V_180U_KW | ws2022_amd_mcs_1n_A6.5.5_AHV_10V_180U_KW |
| Windows Server 2022 MCS 2n | 3 | ✅ | jameskindon | Windows Server 2022 MCS 2n | 027e07_2n_A6.5.5.1_AHV_20V_360U_KW | ws2022_amd_mcs_2n_A6.5.5_AHV_20V_360U_KW |
| Windows Server 2022 MCS 4n | 3 | ✅ | jameskindon | Windows Server 2022 MCS 4n | 821e80_4n_A6.5.5.1_AHV_40V_720U_KW | ws2022_amd_mcs_4n_A6.5.5_AHV_40V_720U_KW |
| Windows Server 2022 MCS 6n | 3 | ✅ | jameskindon | Windows Server 2022 MCS 6n | 867bf4_6n_A6.5.5.1_AHV_60V_1080U_KW | ws2022_amd_mcs_6n_A6.5.5_AHV_60V_1080U_KW |
| Windows Server 2022 PVS 6n | 3 | ⚠️ | jameskindon | Windows Server 2022 PVS 6n | `TBD` | ws2022_amd_pvs_6n_A6.5.5_AHV_xV_xU_KW |

## Test Comparisons

Any specific test comparisons made and a report link to the Grafana dashboard with those tests selected.

| Operating System | Detail | Report URL | Test Comparison | Completed |
| :-- | :-- | :-- | :-- | :-- |
| Windows Server 2022 | MCS Baseline - Linear Scale | [Report](http://10.57.64.101:3000/d/N5tnL9EVk/login-documents-v3?orgId=1&var-Bucketname=LoginDocuments&var-Bootbucket=BootBucket&var-Year=2024&var-Month=04&var-Month=05&var-Month=03&var-DocumentName=RA-2020-Len-AMD&var-Run=867bf4_6n_A6.5.5.1_AHV_60V_1080U_KW_Run2&var-Run=027e07_2n_A6.5.5.1_AHV_20V_360U_KW_Run2&var-Run=821e80_4n_A6.5.5.1_AHV_40V_720U_KW_Run2&var-Run=ff78e1_1n_A6.5.5.1_AHV_10V_180U_KW_Run2&var-Naming=Comment&var-Comment=ws2022_amd_mcs_6n_A6.5.5_AHV_60V_1080U_KW&var-Comment=ws2022_amd_mcs_4n_A6.5.5_AHV_40V_720U_KW&var-Comment=ws2022_amd_mcs_2n_A6.5.5_AHV_20V_360U_KW&var-Comment=ws2022_amd_mcs_1n_A6.5.5_AHV_10V_180U_KW&var-Testname=867bf4_6n_A6.5.5.1_AHV_60V_1080U_KW&var-Testname=027e07_2n_A6.5.5.1_AHV_20V_360U_KW&var-Testname=821e80_4n_A6.5.5.1_AHV_40V_720U_KW&var-Testname=ff78e1_1n_A6.5.5.1_AHV_10V_180U_KW) | Windows Server 2022 MCS 1n vs Windows Server 2022 MCS 2n vs Windows Server 2022 MCS 4n vs Windows Server 2022 MCS 6n | ❌ |
| | | | |
| Windows Server 2022 | MCS vs PVS Baseline | [Report]() | Windows Server 2022 MCS 6n vs Windows Server 2022 PVS 6n | ❌ |
| | | | |

## Guiding Notes

- Prove Linear Scale with Windows Server 2022 for MCS.
- Compare MCS and PVS using Windows Server 2022 6 node tests.

