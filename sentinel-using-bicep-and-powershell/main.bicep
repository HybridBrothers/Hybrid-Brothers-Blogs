//--------------------
// Parameters
//--------------------
@description('Resource group name where the Sentinel workspace resides')
param resourceGroupName string

@description('Log analytics worksapce of Sentinel')
param workspaceName string


//--------------------
// Variables
//--------------------
var ootbRules = loadJsonContent('deployments/analytic-rules.json').resources
var overwriteRules = loadJsonContent('deployments/overwrite-rules.json').resources

//--------------------
// TragetScope
//--------------------
targetScope = 'subscription'


//--------------------
// Code
//--------------------
// Get existing resource group
resource sentinelResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroupName
}

// Deploy analytic rules
module deployOOTBRules 'deploy-rules.bicep' = {
  scope: sentinelResourceGroup
  name: 'deployOOTBRules'
  params: {
    workspaceName: workspaceName
    rules: ootbRules
  }
}

// Deploy overwrite rules
module deployOverwriteRules 'deploy-rules.bicep' = {
  scope: sentinelResourceGroup
  name: 'deployOverwriteRules'
  dependsOn: [ deployOOTBRules ]
  params: {
    workspaceName: workspaceName
    rules: overwriteRules
  }
}
