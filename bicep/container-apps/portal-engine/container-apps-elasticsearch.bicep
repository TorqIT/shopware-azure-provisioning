param location string = resourceGroup().location

param containerAppsEnvironmentId string
param containerAppName string
param nodeName string
param cpuCores string
param memory string

resource elasticsearchContainerApp 'Microsoft.App/containerApps@2023-05-02-preview' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        targetPort: 9200
        external: false
        transport: 'tcp'
        exposedPort: 9200
      }
    }
    template: {
      containers: [
        {
          name: 'elasticsearch'
          image: 'docker.elastic.co/elasticsearch/elasticsearch:8.10.2'
          env: [
            {
              name: 'node.name'
              value: nodeName
            }
            {
              name: 'xpack.security.enabled'
              value: 'false'
            }
            {
              name: 'discovery.type'
              value: 'single-node'
            }
            {
              name: 'ES_JAVA_OPTS'
              value: '-Xms512m -Xmx512m'
            }
          ]
          resources: {
            cpu: cpuCores
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
