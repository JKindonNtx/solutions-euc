# Introduction

This tech note is part of the Nutanix Solutions Library. We wrote it for individuals responsible for designing, building, managing, and supporting FSLogix Profiles on Nutanix infrastructures. Readers should be familiar with Nutanix AOS, Prism, AHV, Nutanix Files and FSLogix Containers. Our testing was undertaken with Citrix Virtual Apps and Desktops (CVAD).

## Purpose

This document covers the following subject areas:

- Overview of the Nutanix solution.
- Overview of the FSLogix Containers Profile solution.
- Nutanix Files baseline testing.
- FSLogix Container testing, specifically:
  - The impacts of recommended storage configuration options such as Continuous Availability.
  - The impacts of different mode configurations for FSLogix Containers (Mode 0 and Mode 3) on Nutanix Files.
  - The impacts of FSLogix Cloud Cache on Nutanix Files.
  - The impacts of VHD Disk Compaction.
- Considerations for FSLogix Profiles on Nutanix.

## Document Version History 

| Version Number | Published | Notes |
| :---: | --- | --- |
| 1.0 | October 2023 | Original publication. |
