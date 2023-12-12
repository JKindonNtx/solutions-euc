# G9 Reference Architecture Test Matrix

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
| ⚠️ | Need to ensure that the comparison between G8 and G9 is fair therefore comparing NX-3170 G8 vs NX-3155 G9 |
| ⚠️ | Desktop numbers on Windows 11 vs Windows 10 will drop due to the extended overhead on the cluster |
| ⚠️ | 2 Documents will be removed as part of this testing (RA-2153 and RA2111) and the new documents will be combined |
| ⚠️ | MCS and PVS workloads will be consolidated into single documents as per details below |

## Custom Telegraf Configuration

Details any custom Telegraf configuration over and above the default required before the test.

| Server | Detail |
| :---: | :--- |
| CVAD Controllers | Enable Perfmon Counters |
| SQL Server | Enable Perfmon Counters |
| StoreFront Servers | Enable Perfmon Counters |

## Test to Delete

Any tests run as part of the document that require deleting before producing the final document.

| | Test ID | Detail |
| :---: | --- | :--- |
| ❌ | Not Yet Available | Not Yet Available |

## Test Infrastructure Components

Infrastructure Components in place for the testing. Detail any additional components that are required such as scripts, file copy jobs etc that are part of the testing.

| Component | Info | Status | Detail | Owner | Tested | 
| :-- | :-- | :-- | :-- | :-- | :-- |
| Workload Cluster G8 | 10.56.68.185 | ✅ | 8-node cluster | svenhuisman | ❌ |
| Workload Cluster G9 | TBC | ❌ | 8-node cluster | svenhuisman | ❌ |
| LE Appliance | WS-LE1 | ✅ | Good to go | ntnxDave / svenhuisman / ntnxJKindon | ✅ |
| LE Launchers | LE1-202312-### | ✅ | Redeploy with new Launcher Agent and Citrix Workspace App | svenhuisman | ❌ |
| G8 Windows 10 Image | W10-22H2-2649_Snap_Optimized.template | ✅ | 12/11/2023 14:19:15 svenhuisman | svenhuisman | ❌ |
| G8 Windows 11 Image | W11-23H2-2509_Snap_Optimized.template | ✅ | 12/12/2023 : 11:12:15 | ntnxDave | ❌ |
| G8 Windows Server 2022 Image | S22-XXXX-XXXX_Snap_Optimized | ❌ | Image Description | TBC | ❌ |
| G9 Windows 10 Image | W10-XXXX-XXXX_Snap_Optimized | ❌ | Image Description | TBC | ❌ |
| G9 Windows 11 Image | W11-XXXX-XXXX_Snap_Optimized | ❌ | Image Description | TBC | ❌ |
| G9 Windows Server 2022 Image | S22-XXXX-XXXX_Snap_Optimized | ❌ | Image Description | TBC | ❌ |
| W10 Catalog | Machine Count | ❌ | Catalog Detail | TBC | ❌ |
| W11 Catalog | Machine Count | ❌ | Catalog Detail | TBC | ❌ |
| S22 Catalog | Machine Count | ❌ | Catalog Detail | TBC | ❌ |

## Group Policy Configurations

Detail any group policies that you will be using as part of the testing.

| Policy | Detail | Test Info |
| :-- | :-- | :-- |
| Default GPO Policies | Using Default GPO Settings for all tests | All Tests |
| Default Citrix Policies | Using Default Citrix Settings for all tests | All Tests |

## Test Names

Detail the tests you are planning to run as part of the document.
| Document Reference | Test Name | Run Count | Completed | By | Info | Test ID |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| RA-2053-BL-G8 | G8 Windows 10 Baseline | 5 | ❌ | TBC | Baseline Windows 10 on G8 | TBC - Fill out once test started. |
| RA-2053-BL | G9 Windows 10 Baseline | 5 | ❌ | TBC | Baseline Windows 10 on G9 | TBC - Fill out once test started. |
| RA-2053-BL-G8 | G8 Windows 11 Baseline | 5 | ❌ | TBC | Baseline Windows 11 on G8 | TBC - Fill out once test started. |
| RA-2053-BL | G9 Windows 11 Baseline | 5 | ❌ | TBC | Baseline Windows 11 on G9 | TBC - Fill out once test started. |
| RA-2150-BL-8 | G8 Windows Srv 2022 Baseline | 5 | ❌ | TBC | Baseline Windows Server 2022 on G8 | TBC - Fill out once test started. |
| RA-2150-BL | G9 Windows Srv 2022 Baseline | 5 | ❌ | TBC | Baseline Windows Server 2022 on G9 | TBC - Fill out once test started. |
| RA-2053 | 1n_w10_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 1 Nodes - Windows 10 - MCS - AHV | TBC - Fill out once test started. |
| RA-2053 | 2n_w10_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 2 Nodes - Windows 10 - MCS - AHV | TBC - Fill out once test started. |
| RA-2053 | 4n_w10_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 4 Nodes - Windows 10 - MCS - AHV | TBC - Fill out once test started. |
| RA-2053 | 6n_w10_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 6 Nodes - Windows 10 - MCS - AHV | TBC - Fill out once test started. |
| RA-2053 | 8n_w10_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 8 Nodes - Windows 10 - MCS - AHV | TBC - Fill out once test started. |
| RA-2053 | 8n_w10_uXXX_vXXX_pvs_ahv | 3 | ❌ | TBC | 8 Nodes - Windows 10 - PVS - AHV | TBC - Fill out once test started. |
| RA-2053 | 8n_w11_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 8 Nodes - Windows 11 - MCS - AHV | TBC - Fill out once test started. |
| RA-2150 | 1n_s22_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 1 Nodes - Server 2022 - MCS - AHV | TBC - Fill out once test started. |
| RA-2150 | 2n_s22_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 2 Nodes - Server 2022 - MCS - AHV | TBC - Fill out once test started. |
| RA-2150 | 4n_s22_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 4 Nodes - Server 2022 - MCS - AHV | TBC - Fill out once test started. |
| RA-2150 | 6n_s22_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 6 Nodes - Server 2022 - MCS - AHV | TBC - Fill out once test started. |
| RA-2150 | 8n_s22_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 8 Nodes - Server 2022 - MCS - AHV | TBC - Fill out once test started. |
| RA-2150 | 8n_s22_uXXX_vXXX_pvs_ahv | 3 | ❌ | TBC | 8 Nodes - Server 2022 - PVS - AHV | TBC - Fill out once test started. |

## Test Comparisons

Any specific test comparisons made and a report link to the Grafana dashboard with those tests selected.

| Operating System | Detail | Report URL | Test Comparison | Completed |
| :-- | :-- | :-- | :-- | :-- |
| TBC | TBC | [Report](http://10.57.64.101:3000) | TBC  | ✅ |
| | | | |

