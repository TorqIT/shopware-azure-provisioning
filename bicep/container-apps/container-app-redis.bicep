param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppName string
param cpuCores string
@description('Sets the required memory for the Container App')
param memory string
@description('Sets the maxmemory setting on the redis-server binary')
param maxMemorySetting string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerAppsEnvironmentName
}
var containerAppsEnvironmentId = containerAppsEnvironment.id

resource redisContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        targetPort: 6379
        external: false
        transport: 'Tcp'
        exposedPort: 6379
      }
    }
    template: {
      containers: [
        {
          name: 'redis'
          image: 'docker.io/redis:alpine'
          command: [
            'redis-server'
            '--maxmemory ${maxMemorySetting}'
            '--maxmemory-policy volatile-lru'
            '--save ""'
          ]
          resources: {
            cpu: json(cpuCores)
            memory: memory
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1 
      }
    }
  }
}
