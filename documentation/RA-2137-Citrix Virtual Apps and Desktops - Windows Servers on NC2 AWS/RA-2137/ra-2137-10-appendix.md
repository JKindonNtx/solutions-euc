# Appendix

## References

1.  [Login Enterprise](https://www.loginvsi.com/)
2.  [Login Enterprise EUX Score](https://support.loginvsi.com/hc/en-us/articles/4408717958162-Login-Enterprise-EUX-Score-#h_01GS8W30049HVB851TX60TDKS3)
3.  [Login Enterprise Workload Templates](https://support.loginvsi.com/hc/en-us/sections/360001765419-Workload-Templates)
4.  [Citrix Virtual Apps and Desktops 2203 Long Term Service Release (LTSR) Documentation](https://docs.citrix.com/en-us/citrix-virtual-apps-desktops/2203-ltsr/)

## Login Enterprise Configuration Changes

The following changes were made to the Login Enterprise configuration prior to running the tests to better reflect a VDI workload.

### Login Enterprise Actions

```
{
    "diskmydocs": {
      "App": "diskspeed",
      "Arguments": "folder=\"{myDocs}\" blockSize=4k bufferSize=32K writeMask=0x5555 cachePct=97 latencyPct=99 threads=1 duration=250",
      "Label": "MyDocuments"
    },
    "diskappdata": {
      "App": "diskspeed",
      "Arguments": "folder=\"{appData}\"  blockSize=50k bufferSize=4K writeMask=0x5555 cachePct=97 latencyPct=99 threads=1 duration=250",
      "Label": "LocalAppdata"
    },
    "cpuspeed": {
      "App": "cpuspeed",
      "Arguments": "d=250 t=4",
      "Label": "CPU"
    },
    "highcompression": {
      "App": "compressionspeed",
      "Arguments": "folder=\"{appData}\" cachePct=95 writePct=100 duration=250 threads=1 -high",
      "Label": "Compression"
    },
    "fastcompression": {
      "App": "compressionspeed",
      "Arguments": "folder=\"{appData}\" cachePct=95 writePct=100 duration=250 threads=1",
      "Label": "CachedHighCompression"
    },
    "appspeed": {
      "App": "appspeed",
      "Arguments": "folder=\"{appData}\" duration=10000 launchtimestamp={launchTimestamp}",
      "Label": "App"
    }
}
```

### Login Enterprise Tuning

```
 {
  "PerformancePenalty": 3.0,
  "BucketSizeInMinutes": 5,
  "NumSamplesForBaseline": 5,
  "CapacityRollingAverageSize": 3,
  "MaxBaselineForCapacity": 4000,
  "CapacityTrigger": "<80%",
  "SteadyStateCooldownWindow": 5,
  "BaselineScoreWindowSize": 5,
  "Actions": {
    "DiskMyDocs": {
      "Weight": 0,
      "NominalValue": 8500,
      "CapacityTrigger": "<25%"
    },
    "DiskMyDocsLatency": {
      "Weight": 0,
      "NominalValue": 1200,
      "CapacityTrigger": "<5%"
    },
    "DiskAppData": {
      "Weight": 0,
      "NominalValue": 14000,
      "CapacityTrigger": "<25%"
    },
    "DiskAppDataLatency": {
      "Weight": 0,
      "NominalValue": 1700,
      "CapacityTrigger": "<5%"
    },
    "CpuSpeed": {
      "Weight": 0,
      "NominalValue": 50000,
      "CapacityTrigger": "<55%"
    },
    "HighCompression": {
      "Weight": 1,
      "NominalValue": 2500,
      "CapacityTrigger": "<5%"
    },
    "FastCompression": {
      "Weight": 1,
      "NominalValue": 2500,
      "CapacityTrigger": "<5%"
    },
    "AppSpeed": {
      "Weight": 6,
      "NominalValue": 2500,
      "CapacityTrigger": "<45%"
    },
    "AppSpeedUserInput": {
      "Weight": 1,
      "NominalValue": 500,
      "CapacityTrigger": "<35%"
    }
  }
}
```

## About the Authors
**Jarian Gibson** is a senior staff solutions architect on the End-User Computing Engineering team at Nutanix. Follow Jarian on Twitter @JarianGibson.
**Sven Huisman** is a senior staff solutions architect on the End-User Computing Engineering team at Nutanix. Follow Sven on Twitter @SvenH.
**Dave Brett** is a senior solutions architect on the End-User Computing Engineering team at Nutanix. Follow Dave on Twitter @dbretty.
