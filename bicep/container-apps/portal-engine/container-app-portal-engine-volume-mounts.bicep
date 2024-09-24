param portalEnginePublicBuildStorageMountName string

output portalEngineVolume object = {
  name: 'portal-engine-public-build'
  storageName: portalEnginePublicBuildStorageMountName
  storageType: 'AzureFile'
}
output portalEngineVolumeMount object = {
  volumeName: 'portal-engine-public-build'
  mountPath: '/var/www/html/public/portal-engine/build'
}
