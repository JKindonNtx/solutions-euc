## Objective

Automate the replication of Citrix base images using a `Protection Domain` in a 1:many relationship (1 Source Cluster with many remote Clusters). 

Citrix Machine Creation Services uses Nutanix Prism Element `Snapshots` for Catalog creation and updates when integrated with PE.

The end state should be an identical snapshot available on the source, and all remote clusters ready for Citrix Machine Creation Services Provisioning.

## Automation Requirements

- A single Nutanix cluster holding the base image virtual machine (vm) should be the single update point for Citrix images.
- All clusters associated with a `Protection Domain` hosting the base image should ultimately have a `Snapshot` ready for Citrix Provisioning.
- The source cluster should also have an identical snapshot to ensure consistency across all clusters with associated Citrix `Hosting Connections` and `Catalogs`.

## Technical requirements for running the script

- The script is written 100% in PowerShell and uses the NutanixCmdLets to action all tasks. These must be installed and available on the machine executing the script.
- The script assumes the same username and password for all PE instances including the source.

## Parameter and Scenario Details

The following parameters exist to drive the behaviour of the script:

#### Mandatory and recommended parameters:

- `SourceCluster`: Mandatory **`String`**. The source Nutanix PE instance which holds the Citrix base image VM.
- `pd`: Mandatory **`String`**. The Protection Domain on the Source Cluster holding the base image VM.
- `BaseVM`: Mandatory **`String`**. The name of the Citrix base image VM. This is CASE SENSITIVE.
- `ImageSnapsToRetain`: Optional **`Integer`**. The number of snapshots to retain on each target Cluster. This is limited only to snaps meeting the `BaseVM` and `VMPrefix` naming patterns (Snapshots the script created).
- `TriggerPDReplication`: Optional **`Switch`**. Will trigger an out of band replication for the Protection Domain and query the PD events for success. Snapshot will expire after 1 hour (`3600 seconds`).

#### Optional Parameters

- `LogPath`: Optional **`String`**. Log path output for all operations. The default is `C:\Logs\MCSReplicateBaseImage.log`
- `LogRollover`: Optional **`Integer`**. Number of days before the log files are rolled over. The default is 5
- `VMPrefix`: Optional **`String`**. The prefix used for both the restored VM (temp) and the associated Snapshot. The default is `ctx_`
- `SnapshotID`: Optional **`String`**. If you do not want to use the latest snapshot, specify the appropriate Protection Domain Snapshot ID from the Source Cluster.
- `SleepTime`: Optional **`Integer`**. The amount of time to sleep between VM creation and Snapshot creation tasks. Default is `10 seconds`.
- `UseCustomCredentialFile`: Optional. Will call the `Get-CustomCredentials` function which keeps outputs and inputs a secure credential file base on `Stephane Bourdeaud` from Nutanix functions.
- `CredPath`: Optional **`String`**. Used if using the `UseCustomCredentialFile` parameter. Defines the location of the credential file. The default is `"$Env:USERPROFILE\Documents\WindowsPowerShell\CustomCredentials"`
- `ExcludeSourceClusterFromProcessing` **`Switch`**: Optional. By default the Source Cluster is also processed to ensure consistency of snapshots available to Citrix. This switch allows to the Source Cluster to be ignored incase the VM snaps have already been handled and snap naming consistency doesn't matter.
- `MaxReplicationSuccessQueryAttempts`: Optional **`Integer`**. An advanced parameter to alter the number of successful PD query events. Defaults to `10`. Time between those queries is an advanced variable in the script which you should be careful with (10 seconds).

The following examples use parameter splatting to make reading easier. A corresponding commandline example is also included:

### Scenarios

#### General Basic Suggested Use

This scenario is the optimal and most generic use case for this script.

```
$params = @{
    SourceCluster                      = "1.1.1.1" # The source Cluster holding the base image vm
    pd                                 = "PD-Citrix-Base-Image" # The protection domain holding the base image vm
    BaseVM                             = "CTX-Gold-01" # The name of the Base image VM. Case sensitive.
    ImageSnapsToRetain                 = 10 # The number of snapshots to retain in each cluster.
    UseCustomCredentialFile            = $true # Will look for a custom credential file. If not found, will create
    TriggerPDReplication               = $true # Triggers an out-of-band PD replication for the specified PD
}
& ReplicateCitrixBaseImageVM.ps1 @params 
```

```
.\ReplicateCitrixBaseImageVM.ps1 -SourceCluster "1.1.1.1" -pd "PD-Citrix-Base-Image" -BaseVM "CTX-Gold-01" -ImageSnapsToRetain 10 -UseCustomCredentialFile -TriggerPDReplication
```

The script will:

- Connect to the source `1.1.1.1` Cluster, and authenticate using a custom credential file. If that does not exist, it will be created and used next time. 
- Look for the `PD-Citrix-Base-Image` Protection Domain and the associated `CTX-Gold-01` protected Instance. An out of band replication will occur on the `PD-Citrix-Base-Image` to all associated target clusters. 
- Process the source cluster `1.1.1.1` by creating a snapshot of the base VM directly `CTX-Gold-01`. 
- Process each target cluster by creating a snapshot with an identical name based on the default `VMPrefix` value of `ctx_` + `BaseVM` + `Date`. For example: `ctx_CTX-Gold-01_2023-05-15 16:55:41`.
- Delete all snapshots matching the above naming pattern older than `10` based on the `ImageSnapsToRetain` parameter
- Log all output to the default `LogPath` directory of `C:\Logs\MCSReplicateBaseImage.log` and rollover logs after `5 days` based on the default `LogRollover` value.

#### Change the snapshot name output and exclude source cluster

```
$params = @{
    SourceCluster                      = "1.1.1.1" # The source Cluster holding the base image vm
    pd                                 = "PD-Citrix-Base-Image" # The protection domain holding the base image vm
    BaseVM                             = "CTX-Gold-01" # The name of the Base image VM. Case sensitive.
    VMPrefix                           = "custsnapname_" # The prefix for VM and snapshot restore
    ImageSnapsToRetain                 = 20 # The number of snapshots to retain in each cluster.
    UseCustomCredentialFile            = $true # Will look for a custom credential file. If not found, will create
    ExcludeSourceClusterFromProcessing = $false # Excludes the source cluster from being included in snapshot processing
    TriggerPDReplication               = $true # Triggers an out-of-band PD replication for the specified PD
}
& ReplicateCitrixBaseImageVM.ps1 @params 
```

```
.\ReplicateCitrixBaseImageVM.ps1 -SourceCluster "1.1.1.1" -pd "PD-Citrix-Base-Image" -BaseVM "CTX-Gold-01" -VMPrefix "custsnapname_" -ImageSnapsToRetain 20 -UseCustomCredentialFile -TriggerPDReplication -ExcludeSourceClusterFromProcessing
```

The script will:

- Connect to the source `1.1.1.1` Cluster, and authenticate using a custom credential file. If that does not exist, it will be created and used next time. 
- Look for the `PD-Citrix-Base-Image` Protection Domain and the associated `CTX-Gold-01` protected Instance. An out of band replication will occur on the `PD-Citrix-Base-Image` to all associated target clusters. 
- Ignore the source cluster `1.1.1.1` due to the `ExcludeSourceClusterFromProcessing` switch meaning no snapshot will match on the source cluster.
- Process each target cluster by creating a snapshot with an identical name based on the updated `VMPrefix` value of `custsnapname_` + `BaseVM` + `Date`. For example: `custsnapname_CTX-Gold-01_2023-05-15 16:55:41`.
- Delete all snapshots matching the above naming pattern older than `20` based on the `ImageSnapsToRetain` parameter
- Log all output to the default `LogPath` directory of `C:\Logs\MCSReplicateBaseImage.log` and rollover logs after `5 days` based on the default `LogRollover` value.

#### Advanced selection of specific PD Snapshot ID, manual auth, Source exclusion and no forced replication. 

```
$params = @{
    SourceCluster                      = "1.1.1.1" # The source Cluster holding the base image vm
    pd                                 = "PD-Citrix-Base-Image" # The protection domain holding the base image vm
    BaseVM                             = "CTX-Gold-01" # The name of the Base image VM. Case sensitive.
    ImageSnapsToRetain                 = "100" # The number of snapshots to retain in each cluster.
    SnapshotID                         = "657465" # The PD Snapshot ID of the desired snapshot if the source cluster
    ExcludeSourceClusterFromProcessing = $true # Excludes the source cluster from being included in snapshot processing
    TriggerPDReplication               = $false # Triggers an out-of-band PD replication for the specified PD
}
& ReplicateCitrixBaseImageVM.ps1 @params 
```

```
.\ReplicateCitrixBaseImageVM.ps1 -SourceCluster "1.1.1.1" -pd "PD-Citrix-Base-Image" -BaseVM "CTX-Gold-01" -SnapshotID "657465" -ImageSnapsToRetain 100 -ExcludeSourceClusterFromProcessing
```

The script will:
- Connect to the source `1.1.1.1` Cluster, and prompt for credentials to use for authentication due to missing the `UseCustomCredentialFile` switch.
- Look for the `PD-Citrix-Base-Image` Protection Domain and the associated `CTX-Gold-01` protected Instance. An out of band replication will not occur due to missing the `TriggerPDReplication` switch. 
- Process each target cluster by creating a snapshot with an identical name based on the default `VMPrefix` value of `ctx_` + `BaseVM` + `Date`. For example: `ctx_CTX-Gold-01_2023-05-15 16:55:41`.
- Use a specific PD Snapshot ID of `657465` as per the `SnapshotID` parameter.
- Ignore the source cluster `1.1.1.1` due to the `ExcludeSourceClusterFromProcessing` switch meaning no snapshot will match on the source cluster.
- Delete all snapshots matching the above naming pattern older than `100` based on the `ImageSnapsToRetain` parameter.
