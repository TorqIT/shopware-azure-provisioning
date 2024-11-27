// Volumes
var defaultVolumes = []
var secretsVolume = [{
  storageType: 'Secret'
  name: 'secrets'
}]
output volumes array = concat(defaultVolumes, secretsVolume)

// Volume mounts
var defaultVolumeMounts = []
var secretsVolumeMount = [{
  volumeName: 'secrets'
  mountPath: '/run/secrets'
}]
output volumeMounts array = concat(defaultVolumeMounts, secretsVolumeMount)
