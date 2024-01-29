//--------------------
// Parameters
//--------------------
param location string
param environment string
param application string
param storageAccountName string
param websiteContentShareName string
param virtualNetworkId string?
param subnetId string?

//--------------------
// Targetscope
//--------------------
targetScope = 'resourceGroup'

//--------------------
// Variables
//--------------------
var backupURL = 'privatelink.we.backup.windowsazure.com'
var privateEndpoint = (empty(virtualNetworkId) || empty(subnetId)) ? false : true

//--------------------
// Backup infra
//--------------------

// Recovery services vault for storage acount backup
resource recoveryServiceVault 'Microsoft.RecoveryServices/vaults@2023-06-01' = {
  name: 'rsv-${application}-${environment}-${location}-001'
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties:{
    publicNetworkAccess: 'Enabled'
    securitySettings:{
      immutabilitySettings:{
        state: 'Disabled'
      }
    }
  }
}

// Recovery services vault private endpoint
resource privateRecoveryServiceVaultEndpoint 'Microsoft.Network/privateEndpoints@2023-06-01' = if (privateEndpoint)  {
  name: 'pep-${application}backup-${environment}-${location}-001'
  location: location
  properties:{
    subnet: {
      id: subnetId
    }
    customNetworkInterfaceName: 'nic-${application}backup-${environment}-${location}-001'
    privateLinkServiceConnections:[{
      name: 'pl-backup-${environment}-${location}-001'
      properties:{
        privateLinkServiceId: recoveryServiceVault.id
        groupIds: [
          'AzureBackup'
        ]
        privateLinkServiceConnectionState: {
          status: 'Approved'
          description: 'Auto-Approved'
          actionsRequired: 'None'
        }
      }
    }]
  }
}

// Recovery services vault private dns zone
resource privateRecoveryServiceVaultDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (privateEndpoint) {
  name: backupURL
  location: 'global'
}

// Recovery services vault private dns zone virtual network link
resource privateRecoveryServiceVaultDNSZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (privateEndpoint) {
  name: 'vnl-backup-${application}-${environment}-${location}-001'
  location: 'global'
  parent: privateRecoveryServiceVaultDNSZone
  properties:{
    registrationEnabled: false
    virtualNetwork:{
      id: virtualNetworkId
    }
  }
}

// Recovery services vault private dns zone group
resource privateRecoveryServiceVaultDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = if (privateEndpoint) {
  name: 'default'
  parent: privateRecoveryServiceVaultEndpoint
  properties:{
    privateDnsZoneConfigs:[
      {
        name: backupURL
        properties:{
          privateDnsZoneId: privateRecoveryServiceVaultDNSZone.id
        }
      }
    ]
  }
}

// Reference existing storageaccount
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// Reference existing fileshare
resource websiteContentShare 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' existing = {
  parent: storageAccount
  name: websiteContentShareName
}

// Recovery services vault backup policy
resource storageAccountBackupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-06-01' = {
  name: 'bkpol-${application}backup-${environment}-${location}-001'
  parent: recoveryServiceVault
  properties:{
    backupManagementType: 'AzureStorage'
    workLoadType: 'AzureFileShare'
    timeZone: 'Romance Standard Time'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        '2020-01-01T19:30:00.000Z'
      ]
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
        retentionTimes:[
          '2020-01-01T19:30:00.000Z'
        ]
      }
    }
  }
}

// Recovery services vault protectionContainer
resource storageAccountProtectionContainer 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers@2023-06-01' = {
  #disable-next-line use-parent-property
  name: '${recoveryServiceVault.name}/Azure/storagecontainer;Storage;${resourceGroup().name};${storageAccount.name}'
  properties: {
    backupManagementType: 'AzureStorage'
    containerType: 'StorageContainer'
    sourceResourceId: storageAccount.id
  }
}

// Recovery services vault protectedItem
resource storageAccountProtectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2023-06-01' = {
  name: 'AzureFileShare;${websiteContentShare.name}'
  parent: storageAccountProtectionContainer
  properties: {
    protectedItemType: 'AzureFileShareProtectedItem'
    sourceResourceId: storageAccount.id
    policyId: storageAccountBackupPolicy.id
  }
  dependsOn:[
    recoveryServiceVault
  ]
}
