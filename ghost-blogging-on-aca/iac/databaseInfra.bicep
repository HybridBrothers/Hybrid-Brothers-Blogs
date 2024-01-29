//--------------------
// Parameters
//--------------------
param location string
param environment string
param application string
param dbConfig object
@secure()
param dbPassword string
param containerAppName string
param virtualNetworkId string?
param subnetId string?

//--------------------
// Targetscope
//--------------------
targetScope = 'resourceGroup'

//--------------------
// Variables
//--------------------
var mysqlURL = 'privatelink.mysql.database.azure.com'
var privateEndpoint = (empty(virtualNetworkId) || empty(subnetId)) ? false : true

//--------------------
// Database infra
//--------------------

// MySQL flexible server 
resource mySQLServer 'Microsoft.DBforMySQL/flexibleServers@2023-06-30' = {
  name: dbConfig.serverName
  tags:{
    'hidden-title': 'mysql-${application}-${environment}-${location}-001'
  }
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties:{
    administratorLogin: dbConfig.username
    administratorLoginPassword: dbPassword
    highAvailability: {
      mode: 'Disabled'
    }
    storage: {
      storageSizeGB: 20
      iops: 360
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    network:{
      publicNetworkAccess: (privateEndpoint) ? 'Disabled' : 'Enabled'
    }
    version: '8.0.21'
  }
}

// MySQL Database
resource mySQLDatabase 'Microsoft.DBforMySQL/flexibleServers/databases@2023-06-30' =  {
  name: dbConfig.dbname
  parent: mySQLServer
}

// MySQL disable TLS
resource mySQLSSLConfig 'Microsoft.DBforMySQL/flexibleServers/configurations@2023-06-30' = {
  name: 'require_secure_transport'
  parent: mySQLServer
  properties:{
    value: 'OFF'
    source: 'user-override'
  }
}

// Reference existing containerapp
resource containerApp 'Microsoft.App/containerApps@2023-05-01' existing = {
  name: containerAppName
}

// MySQL add firewall rule
resource mySQLFirewallRule 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2023-06-30' = {
  name: 'allow-aca-outbound-ip'
  parent: mySQLServer
  properties:{
    startIpAddress: containerApp.properties.outboundIpAddresses[0]
    endIpAddress: containerApp.properties.outboundIpAddresses[0]
  }
}

// MySQL private endpoint
resource privateMySQLEndpoint 'Microsoft.Network/privateEndpoints@2023-06-01' = if (privateEndpoint) {
  name: 'pep-${application}mysql-${environment}-${location}-001'
  location: location
  properties:{
    subnet: empty(subnetId) ? null: {
      id: subnetId
    }
    customNetworkInterfaceName: 'nic-${application}mysql-${environment}-${location}-001'
    privateLinkServiceConnections:[{
      name: 'pl-mysql-${environment}-${location}-001'
      properties:{
        privateLinkServiceId: mySQLServer.id
        groupIds: [
          'mysqlServer'
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

// MySQL private dns zone
resource privateMySQLDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (privateEndpoint) {
  name: mysqlURL
  location: 'global'
}

// MySQL private dns zone virtual network link
resource privateMySQLDNSZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (privateEndpoint) {
  name: 'vnl-mysql-${application}-${environment}-${location}-001'
  location: 'global'
  parent: privateMySQLDNSZone
  properties:{
    registrationEnabled: false
    virtualNetwork: empty(virtualNetworkId) ? null : {
      id: virtualNetworkId
    }
  }
}

// MySQL private dns zone group
resource privateMySQLDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = if (privateEndpoint) {
  name: 'default'
  parent: privateMySQLEndpoint
  properties:{
    privateDnsZoneConfigs:[
      {
        name: mysqlURL
        properties:{
          privateDnsZoneId: privateMySQLDNSZone.id
        }
      }
    ]
  }
}
