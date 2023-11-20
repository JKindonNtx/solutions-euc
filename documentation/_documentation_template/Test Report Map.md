# Document Name Test Matrix

## Icon Set
| Running | Completed | Not Started | Problem |
| :---: | :---: | :---: | :---: |
| 🏃🏻‍♂️ | ✅ | ❌ | ⚠️ |

## Warnings / Details

Details any warnings or considerations that need to be reviewed as part of the testing schedule for this document.

| Warning | Detail |
| :---: | :--- |
| ⚠️ | Warning Item Number 1 |
| ⚠️ | Warning Item Number 2 |

## Test to Delete

Any tests run as part of the document that require deleting before producing the final document.

| | Test ID | Detail |
| :---: | --- | :--- |
| ❌ | 7e8766_8n_A6.5.2.7_AHV_5V_5U_KW | Delete as Dummy Run |
| ❌ | a4df64_8n_A6.5.2.7_AHV_1000V_1000U_KW | Missing Data as an example |

## Test Infrastructure Components

Infrastructure Components in place for the testing. Detail any additional components that are required such as scripts, file copy jobs etc that are part of the testing.

| Component | Info | Status | Detail | Owner | Tested | 
| :-- | :-- | :-- | :-- | :-- | :-- |
| Workload Cluster | 10.56.68.XXX | ✅ | X-node cluster | Username | ✅ |
| LE Appliance | WS-LE1/2/3 | ✅ | Good to go | Username | ✅ |
| Files Cluster | 10.56.68.XXX | ✅ | 4.3.0.1 (ws-profile) | Username | ✅ |
| Image | W10-XXXX-XXXX_Snap_Optimized | ✅ | Image Description | Username | ✅ |
| Catalog | Machine Count | ✅ | Catalog Detail | Username | ✅ |

## Group Policy Configurations

Detail any group policies that you will be using as part of the testing.

| Policy | Detail | Test Info |
| :-- | :-- | :-- |
| GPO Name - General Settings | General behaviors | All Tests |
| GPO Name - Specific Settings | Specific behavior details | All Specific Tests |

## Test Names

Detail the tests you are planning to run as part of the document.
| Test Name | Run Count | Completed | By | Info | Test ID |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Test Description from JSON | 3 | ✅ | Username | Test Description | TBC - Fill out once test started. |
| Test Description from JSON | 1 | ❌ | Username | Test Description | TBC - Fill out once test started. |

## Test Comparisons

Any specific test comparisons made and a report link to the Grafana dashboard with those tests selected.

| Operating System | Detail | Report URL | Test Comparison | Completed |
| :-- | :-- | :-- | :-- | :-- |
| Windows 10 | Baseline Comparison | [Report](http://10.57.64.101:3000) | Test Comparison Description  | ✅ |
| | | | |
| Windows 10 | Next Comparison | [Report](http://10.57.64.101:3000) | Test Comparison Description  | ✅ |
| | | | |
