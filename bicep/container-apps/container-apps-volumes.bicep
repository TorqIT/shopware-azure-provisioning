param additionalVolumesAndMounts array

// Volumes
var defaultVolumes = []
var secretsVolume = [{
  storageType: 'Secret'
  name: 'secrets'
}]
var additionalVolumes = [for volumeAndMount in additionalVolumesAndMounts: {
  storageType: 'NfsAzureFile'
  name: volumeAndMount.volumeName
  storageName: volumeAndMount.volumeName
  mountOptions: volumeAndMount.?mountOptions ?? 'uid=1000,gid=1000'
}]
output volumes array = concat(defaultVolumes, secretsVolume, additionalVolumes)

// Volume mounts
var defaultVolumeMounts = []
var secretsVolumeMount = [{
  volumeName: 'secrets'
  mountPath: '/run/secrets'
}]
var additionalVolumeMounts = [for volumeAndMount in additionalVolumesAndMounts: {
  volumeName: volumeAndMount.volumeName
  mountPath: volumeAndMount.mountPath
}]
output volumeMounts array = concat(defaultVolumeMounts, secretsVolumeMount, additionalVolumeMounts)
