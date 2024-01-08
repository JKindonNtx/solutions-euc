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
| G8 Windows Server 2022 Image | SRV-2022-407e_Snap_Optimized | ✅ | 12/12/2023 13:04:51 svenhuisman | svenhuisman | ❌ |
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

## Baseline Numbers

Detail the testing baseline numbers.
| OS | CPU | Cores | Memory | VMs Per Node | Users Per Node | 
| :-- | :-- | :-- | :-- | :-- | :-- | 
| Windows 10 (G8) | 1 | 2 | 4 | 120 | 120 | 
| Windows Server 2022 (G8) | 2 | 3 | 42 | 16 | 135 | 
| Windows 10 (G9) | 1 | 2 | 4 | 135 | 135 | 
| Windows 11 (G9) | ? | ? | ? | ? | ? | 
| Windows Server 2022 (G9) | 2 | 3 | 42 | ? | ? | 

## Test Names

Detail the tests you are planning to run as part of the document.
| Document Reference | Test Name | Run Count | Completed | By | Info | Test ID | Link |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| RADOC-2053-G8 | G8 Windows 10 Baseline | 2 | ✅ | Sven | Baseline Windows 10 on G8 | c508f7_1n_A6.5.4.5_AHV_120V_120U_KW | [Report](http://10.57.64.101:3000/d/N5tnL9EVk/login-documents-v3?orgId=1&var-Bucketname=LoginDocuments&var-Bootbucket=BootBucket&var-Year=2024&var-Month=01&var-DocumentName=RADOC-2053-G8&var-Comment=G8_Windows_10&var-Testname=c508f7_1n_A6.5.4.5_AHV_120V_120U_KW&var-Run=c508f7_1n_A6.5.4.5_AHV_120V_120U_KW_Run1&var-Run=c508f7_1n_A6.5.4.5_AHV_120V_120U_KW_Run2&var-Naming=Comment)| |
| RADOC-2053-G9 | G9 Windows 10 | 3 | ✅ | Sven | Baseline Windows 10 on G9 | 4af950_1n_A6.5.4.5_AHV_135V_135U_KW | |
| RADOC-2053-BG9 | G9 Windows 11 Baseline | 5 | ❌ | TBC | Baseline Windows 11 on G9 | TBC - Fill out once test started. | |
| RADOC-2150-G8 | G8 Windows Srv 2022 Baseline | 5 | ✅ | Sven | Baseline Windows Server 2022 on G8 | 3afd79_1n_A6.5.4.5_AHV_16V_135U_KW | |
| RADOC-2150-G9 | G9 Windows Srv 2022 Baseline | 5 | ❌ | TBC | Baseline Windows Server 2022 on G9 | TBC - Fill out once test started. | |
| RA-2150 | 8n_s22_uXXX_vXXX_mcs_ahv_g8 | 3 | ❌ | TBC | 8 Nodes - Server 2022 - MCS - AHV - G8 | TBC - Fill out once test started. | |
| RA-2053 | 8n_w10_uXXX_vXXX_mcs_ahv_g8 | 3 | ❌ | TBC | 8 Nodes - Windows 10 - MCS - AHV - G8 | TBC - Fill out once test started. | |
| RA-2053 | 1n_w10_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 1 Nodes - Windows 10 - MCS - AHV | TBC - Fill out once test started. | |
| RA-2053 | 2n_w10_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 2 Nodes - Windows 10 - MCS - AHV | TBC - Fill out once test started. | |
| RA-2053 | 4n_w10_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 4 Nodes - Windows 10 - MCS - AHV | TBC - Fill out once test started. | |
| RA-2053 | 6n_w10_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 6 Nodes - Windows 10 - MCS - AHV | TBC - Fill out once test started. | | 
| RA-2053 | 8n_w10_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 8 Nodes - Windows 10 - MCS - AHV | TBC - Fill out once test started. | |
| RA-2053 | 8n_w10_uXXX_vXXX_pvs_ahv | 3 | ❌ | TBC | 8 Nodes - Windows 10 - PVS - AHV | TBC - Fill out once test started. | |
| RA-2053 | 8n_w11_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 8 Nodes - Windows 11 - MCS - AHV | TBC - Fill out once test started. | |
| RA-2150 | 1n_s22_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 1 Nodes - Server 2022 - MCS - AHV | TBC - Fill out once test started. | |
| RA-2150 | 2n_s22_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 2 Nodes - Server 2022 - MCS - AHV | TBC - Fill out once test started. | |
| RA-2150 | 4n_s22_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 4 Nodes - Server 2022 - MCS - AHV | TBC - Fill out once test started. | |
| RA-2150 | 6n_s22_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 6 Nodes - Server 2022 - MCS - AHV | TBC - Fill out once test started. | |
| RA-2150 | 8n_s22_uXXX_vXXX_mcs_ahv | 3 | ❌ | TBC | 8 Nodes - Server 2022 - MCS - AHV | TBC - Fill out once test started. | |
| RA-2150 | 8n_s22_uXXX_vXXX_pvs_ahv | 3 | ❌ | TBC | 8 Nodes - Server 2022 - PVS - AHV | TBC - Fill out once test started. | |

## Test Comparisons

Any specific test comparisons made and a report link to the Grafana dashboard with those tests selected.

| Operating System | Detail | Report URL | Test Comparison | Completed |
| :-- | :-- | :-- | :-- | :-- |
| TBC | TBC | [Report](http://10.57.64.101:3000) | TBC  | ✅ |
| | | | |

