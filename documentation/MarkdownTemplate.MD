# Document Format

- Documents are split into sections by Tech Writing team. Typically Heading One per document
- Terms lists are preferred over tables. Example:
  
Term
: Definition

Term2
: Second definition

- Bullet writing is per Microsoft style guides
- Hyphen usage is based on Microsoft style guides
  - https://learn.microsoft.com/en-us/style-guide/punctuation/dashes-hyphens/
- Language is per Microsoft style guides. Personal language (I, we, you, they, your, us, them) is OK
- Figures do NOT need a caption
- Tables do need a caption. Example

_Table. This is a table_

| Heading | Detail |
| --- | --- |
| Bob | What a cool name | 

- Notes are formatted as below. These will format differently in the support portal than the preview utils or github rendering of the markdown

<Note>
  This is a nice note
</note>

- Images are referenced as below. Note that images are stored in a shared store, so all documents have their images stored in the /images/ directory. Not a bad idea to keep your images named inline with the document ID for simplicity of merge and identification

![Image!](../images/TN-ID-image01.png "Image Caption")

- URLs are referenced as below

[What a nice URL](https://thatjameskindonblokeisbloodygoodlooking/thanksdave.html)

A common document layout looks like below

- Exec Summary
- Introduction
- Content Specific Section A <- Add your goodies
- Content Specific Section B <- Add your goodies
- Conclusion
- Appendix

An example starting point is below:

# Executive Summary

Because Nutanix AOS can withstand hardware failures and software glitches, it ensures that application availability and performance are never compromised.

![Nutanix Hybrid Multicloud Software Overview](../images/overview-hybrid-multicloud-software.png "Nutanix Hybrid Multicloud Software Overview")

<--Text Here-->

# Introduction

## Audience

This tech note is part of the Nutanix Solutions Library. We wrote it for individuals responsible for designing, building, managing, and supporting Citrix DaaS on Nutanix infrastructures. Readers should be familiar with Nutanix AOS, Prism, AHV, Citrix DaaS with supporting components, and supporting Microsoft components.

## Purpose

This document covers the following subject areas:

- Overview of the Nutanix solution.
- Overview of .....

<--Text Here-->

## Document Version History

| **Version Number** | **Published** | **Notes** |
| :---: | --- | --- |
| 1.0 | January 2023 | Original publication. |

# Section 1

# Section 2

# Section 3

# Conclusion

<--Text Here-->

# Appendix

## References

-  [URL1](https://whatever.com)
-  [URL2](https://whateverelse.com)

