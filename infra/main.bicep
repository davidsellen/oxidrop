targetScope = 'resourceGroup'

param location string = resourceGroup().location
param appName string = 'oxidrop-dev'
param containerImage string = 'ghcr.io/davidsellen/oxidrop@sha256:dc76bd954c1e09358941227f9a8e0b9893a3587e40c683bd06f746e881506919'

@secure()
param ingestToken string

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
  }
}

resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: appName
  location: location
  properties: {
    managedEnvironmentId: environment.id
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Multiple'
      ingress: {
        external: true
        targetPort: 8080
        traffic: [
          {
            revisionName: 'oxidrop-dev--v012'
            weight: 100
          }
        ]
        allowInsecure: false
        transport: 'auto'
      }
      secrets: [
      {
        name: 'ingest-token'
        value: ingestToken
      }
    ]
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
          probes: [
            {
              type: 'Readiness'
              httpGet: {
                path: '/health'
                port: 8080
                scheme: 'HTTP'
              }
            }
          ]
          env: [
            {
              name: 'BIND_ADDRESS'
              value: '0.0.0.0:8080'
            }
            {
              name: 'RUST_LOG'
              value: 'info'
            }
            {
              name: 'INGEST_TOKEN'
              secretRef: 'ingest-token'
            }
          ]
        }
      ]
      revisionSuffix: 'v012-pinned'
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
