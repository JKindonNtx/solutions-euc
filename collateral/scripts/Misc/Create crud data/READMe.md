## Objective

Create and delete crud data in the users profile to allow for container compaction testing. Offer a selective, or automated process with a range of data sets (15, 30 and 45 Gb)

## Parameter and Scenario Details

The following parameters exist to drive the behaviour of the script:

- `LogPath`: Optional **`String`**. Log path output for all operations. The default is `C:\Logs\MCSReplicateBaseImage.log`
- `LogRollover`: Optional **`Integer`**. Number of days before the log files are rolled over. The default is `5`.
- `CrudPath`: Optional **`String`**. Path to create crud data. default is `C:\Users\%Username%\AppData\Roaming\CrudData`.
- `Mode`: Optional **`String`**. Create or Delete mode. Cannot be used with `AutoCreateAndClean`.
- `AutoCreateAndClean`: Optional **`Switch`**. Automatically creates, sleeps, and deletes data. cannot be used with `Mode` parameter.
- `AutoCreateAndCleanRestTime`: Optional **`Int`**. Amount of time to sleep between creation and deletion in `AutoCreateAndClean` mode. Defaults to `20` seconds.
- `FileSetSizeinGb`: Optional **`Int`**. Predefined amount of data to create. Offers `5`, `10`, `15`, `30` or `45` Gb options. Defaults to `15`.
- `Iscontainer`: Optional. To be used with FSLogix Containers. Turns out that the `System.IO.FileStream` class doesn't play nicely with the filter driver. This switch will do a basic file copy of the `C:\Windows\System32\WindowsCodecsRaw.dll` as many times as needed to math the `FileSetSizeinGb` parameter.

## Examples

```
.\CreateCrudData.ps1 -Mode Create
```
Will create data in C:\Users\\%Username%\AppData\Roaming\CrudData and use the default 15 GiB file set

```
.\CreateCrudData.ps1 -Mode Create -CrudPath "MoreCrudThanCrud"
```
Will create data in C:\Users\\%Username%\AppData\Roaming\MoreCrudThanCrud and use the default 15 GiB file set

```
.\CreateCrudData.ps1 -Mode Create -FileSetSizeinGb 30
```
Will create data in C:\Users\\%Username%\AppData\Roaming\CrudData and use the 30 GiB file set

```
.\CreateCrudData.ps1 -Mode Delete
```
Will delete data in C:\Users\\%Username%\AppData\Roaming\CrudData

```
.\CreateCrudData.ps1 -Mode Delete -CrudPath "MoreCrudThanCrud"
```
Will delete data in C:\Users\\%Username%\AppData\Roaming\MoreCrudThanCrud

```
.\CreateCrudData.ps1 -AutoCreateAndClean
```
Will create and delete data in C:\Users\\%Username%\AppData\Roaming\CrudData, wait the default 20 seconds between creation and deletion and use the default 15 GiB file set

```
.\CreateCrudData.ps1 -AutoCreateAndClean -AutoCreateAndCleanRestTime 30
```
Will create and delete data in C:\Users\\%Username%\AppData\Roaming\CrudData, wait 30 seconds between creation and deletion and use the default 15 GiB file set

```
.\CreateCrudData.ps1 -AutoCreateAndClean -FileSetSizeinGb 30 -CrudPath "MoreCrudThanCrud"
```
Will create and delete data in C:\Users\\%Username%\AppData\Roaming\MoreCrudThanCrud, wait default 20 seconds between creation and deletion and use the 30 GiB file set

```
.\CreateCrudData.ps1 -AutoCreateAndClean -FileSetSizeinGb 30 -CrudPath "MoreCrudThanCrud" -IsContainer
```
Will create and delete data in C:\Users\\%Username%\AppData\Roaming\MoreCrudThanCrud, wait default 20 seconds between creation and deletion and use the 30 GiB file set. Handles a file copy logic for FSLogix Containers.