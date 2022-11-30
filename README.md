
# EUC Solutions

This is a shared repository for the Nutanix EUC Solutions team. 

## Rules Of Engagement

The following are the rules/guidelines for this repository, please follow them as they are there to ensure that we don't suffer the loss of code or double up on work efforts.

### Coding / Scripting
- Please create a new Branch for all commits and do not commit directly to main. This is so that GitHub can vet the changes you are implementing and anything you have written will not get inadvertently over-written by someone else
- Branch naming. Please prefix each branch with your initials then an underscore then what the branch is for i.e. db_update_main_readme
- All code here is provided "as-is" and should be tested / reviewed before being used in a production environment
- If you want to pick up some development work then go to the issues log, create a branch and get to work!

### Documentation
- Please use Markdown for all documentation as this is the Nutanix standard for technical documentation
- Please place all documentation in the relevant folder, if you require images in your document then there is an images' folder within the documentation folder for this purpose

### Engineering 'vs' Collateral
- The engineering folder is for 'production' scripts and functions. These are critical to the day-to-day tasks that the solutions team perform and should be edited with care
- The collateral folder is for scripts, tips and tricks that the solutions team may find useful. This is more of a 'dumping ground' for useful items

## Docker

There is a .devcontainer folder in the root of this repository with a definition for a Docker Container built. Please edit these definition files with care as they will affect the performance testing lab scripts. If using VS Code you can open or clone this repo and open it in a container. This will allow you to execute the following products locally from your laptop regardless of the OS / software installed:

- Ansible
- Terraform
- Packer
- PowerShell Core

## Issues and Projects

There is a live issues board with all current outstanding issues present in the 'Lab' framework.  If you find a new issue please log it [here](https://github.com/nutanix-enterprise/solutions-euc/issues), also be sure to assign it to the 'EUC Lab' project found [here](https://github.com/orgs/nutanix-enterprise/projects/3). The workflow for issues is:

- Log a new issue (please be as descriptive as possible)
- Tag it as a bug or enhancement
- Assign it to the EUC Lab project

Then to work on an issue:

- Assign the issue to yourself from the EUC Lab project
- Move the issue to in-progress
- Create a branch and fix the issue
- Submit the branch for review
- Merge the branch to 'main'
- Mark the issue as complete and delete the branch


If you have any issues then please reach out to a member of the team.

Thanks!