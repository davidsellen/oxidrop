param location string = resourceGroup().location
param sqlAdminLogin string = 'oxidropadmin'

@secure()
param sqlAdminPassword string

@minLength(1)
param oxidropOutboundIps array

resource sqlServer 'Microsoft.Sql/servers@2023-08-01' = {
  name: 'oxidrop-dev-sql-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    publicNetworkAccess: 'Enabled'
  }
}

resource oxidropFirewallRules 'Microsoft.Sql/servers/firewallRules@2023-08-01' = [
  for ip in oxidropOutboundIps: {
    parent: sqlServer
    name: 'oxidrop-${replace(ip, '.', '-')}'
    properties: {
      startIpAddress: ip
      endIpAddress: ip
    }
  }
]

resource database 'Microsoft.Sql/servers/databases@2023-08-01' = {
  parent: sqlServer
  name: 'oxidrop'
  location: location
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 2
  }
  properties: {
    minCapacity: json('0.5')
    maxSizeBytes: 34359738368
    requestedBackupStorageRedundancy: 'Local'
    useFreeLimit: true
    freeLimitExhaustionBehavior: 'AutoPause'
  }
}
