# Introduction

This document describes the setup of InfluxDB and Grafana in the Durham lab.

# InfluxDB

## Config

VM running on the infrastructure cluster (10.57.64.25). Details:
| Parameter | Detail |
| --- | --- |
| Name | WS-IDB1 |  
| IP | 10.57.64.101 |
| vCPUs | 8 |
| Memory | 16GB |
| OS | Ubuntu Server |

## Installation

- Create a VM
- Install Ubuntu from iso (\\ws-files.wsperf.nutanix.com\automation\OS\Server\ubuntu-22.04.3-live-server-amd64.iso)
  - user: nutanix
- Make sure lvm mapping is using all of the disk
  - sudo lvresize -tvl +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
  - sudo lvresize -vl +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
  - sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
- Install Docker
- Install Docker Compose
  -  sudo curl -L https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
- Create folders in /home/nutanix/
  - docker
  - docker/appdata
  - docker/appdata/influxdb2
  - docker/appdata/influxdb2/db
  - docker/appdata/influxdb2/config
- set permissions:
  -  sudo setfacl -Rdm g:nutanix:rwx /home/nutanix/docker/
  -  sudo setfacl -Rd g:nutanix:rwx /home/nutanix/docker/

- Create these files:
  - docker/.env
----
PUID=1000
PGID=1000
TZ="America/Los_Angeles"
USERDIR="/home/nutanix"
DOCKERDIR="/home/nutanix/docker"
DATADIR="/media/storage"

----

  - docker/docker-compose.yml

----
version: "3.9"

########################### NETWORKS
networks:
  default:
    driver: bridge

########################### SERVICES
services:
# InfluxDB - Database
  influxdb:
    image: influxdb:latest
    container_name: influxdb
    networks:
      - default
    security_opt:
      - no-new-privileges:false
    restart: unless-stopped
    ports:
      - "8086:8086"
    volumes:
      - $DOCKERDIR/appdata/influxdb2/config:/etc/influxdb2:rw
      - $DOCKERDIR/appdata/influxdb2/db:/var/lib/influxdb2:rw
----



- Install InfluxDB using Docker Compose file
  - sudo docker compose -f ~/docker/docker-compose.yml up -d
- Restore InfluxDB from backup
  - Copy content of backup dir to ~/docker/appdata/influxdb2/db/backup
  - sudo docker exec -it influxdb bash
  - influx restore /var/lib/influxdb2/backup -t C89NatqtrEaf5WLiarIAS9MhHHhVHTS0Y34zGTJlgLWrldAS05a5lfSGK-JdWUlhkrwZMJW3dzkRWn-J2nikEw==
  - (this can take a long time, 1 day at least)

## Backup

Backup is running from WS-GRAF2 VM as scheduled task (backup-script.ps1). Backup is stored on
\\ws-files.wsperf.nutanix.com\backup\influxdb



# Grafana

VM

\\ws-files.wsperf.nutanix.com\Automation\Apps\Other\Grafana\grafana-enterprise-10.2.0.windows-amd64.msi

## Installation

## Backup

Backup is running from WS-GRAF2 VM as scheduled task. Backup is stored on
\\ws-files.wsperf.nutanix.com\backup\Grafana

  
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