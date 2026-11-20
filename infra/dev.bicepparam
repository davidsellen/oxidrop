using './main.bicep'

param ingestToken = readEnvironmentVariable('OXIDROP_DEPLOY_TOKEN')
param containerImage = 'ghcr.io/davidsellen/oxidrop@sha256:dc76bd954c1e09358941227f9a8e0b9893a3587e40c683bd06f746e881506919'
param revisionSuffix = 'v012-pinned'
