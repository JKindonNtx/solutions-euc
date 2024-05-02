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
| ✅ | 430775_1n_A6.5.5.1_AHV_140V_140U_KW | Failed host power metrics due to missing code |
| ✅ | 1d166a_1n_A6.5.5.1_AHV_140V_140U_KW | Failed due to Edge updating and breaking LE |
| ✅ | c292be_2n_A6.5.5.1_AHV_280V_280U_KW | Failed due to Edge updating and breaking LE |
| ✅ | 83d99d_4n_A6.5.5.1_AHV_560V_560U_KW | Failed due to Edge updating and breaking LE |
| ✅ | eed284_6n_A6.5.5.1_AHV_840V_840U_KW | Failed due to Edge updating and breaking LE |
| ✅ | fbfffe_1n_A6.5.5.1_AHV_140V_140U_KW | (Weird run3) |
| ✅ | 4fa8ce_6n_A6.5.5.1_AHV_900V_900U_KW | Failed due to wrong version of Edge on Windows 10 |

## Test Infrastructure Components

Infrastructure Components in place for the testing. Detail any additional components that are required such as scripts, file copy jobs etc that are part of the testing.

| Component | Info | Status | Detail | Owner | Tested | 
| :-- | :-- | :-- | :-- | :-- | :-- |
| Workload Cluster | 10.56.68.135 | ✅ | 6-node cluster | jameskindon | ✅ |
| LE Appliance | WS-LE1 | ✅ | NA| jameskindon | ✅ |
| Image | W11-23H2-6127_Snap_Optimized_DefOff | ✅ | Windows 11 Base Image | jameskindon | ✅ |
| Image | W11-23H2-8b83 (PVS_Gold) | ✅ | Windows 11 Base Image - PVS Base | jameskindon | ✅ |
| Template | W11-Gold-PVS-Template | ✅ | Windows 11 PVS Template | jameskindon | ✅ |
| Image | W10-22H2-6c98_Snap_Optimized | ✅ | Windows 10 Base Image | jameskindon | ✅ |
| Catalog | 900 | ✅ | LE-W11-AMD | jameskindon | ✅ |
| Catalog | 900 | ✅ | LE-W11-AMD-PVS | jameskindon | ✅ |
| Catalog | 900 | ✅ | LE-W10-AMD | jameskindon | ✅ |

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
| Windows 11 MCS 1n | 1 | ✅ | jameskindon | Windows 11 MCS 1n | e657a3_1n_A6.5.5.1_AHV_140V_140U_KW | w11_amd_mcs_1n_A6.5.5_AHV_140V_140U_KW_2_4 |
| Windows 11 MCS 2n | 1 | ✅ | jameskindon | Windows 11 MCS 2n | e0a5ef_2n_A6.5.5.1_AHV_280V_280U_KW | w11_amd_mcs_2n_A6.5.5_AHV_280V_280U_KW_2_4 |
| Windows 11 MCS 1n | 1 | ✅ | jameskindon | Windows 11 MCS 1n | c061b5_1n_A6.5.5.1_AHV_140V_140U_KW | w11_amd_mcs_1n_A6.5.5_AHV_140V_140U_KW_3_6 |
| Windows 11 MCS 2n | 1 | ✅ | jameskindon | Windows 11 MCS 2n | 4ea4e5_2n_A6.5.5.1_AHV_280V_280U_KW | w11_amd_mcs_2n_A6.5.5_AHV_280V_280U_KW_3_6 |
| Windows 11 MCS 1n | 1 | ✅ | jameskindon | Windows 11 MCS 1n | 8704d9_1n_A6.5.5.1_AHV_150V_150U_KW | w11_amd_mcs_1n_A6.5.5_AHV_150V_150U_KW_3_6 |
| - | - | - | - | - | - | - |
| Windows 11 MCS 1n | 3 | ✅ | jameskindon | Windows 11 MCS 1n | 3d9f32_1n_A6.5.5.1_AHV_150V_150U_KW | w11_amd_mcs_1n_A6.5.5_AHV_150V_150U_KW |
| Windows 11 MCS 2n | 3 | ✅ | jameskindon | Windows 11 MCS 2n | dc1e58_2n_A6.5.5.1_AHV_300V_300U_KW | w11_amd_mcs_2n_A6.5.5_AHV_300V_300U_KW |
| Windows 11 MCS 4n | 3 | ✅ | jameskindon | Windows 11 MCS 4n | 8b3e59_4n_A6.5.5.1_AHV_600V_600U_KW | w11_amd_mcs_4n_A6.5.5_AHV_600V_600U_KW |
| Windows 11 MCS 6n | 3 | ✅ | jameskindon | Windows 11 MCS 6n | 41fd33_6n_A6.5.5.1_AHV_900V_900U_KW | w11_amd_mcs_6n_A6.5.5_AHV_900V_900U_KW |
| Windows 10 MCS 6n | 3 | ✅ | jameskindon | Windows 10 MCS 6n | 38c9a1_6n_A6.5.5.1_AHV_900V_900U_KW | w10_amd_mcs_6n_A6.5.5_AHV_900V_900U_KW |
| Windows 11 PVS 6n | 3 | ✅ | jameskindon | Windows 11 PVS 6n | 3a8b5f_6n_A6.5.5.1_AHV_900V_900U_KW | w11_amd_pvs_6n_A6.5.5_AHV_900V_900U_KW |

## Test Comparisons

Any specific test comparisons made and a report link to the Grafana dashboard with those tests selected.

| Operating System | Detail | Report URL | Test Comparison | Completed |
| :-- | :-- | :-- | :-- | :-- |
| Windows 11 | MCS Baseline - Linear Scale | [Report](http://10.57.64.101:3000/d/N5tnL9EVk/login-documents-v3?orgId=1&var-Bucketname=LoginDocuments&var-Bootbucket=BootBucket&var-Year=2024&var-Month=04&var-DocumentName=RA-2020-Len-AMD&var-Run=3d9f32_1n_A6.5.5.1_AHV_150V_150U_KW_Run2&var-Run=41fd33_6n_A6.5.5.1_AHV_900V_900U_KW_Run2&var-Run=8b3e59_4n_A6.5.5.1_AHV_600V_600U_KW_Run2&var-Run=dc1e58_2n_A6.5.5.1_AHV_300V_300U_KW_Run2&var-Naming=Comment&var-Comment=w11_amd_mcs_1n_A6.5.5_AHV_150V_150U_KW&var-Comment=w11_amd_mcs_4n_A6.5.5_AHV_600V_600U_KW&var-Comment=w11_amd_mcs_6n_A6.5.5_AHV_900V_900U_KW&var-Comment=w11_amd_mcs_2n_A6.5.5_AHV_300V_300U_KW&var-Testname=3d9f32_1n_A6.5.5.1_AHV_150V_150U_KW&var-Testname=41fd33_6n_A6.5.5.1_AHV_900V_900U_KW&var-Testname=8b3e59_4n_A6.5.5.1_AHV_600V_600U_KW&var-Testname=dc1e58_2n_A6.5.5.1_AHV_300V_300U_KW) | Windows 11 MCS 1n vs Windows 11 MCS 2n vs Windows 11 MCS 4n vs Windows 11 MCS 6n Run2 | ✅ |
| | | | |
| Windows 11 | MCS vs PVS Baseline | [Report](http://10.57.64.101:3000/d/N5tnL9EVk/login-documents-v3?orgId=1&var-Bucketname=LoginDocuments&var-Bootbucket=BootBucket&var-Year=2024&var-Month=04&var-DocumentName=RA-2020-Len-AMD&var-Run=41fd33_6n_A6.5.5.1_AHV_900V_900U_KW_Run2&var-Run=3a8b5f_6n_A6.5.5.1_AHV_900V_900U_KW_Run2&var-Naming=Comment&var-Comment=w11_amd_mcs_6n_A6.5.5_AHV_900V_900U_KW&var-Comment=w11_amd_pvs_6n_A6.5.5_AHV_900V_900U_KW&var-Testname=41fd33_6n_A6.5.5.1_AHV_900V_900U_KW&var-Testname=3a8b5f_6n_A6.5.5.1_AHV_900V_900U_KW) | Windows 11 MCS 6n vs Windows 11 PVS 6n | ✅ |
| | | | |
| Windows 11 and 10 | Compare Windows 11 and Windows 10 with MCS | [Report](http://10.57.64.101:3000/d/N5tnL9EVk/login-documents-v3?orgId=1&var-Bucketname=LoginDocuments&var-Bootbucket=BootBucket&var-Year=2024&var-Month=04&var-DocumentName=RA-2020-Len-AMD&var-Run=38c9a1_6n_A6.5.5.1_AHV_900V_900U_KW_Run2&var-Run=41fd33_6n_A6.5.5.1_AHV_900V_900U_KW_Run2&var-Naming=Comment&var-Comment=w10_amd_mcs_6n_A6.5.5_AHV_900V_900U_KW&var-Comment=w11_amd_mcs_6n_A6.5.5_AHV_900V_900U_KW&var-Testname=38c9a1_6n_A6.5.5.1_AHV_900V_900U_KW&var-Testname=41fd33_6n_A6.5.5.1_AHV_900V_900U_KW) | Windows 11 MCS 6n run 2 vs Windows 10 MCS 6n run 3  | ✅ |
| | | | |

## Guiding Notes

- Prove Linear Scale with Windows 10 for MCS. Just the once.
- Compare MCS using Windows 10 or 11 6 node tests.
- Compare Windows 10 and Windows 11 MCS on 6 node tests.

