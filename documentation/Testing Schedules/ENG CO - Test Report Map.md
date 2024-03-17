# Compute Only - Login Enterprise workload Test Matrix

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
| ⚠️ | Create new baseline tests with 8 nodes, AOS 6.7.1.6 and the Knowledgeworker (1000) and Taskworker profile (1500) |
| ⚠️ | AOS 6.7.1.6 has an issue with Citrix plugin. Need to retest baseline with AOS 6.5 |
| ⚠️ | Test with 4x HCI (NX-G9) + 4x CO (NX-G9). 1:1. KW 1000, TW 1500 |
| ⚠️ | Test with 4x HCI (HPE-Gen11) + 4x CO (NX-G9). 1:1. KW 880, TW 1300 |
| ⚠️ | Test with 4x HCI (HPE-Gen11) + 8x CO (NX-G9). 2:1. KW 1000, TW 1500 |
| ⚠️ | Test with 4x HCI (HPE-Gen11) + 8x CO (NX-G9). 2:1. KW 1000, TW 1500 with affinity set to CO nodes |


## Test Infrastructure Components

Infrastructure Components in place for the testing. Detail any additional components that are required such as scripts, file copy jobs etc that are part of the testing.

| Component | Info | Status | Detail | Owner | Tested | 
| :-- | :-- | :-- | :-- | :-- | :-- |
| Workload Cluster G9 | 10.56.70.55 | ✅ | 8-node cluster | svenhuisman | ✅ |
| Workload Cluster HPE Gen11 | 10.56.68.190 | ✅ | 4-node cluster | svenhuisman | ✅ |
| LE Appliance | WS-LE1 | ✅ | Good to go | svenhuisman | ✅ |
| LE Launchers | LE1-202401-### | ✅ | Redeploy with new Launcher Agent and Citrix Workspace App | svenhuisman | ✅ |

## Baseline Numbers

Detail the testing baseline numbers.
| OS | CPU | Cores | Memory | VMs | Workload | Cluster | Status |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| Windows 10 (G9) | 1 | 2 | 4 | 1000  | Knowledgeworker | 10.56.70.55 | ✅ |
| Windows 10 (G9) | 1 | 2 | 4 | 1500  | Taskworker | 10.56.70.55 | ✅ |
| Windows 10 (HPE) | 1 | 2 | 4 | 380  | Knowledgeworker | 10.56.68.190 | ✅ |
| Windows 10 (HPE) | 1 | 2 | 4 | 550  | Taskworker | 10.56.68.190 | ✅ |


## Test Names

Detail the tests you are planning to run as part of the document.
| Test Name | Run Count | HCI nodes | CO nodes | VMs | Completed | By | Info | Test ID | VSI-Dashboard | Illuminati | Organon |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| W10 Baseline KW on G9 | 2 | 8 NX | 0 | 1000 | ✅ | Sven | 8 Nodes - W10 - HCI - NX-G9 - KW baseline | 55a081_8n_A6.7.1.6_AHV_1000V_1000U_KW | [Report](http://10.57.64.101:3000/d/N5tnL9EVk/login-documents-v3?orgId=1&var-Bucketname=LoginDocuments&var-Bootbucket=BootBucket&var-Year=2024&var-DocumentName=ENG-CO-Tests&var-Comment=8n_g9_ahv_w10_u1000_v1000_kw&var-Testname=55a081_8n_A6.7.1.6_AHV_1000V_1000U_KW&var-Run=55a081_8n_A6.7.1.6_AHV_1000V_1000U_KW_Run1&var-Naming=Comment&var-Month=03) | | |
| W10 Baseline TW on G9 | 2 | 8 NX | 0 | 1500 | ✅ | Sven | 8 Nodes - W10 - HCI - NX-G9 - TW baseline | ee4b49_8n_A6.7.1.6_AHV_1500V_1500U_TW | [Report](http://10.57.64.101:3000/d/N5tnL9EVk/login-documents-v3?orgId=1&var-Bucketname=LoginDocuments&var-Bootbucket=BootBucket&var-Year=2024&var-DocumentName=ENG-CO-Tests&var-Comment=8n_g9_ahv_w10_u1500_v1500_tw&var-Testname=ee4b49_8n_A6.7.1.6_AHV_1500V_1500U_TW&var-Run=ee4b49_8n_A6.7.1.6_AHV_1500V_1500U_TW_Run1&var-Naming=Comment&var-Month=03) | [Report Run2](https://illuminati.rtp.nutanix.com/collection/cid-1_clusterid-4761567880139609286_datetime-2024-03-08T173A053A31.686625_perf_1_0) | [Report Run2](https://organon.emea.nutanix.com/job?job=job:eac95f3e-250d-4f0f-89b6-383087e344ba) |
| W10 Baseline KW on HPE | 2 | 4 HPE | 0 | 400 | ✅ | Sven | 8 Nodes - W10 - HCI - HPE - KW baseline | cc1f88_4n_A6.7.1.6_AHV_400V_400U_KW | [Report](http://10.57.64.101:3000/d/N5tnL9EVk/login-documents-v3?orgId=1&var-Bucketname=LoginDocuments&var-Bootbucket=BootBucket&var-Year=2024&var-DocumentName=ENG-CO-Tests&var-Comment=4n_hpg11_w10_400u_kw&var-Testname=cc1f88_4n_A6.7.1.6_AHV_400V_400U_KW&var-Run=cc1f88_4n_A6.7.1.6_AHV_400V_400U_KW_Run1&var-Naming=Comment&var-Month=03)| | |
| W10 Baseline KW on HPE | 2 | 4 HPE | 0 | 380 | ✅ | Sven | 8 Nodes - W10 - HCI - HPE - KW baseline | d5ae94_4n_A6.7.1.6_AHV_380V_380U_KW | [Report](http://10.57.64.101:3000/d/N5tnL9EVk/login-documents-v3?orgId=1&var-Bucketname=LoginDocuments&var-Bootbucket=BootBucket&var-Year=2024&var-DocumentName=ENG-CO-Tests&var-Comment=4n_hpg11_w10_380u_kw&var-Testname=d5ae94_4n_A6.7.1.6_AHV_380V_380U_KW&var-Run=d5ae94_4n_A6.7.1.6_AHV_380V_380U_KW_Run1&var-Naming=Comment&var-Month=03) | [Report Run2](https://illuminati.rtp.nutanix.com/collection/cid-1_clusterid-4036936260608970908_datetime-2024-03-08T153A313A21.282939_perf_1_0) | [Report Run2](https://organon.emea.nutanix.com/job?job=job:2b95a6cd-6279-430b-8226-0ffe5a246b8c)|
| W10 Baseline TW on HPE | 2 | 4 HPE | 0 | 550 | ✅ | Sven | 8 Nodes - W10 - HCI - HPE - KW baseline | 5e0bd2_4n_A6.7.1.6_AHV_550V_550U_TW | [Report](http://10.57.64.101:3000/d/N5tnL9EVk/login-documents-v3?orgId=1&var-Bucketname=LoginDocuments&var-Bootbucket=BootBucket&var-Year=2024&var-DocumentName=ENG-CO-Tests&var-Comment=4n_hpg11_w10_550u_tw&var-Testname=5e0bd2_4n_A6.7.1.6_AHV_550V_550U_TW&var-Run=5e0bd2_4n_A6.7.1.6_AHV_550V_550U_TW_Run1&var-Naming=Comment&var-Month=03)| | |
| W10 Baseline KW on G9 - CO | 2 | 4 NX | 4 NX | 1000 | ✅ | Sven | 8 Nodes - W10 - HCI-CO - NX-G9 - KW | 6feeef_8n_A6.5.5.1_AHV_1000V_1000U_KW | [Report](http://10.57.64.101:3000/d/N5tnL9EVk/login-documents-v3?orgId=1&var-Bucketname=LoginDocuments&var-Bootbucket=BootBucket&var-Year=2024&var-DocumentName=ENG-CO-Tests&var-Comment=CO_4hci_4co_g9_ahv_w10_u1000_v1000_kw&var-Testname=6feeef_8n_A6.5.5.1_AHV_1000V_1000U_KW&var-Run=6feeef_8n_A6.5.5.1_AHV_1000V_1000U_KW_Run1&var-Naming=Comment&var-Month=03) | [Report Run2](https://illuminati.rtp.nutanix.com/collection/cid-1_clusterid-849628653814912198_datetime-2024-03-13T183A423A49.414685_perf_1_0) | [Report Run2](https://organon.emea.nutanix.com/job?job=job:4ade16e3-6a80-4626-b1c0-590a93fca5ed#) |
| W10 Baseline TW on G9 - CO | 2 | 4 NX | 4 NX | 1500 | ⚠️ | Sven | 8 Nodes - W10 - HCI-CO - NX-G9 - TW | Problem with 109 VMs getting IP from IPMI | | | |
| W10 Baseline TW on G9 - CO | 2 | 4 NX | 4 NX | 1300 | 🏃🏻‍♂️ | Sven | 8 Nodes - W10 - HCI-CO - NX-G9 - TW | TBD | | | |
| W10 Baseline KW on HPE+G9 - CO | 2 | 4 HPE | 4 NX | 880 | ❌ | Sven | 8 Nodes - W10 - HCI-CO - HPE+NX-G9 - KW | TBD | |
| W10 Baseline TW on HPE+G9 - CO | 2 | 4 HPE | 4 NX | 1300 | ❌ | Sven | 8 Nodes - W10 - HCI-CO - HPE+NX-G9 - TW | TBD | |
| W10 Baseline KW on HPE+G9 - CO2-1 | 2 | 4 HPE | 8 NX | 1000 | ❌ | Sven | 8 Nodes - W10 - HCI-CO - HPE+NX-G9 - KW | TBD | |
| W10 Baseline TW on HPE+G9 - CO2-1 | 2 | 4 HPE | 8 NX | 1500 | ❌ | Sven | 8 Nodes - W10 - HCI-CO - HPE+NX-G9 - TW | TBD | |
| W10 Baseline KW on HPE+G9 - CO2-1-aff | 2 | 4 HPE | 8 NX | 1000 | ❌ | Sven | 8 Nodes - W10 - HCI-CO - HPE+NX-G9 - KW - affinity set to CO | TBD | |
| W10 Baseline TW on HPE+G9 - CO2-1-aff | 2 | 4 HPE | 8 NX | 1500 | ❌ | Sven | 8 Nodes - W10 - HCI-CO - HPE+NX-G9 - TW - affinity set to CO | TBD | |

## Test Comparisons

Any specific test comparisons made and a report link to the Grafana dashboard with those tests selected.

| Operating System | Detail | Report URL | Test Comparison | Completed |
| :-- | :-- | :-- | :-- | :-- |
| | | | |
| | | | |
