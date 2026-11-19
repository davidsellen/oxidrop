targetScope = 'resourceGroup'

param location string = resourceGroup().location
param appName string = 'oxidrop-dev'
param containerImage string = 'ghcr.io/davidsellen/oxidrop:0.1.0'

resource environment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: '${appName}-env'
  location: location
  properties: {
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    appLogsConfiguration: {
      destination: 'none'
    }
  }
}

resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: appName
  location: location
  properties: {
    managedEnvironmentId: environment.id
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: false
        targetPort: 8080
        allowInsecure: false
        transport: 'auto'
      }
    }
    template: {
      containers: [
        {
          name: 'oxidrop'
          image: containerImage
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'BIND_ADDRESS'
              value: '0.0.0.0:8080'
            }
            {
              name: 'RUST_LOG'
              value: 'info'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
        rules: [
          {
            name: 'http'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

output appName string = app.name
output appHost string = app.properties.configuration.ingress.fqdn
