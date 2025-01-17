# Using New-GrafanaReport.ps1

## Parameters

-  `SourceUri`. Mandatory **`String`**. The source Url of the grafana report. Build the report and either copy the URL from the browser, or use the Granfana share link.
-  `ReportTitle`. Mandatory **`String`**. A Title for the report output. This will create a report output folder named accordingly and dump the markdown and images into sub folders.
-  `mdFile`. Optional **`String`**. You can choose a custom markdown file name, else the default will be `README.MD` under the `md` directory under the `ReportTitle` directory.
-  `ImageSuffix`. Optional **`String`**. You can choose to inject a suffix into the image name to make it easier when doing multiple reports and runs.
-  `influxDbUrl`. Optional **`String`**. This is hardcoded currently to the Influx Database URL.
-  `InfluxToken`. Optional **`String`**. This is hardcoded currently with a provided Token.
-  `iconsSource`. Optional **`String`**. The source if icon files. This is hardcoded currently to `http://10.57.64.119:3000/public/img/nutanix/`
-  `ExcludedComponentList`. Optional **`Array`**. A list of sections to exclude. The default exclusion list is `"BootInfo","IndividualRuns","NutanixFiles","CitrixNetScaler"`.
-  `ImageReferenceCSV`. Optional. **`String`**. A CSV file containing a list of Grafana Panel IDs to image names. Defaults to `ImageReference.csv` found in the same path as the script.

```
.\New-GrafanaReport.ps1 -SourceUri "http://grafanareport" -ReportTitle "RAS_WinServ2022_Linked_vs_Full_Clone" -ImageSuffix "2022_prov"
```

## How To

### Add a new graph download

Add a new Graph to the image download:

-  Identify the panel ID in grafana from the share link for the panel. E.g. `119`
-  Identify the section you are dealing with, E.g. `Individual Runs`
-  Add the Panel ID to the source `ImageReference.csv` file and give it a name.
-  Find the `$Panels` Array for the appropriate section. Add the Panel ID `119`

# Using FixMDOutput.ps1

The script is designed to strip all HTML content out of the markdown report generated by `New-GrfanaReport.ps1`. It does this by importing the source file, searching for specific known HTML patterns and references, and then replacing them with native markdown syntax, and dumping the cleansed config to a new markdown file.

## Parameters

-  `mdFile`. Mandatory **`String`**. The location of the source file with HTML.
-  `mdOutfile` Optional **`String`**. The output location for the new file. The default is `README_nothtml.MD` in the parent directory of the source file. 

```
.\FixMDOutput.ps1 -mdFile c:\temp\readme.MD
```

## Caveats

This is not an exact science. Changes to the source report output may require adjustments to the regex expressions used in the script.