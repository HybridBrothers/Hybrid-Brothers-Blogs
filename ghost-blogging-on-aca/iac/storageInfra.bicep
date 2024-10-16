
//--------------------
// Parameters
//--------------------
param location string
param environment string
param application string
param acaConfig object
param virtualNetworkId string?
param subnetId string?

//--------------------
// Targetscope
//--------------------
targetScope = 'resourceGroup'

//--------------------
// Variables
//--------------------
var storageAccountFileURL = 'privatelink.file.${az.environment().suffixes.storage}'
var privateEndpoint = (empty(virtualNetworkId) || empty(subnetId)) ? false : true

//--------------------
// Storage infra
//--------------------

// Storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: acaConfig.storageAccountName
  tags: {
    'hidden-title': 'st-${application}-${environment}-${location}-001'
  }
  location: location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    publicNetworkAccess: (privateEndpoint) ? 'Disabled' : 'Enabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

// Storage account private endpoint
resource privateStorageAccountEndpoint 'Microsoft.Network/privateEndpoints@2023-06-01' = if (privateEndpoint) {
  name: 'pep-${application}storage-${environment}-${location}-001'
  location: location
  properties:{
    subnet: empty(subnetId) ? null : {
      id: subnetId
    }
    customNetworkInterfaceName: 'nic-${application}storage-${environment}-${location}-001'
    privateLinkServiceConnections:[{
      name: 'pl-file-${environment}-${location}-001'
      properties:{
        privateLinkServiceId: storageAccount.id
        groupIds: [
          'file'
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

// Storage account file private dns zone
resource privateStorageAccountFileDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (privateEndpoint) {
  name: storageAccountFileURL
  location: 'global'
}

// Storage account file private dns zone virtual network link
resource privateStorageAccountFileDNSZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (privateEndpoint) {
  name: 'vnl-storageaccountfile-${application}-${environment}-${location}-001'
  location: 'global'
  parent: privateStorageAccountFileDNSZone
  properties:{
    registrationEnabled: false
    virtualNetwork: empty(virtualNetworkId) ? null : {
      id: virtualNetworkId
    }
  }
}

// Storage account private dns zone group
resource privateStorageAccountDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = if (privateEndpoint) {
  name: 'default'
  parent: privateStorageAccountEndpoint
  properties:{
    privateDnsZoneConfigs:[
      {
        name: storageAccountFileURL
        properties:{
          privateDnsZoneId: privateStorageAccountFileDNSZone.id
        }
      }
    ]
  }
}

// File service
resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}
// File share
resource websiteContentShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: 'websitecontent'
  parent: fileService
  properties: {
    accessTier: 'TransactionOptimized'
    shareQuota: 5120
    enabledProtocols: 'SMB'
  }
} 
var storageAccountKey = storageAccount.listKeys().keys[0].value
output storageAccountKey string = storageAccountKey
output storageAccountName string = storageAccount.name
output websiteContentShareName string = websiteContentShare.name
