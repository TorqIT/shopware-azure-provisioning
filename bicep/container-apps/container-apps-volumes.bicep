param provisionForPortalEngine bool
param portalEnginePublicBuildStorageMountName string

// Volumes
module portalEngineVolumeMounts './portal-engine/container-app-portal-engine-volume-mounts.bicep' = if (provisionForPortalEngine) {
  name: 'portal-engine-volume-mounts'
  params: {
    portalEnginePublicBuildStorageMountName: portalEnginePublicBuildStorageMountName
  }
}
var defaultVolumes = []
var portalEngineVolume = provisionForPortalEngine ? [portalEngineVolumeMounts.outputs.portalEngineVolume] : []
var secretsVolume = [{
  storageType: 'Secret'
  name: 'secrets'
}]
output volumes array = concat(defaultVolumes, secretsVolume, portalEngineVolume)

// Volume mounts
var defaultVolumeMounts = []
var secretsVolumeMount = [{
  volumeName: 'secrets'
  mountPath: '/run/secrets'
}]
var portalEngineVolumeMount = provisionForPortalEngine ? [portalEngineVolumeMounts.outputs.portalEngineVolumeMount] : []
output volumeMounts array = concat(defaultVolumeMounts, secretsVolumeMount, portalEngineVolumeMount)
