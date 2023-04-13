# Introduction

## Audience

This best practice document <!--JK: @david-brett document or guide? --> is part of the Nutanix Solutions Library. We wrote it for architects and administrators responsible for configuring Citrix Virtual Apps and Desktops (CVAD) on AHV with Nutanix Flow Network Security. Readers of this document should already be familiar with Nutanix AHV, Prism Central, Networking basics, and CVAD.

## Purpose

In this document we describe how to use Nutanix Flow Network Security to design a set of categories and security policies for a CVAD environment running on Nutanix AHV, including the infrastructure and worker VMs. We cover the following subjects:

- Nutanix Cloud Platform overview.
- Nutanix Flow Network Security overview.
- Design concepts for Nutanix Flow Network Security.
- Implementing Nutanix Flow Network Security.
- Monitoring Nutanix Flow Network Security.
- Enforcing Nutanix Flow Network Security.
- Auditing Nutanix Flow Network Security.
- Conclusion. <!--JK: @david-brett Not sure if these go here - that's more of a TOC format?-->
- Appendix. <!--JK: @david-brett Not sure if these go here - that's more of a TOC format?-->
  
Unless otherwise stated, the solution described in this document is valid on all supported AOS releases.

## Document Version History

| **Version Number** | **Published** | **Notes** |
| :---: | --- | --- |
| 1.0 | June 2019 | Original publication. |
| 1.1 | October 2019 | Update for AOS 5.11. |
| 1.2 | March 2021 | Updated Nutanix overview, terminology and references. |
| 1.3 | March 2023 | Updated to provide detailed overview for CVAD. |

<!--JK: @david-brett just making sure this version table is accurate?-->