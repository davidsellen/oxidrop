using './main.bicep'

param ingestToken = readEnvironmentVariable('OXIDROP_DEPLOY_TOKEN')
param containerImage = 'ghcr.io/davidsellen/oxidrop@sha256:2e2ce218dd48e23fefce284aa2a93c2b3a2e7c2e04ac757aa45a9207839f4471'
param revisionSuffix = 'v014'
