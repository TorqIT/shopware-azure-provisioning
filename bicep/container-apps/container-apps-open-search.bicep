param location string = resourceGroup().location

param containerAppsEnvironmentId string
param containerAppName string
param cpuCores string
param memory string

resource openSearchContainerApp 'Microsoft.App/containerApps@2023-05-02-preview' = {
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
          name: 'open-search'
          image: 'opensearchproject/opensearch:2'
          env: [
            {
              name: 'DISABLE_SECURITY_PLUGIN'
              value: 'true'
            }
            {
              name: 'discovery.type'
              value: 'single-node'
            }
            {
              name: 'OPENSEARCH_JAVA_OPTS'
              value: '-Xms512m -Xmx512m'
            }
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
