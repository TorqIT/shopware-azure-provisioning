@secure()
param pimcoreEnterpriseTokenSecret object
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
var enterpriseVolume = !empty(pimcoreEnterpriseTokenSecret) ? [{
  storageType: 'Secret'
  name: 'pimcore-enterprise-token'
  secrets: [
    {
      path: '/run/secrets/pimcore-enterprise-token'
      secretRef: 'pimcore-enterprise-token'
    }
  ]
}] : []
output volumes array = concat(defaultVolumes, portalEngineVolume, enterpriseVolume)

// Volume mounts
var defaultVolumeMounts = []
var portalEngineVolumeMount = provisionForPortalEngine ? [portalEngineVolumeMounts.outputs.portalEngineVolumeMount] : []
var enterpriseVolumeMount = !empty(pimcoreEnterpriseTokenSecret) ? [{
  mountPath: '/run/secrets/pimcore-enterprise-token'
  volumeName: 'pimcore-enterprise-token'
}] : []
output volumeMounts array = concat(defaultVolumeMounts, portalEngineVolumeMount, enterpriseVolumeMount)
