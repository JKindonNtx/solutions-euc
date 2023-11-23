Taskworker actions:
        {
    "diskappdata": {
      "App": "diskspeed",
      "Arguments": "folder=\"{appData}\" blockSize=512k bufferSize=32K writeMask=0x5555 cachePct=97 latencyPct=99 threads=1 duration=250",
      "Label": "LocalAppdata"
    },
    "cpuspeed": {
      "App": "cpuspeed",
      "Arguments": "d=250 t=2",
      "Label": "CPU"
    },
    "highcompression": {
      "App": "compressionspeed",
      "Arguments": "folder=\"{appData}\" cachePct=97 writePct=100 duration=250 threads=1 -high",
      "Label": "Compression"
    },
    "appspeed": {
      "App": "appspeed",
      "Arguments": "folder=\"{appData}\" duration=10000 launchtimestamp={launchTimestamp} -cache",
      "Label": "App"
    }
}

Taskworker Tuning:
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
      "NominalValue": 25000,
      "CapacityTrigger": "<55%"
    },
    "HighCompression": {
      "Weight": 1,
      "NominalValue": 2000,
      "CapacityTrigger": "<5%"
    },
    "AppSpeed": {
      "Weight": 6,
      "NominalValue": 2700,
      "CapacityTrigger": "<45%"
    },
    "AppSpeedUserInput": {
      "Weight": 1,
      "NominalValue": 500,
      "CapacityTrigger": "<35%"
    }
  }
}

Knowledgeworker Actions:

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

Knowledgeworker Tuning:

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
      "NominalValue": 2000,
      "CapacityTrigger": "<5%"
    },
    "FastCompression": {
      "Weight": 1,
      "NominalValue": 2000,
      "CapacityTrigger": "<5%"
    },
    "AppSpeed": {
      "Weight": 6,
      "NominalValue": 2700,
      "CapacityTrigger": "<45%"
    },
    "AppSpeedUserInput": {
      "Weight": 1,
      "NominalValue": 500,
      "CapacityTrigger": "<35%"
    }
  }
}