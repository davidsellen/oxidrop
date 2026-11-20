using './main.bicep'

param ingestToken = readEnvironmentVariable('OXIDROP_DEPLOY_TOKEN')
param containerImage = 'ghcr.io/davidsellen/oxidrop@sha256:ead0981b2b6b26ab0278da53ea8aa734ab3c323fe3a702f3589b455e010ff09c'
param revisionSuffix = 'v013'
