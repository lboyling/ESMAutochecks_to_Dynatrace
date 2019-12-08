[CmdletBinding()]
param (
    # Optionally, provide the entityId of an existing synthetic monitor that will be used as a template for creating new monitors. If not provided, use the hard-coded JSON.
    [String] $entityId = "",
    # Option Agent ID - Used to only upload the tests run from a specific ESM Robot and prevent duplicates for tests run from multiple
    [String] $AgentID
)
# Add your full Dynatrace tenant address here
# https://*tenantid*.live.dynatrace.com for Dynatrace SaaS
# https://dynatracemanagedurl/e/*environment_id* for DynatraceManaged
$Dynatrace_Tenant = "" 

#Add your API token here - requires the following permissions:
#1. Access problem and event feed, metrics and topology permission
#2. Create and read synthetic monitors, locations, and nodes
$API_Token = "" 

#Path to XML file containing autochecks (File -> Export data from Enterprise Synthetic Console)
$Autochecks_Path = ""

$Synthetic_API = "$Dynatrace_Tenant/api/v1/synthetic/monitors"

$GET_Headers = @{ 
    Authorization = "Api-Token $API_Token" ;
    Accept = "application/json"
}
$POST_headers = @{ 
    Authorization = "Api-Token $API_Token" ;
    Accept = "application/json";
    "Content-Type" = "application/json"
}
# Set TLS 1.2 as Security Protocols - Powershell doesn't do this by default :(
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try
{
    
    if($entityId -ne "")
    {
        #Get JSON payload of existing monitor
        $Existing_Monitor = Invoke-RestMethod -Uri "$Synthetic_API/$entityId" -Headers $GET_Headers -Method GET
    }
    else
    {
        #Just get list of monitors to confirm that the environment is accessible
        $Monitors = Invoke-RestMethod -Uri "$Synthetic_API" -Headers $GET_Headers -Method GET
    }
}
catch
{
    Write-Output "There was an error when trying to get the list of synthetic monitors: $_"
    exit
}

#Example POST /synthetic/monitors JSON - customise to your own requirements
$New_Monitor_JSON = '{
  "entityId": "SYNTHETIC_TEST-0000000000000000",
  "name": "Google Health Check",
  "frequencyMin": 60,
  "enabled": false,
  "type": "BROWSER",
  "createdFrom": "GUI",
  "script": {
    "type": "availability",
    "version": "1.0",
    "configuration": {
      "device": {
        "deviceName": "Desktop",
        "orientation": "landscape"
      }
    },
    "events": [
      {
        "type": "navigate",
        "description": "Loading of https://google.com",
        "url": "https://google.com",
        "wait": {
          "waitFor": "page_complete"
        }
      }
    ]
  },
  "locations": [
    "GEOLOCATION-2FD31C834DE4D601"
  ],
  "anomalyDetection": {
    "outageHandling": {
      "globalOutage": true,
      "localOutage": false,
      "localOutagePolicy": {
        "affectedLocations": 1,
        "consecutiveRuns": 3
      }
    },
    "loadingTimeThresholds": {
      "enabled": false,
      "thresholds": []
    }
  },
  "tags": [
    {
      "context": "CONTEXTLESS",
      "key": "Google"
    }
  ],
  "managementZones": [],
  "automaticallyAssignedApps": [],
  "manuallyAssignedApps": [],
  "keyPerformanceMetrics": {
    "loadActionKpm": "VISUALLY_COMPLETE",
    "xhrActionKpm": "VISUALLY_COMPLETE"
  },
  "events": [
    {
      "entityId": "SYNTHETIC_TEST_STEP-59572FEEB94B1932",
      "name": "Loading of https://google.com",
      "sequenceNumber": 1
    }
  ]
}'

if($entityId -ne "")
{
    $New_Monitor = $Existing_Monitor
}
else
{
    $New_Monitor = ConvertFrom-Json -InputObject $New_Monitor_JSON
}


[xml]$Autochecks = Get-Content -Path $Autochecks_Path

# Handle the AgentID param
if ($script:AgentID) {
  $autocheckdata = $Autochecks.CVBulkInsert.ACCollection | Where-Object -Property AgentId -EQ -Value $script:AgentID
} else {
  $autocheckdata = $Autochecks.CVBulkInsert.ACCollection 
}

foreach($autocheck in $autocheckdata)
{
    #Provide name, description, url, etc. from attributes of the autocheck
    $New_Monitor.name = $autocheck.TransactionName
    $New_Monitor.script.events[0].description = $autocheck.TaskName
    $New_Monitor.script.events[0].url = $autocheck.AC0_URL

    #Remove fields from GET request that can't be sent in a POST request
    $New_Monitor.automaticallyAssignedApps = $null
    $New_Monitor.entityId = $null
    $New_Monitor.events = $null


    #Tags array needs to be converted to just a string array (stripping the "CONTEXTLESS" part)
    $New_Monitor.tags = @()
    $New_Monitor.tags += $autocheck.ApplicationName

    #Convert and compress JSON payload
    $JSONPayload = $New_Monitor | ConvertTo-Json -Depth 8 -Compress
    try
    {
        $monitor_entityId = Invoke-RestMethod -Uri $Synthetic_API -Headers $POST_headers -Method POST -Body $JSONPayload
        Write-Output "New synthetic monitor created - entityId = $($monitor_entityId.entityId)"
    }
    catch
    {
        Write-Output "There was an error when trying to create the $($New_Monitor.name) monitor: $_"
        continue
    }
}
