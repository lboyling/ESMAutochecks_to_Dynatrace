# ESMAutochecks_to_Dynatrace

This is a basic PowerShell script that can be used to take HTTP AutoChecks from Dynatrace Enterprise Synthetic Monitoring (ESM), and create synthetic monitors in Dynatrace SaaS/Managed

## Prerequisites
1. An XML export of the AutoChecks from your ESM environment:
  * Open the ESM Console, and select File -> Export Data
  * Select Monitoring type = Automated check, and click Browse
  * Select the save location and file name (.xml) and click Save. Click Preview
  * Confirm that the autochecks are listed, and click Export
  * The window will close, and your
2. Your Dynatrace SaaS or Managed tenant URL
3. An API token in Dynatrace SaaS or Managed with the following permissions:
  * Access problem and event feed, metrics and topology permission
  * Create and read synthetic monitors, locations, and nodes
4. A pre-existing JSON payload for the synthetic monitor you want to create.
  * You can create this yourself via the Dynatrace API Explorer
  * Or you can specify an existing synthetic monitor entityId when the script is run, to have the script automatically pull the current synthetic monitor configuration
  
## Configuring the script
At the top of the script are variables for the Dynatrace tenant ID, the API token, and location of the Autocheck XML.

## Running the script

```./ESM_Autochecks_To_Dynatrace.ps1```

For each autocheck in the autocheck XML, create a Dynatrace synthetic monitor using the JSON template hard-coded in the script.

```./ESM_Autochecks_To_Dynatrace.ps1 -entityId <Synthetic entityId>```

For each autocheck in the autocheck XML, create a Dynatrace synthetic monitor using the existing synthetic monitor with the supplied entityId as the template.

```./ESM_Autochecks_To_Dynatrace.ps1 -AgentID <ESM Robot AgentID>```

For each autocheck in the autocheck XML with the specified Agent ID, create a Dynatrace synthetic monitor using the JSON template hard-coded in the script.


## Output
For each successfully created synthetic monitor, the entityID of the new monitor is output
```
New synthetic monitor created - entityId=SYNTHETIC_TEST-0123456789ABCDEF
New synthetic monitor created - entityId=SYNTHETIC_TEST-FEDCBA9876543210
```
