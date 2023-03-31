param location string = resourceGroup().location

param containerAppsEnvironmentId string
param containerAppName string
param imageName string
param environmentVariables array
param containerRegistryName string
param containerRegistryConfiguration object
param useProbes bool
@secure()
param databasePasswordSecret object
@secure()
param containerRegistryPasswordSecret object
@secure()
param storageAccountKeySecret object

resource phpFpmContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'Multiple'
      secrets: [databasePasswordSecret, containerRegistryPasswordSecret, storageAccountKeySecret]
      registries: [
        containerRegistryConfiguration
      ]
      ingress: {
        // Slightly confusing - when we want to restrict access to this container to within the VNet, 
        // the environment can be set to be internal within the VNet, but the webapp itself
        // still needs to be declared external here. Declaring it internal here would limit it to within the Container
        // Apps Environment, which is not what we want.
        external: true
        allowInsecure: false
        targetPort: 80
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
    }
    template: {
      containers: [
        {
          name: imageName
          image: '${containerRegistryName}.azurecr.io/${imageName}:latest'
          env: environmentVariables
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          probes: useProbes ? [
            { 
              type: 'Startup'
              httpGet: {
                port: 80
                path: '/'
              }
            }
            { 
              type: 'Liveness'
              httpGet: {
                port: 80
                path: '/'
              }
            }
          ]: []
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
               concurrentRequests: '30'
              }
            }
          }
        ]
      }
    }
  }
}
