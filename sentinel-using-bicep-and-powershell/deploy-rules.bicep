//--------------------
// Parameters
//--------------------
param workspaceName string
param rules array

//--------------------
// Code
//--------------------
// Get the existing la
resource sentinelWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

// Deploy rules
resource analyticRuleDeployment 'Microsoft.SecurityInsights/alertRules@2022-10-01-preview' = [for rule in rules: {
  name: rule.name
  scope: sentinelWorkspace
  kind: rule.kind
  properties: rule.properties
}]
