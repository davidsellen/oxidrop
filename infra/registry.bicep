targetScope = 'resourceGroup'

@description('Azure region for the registry.')
param location string = resourceGroup().location

@description('Globally unique container registry name.')
param registryName string = 'oxidrop${uniqueString(resourceGroup().id)}'

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

output acrName string = registry.name
output loginServer string = registry.properties.loginServer
