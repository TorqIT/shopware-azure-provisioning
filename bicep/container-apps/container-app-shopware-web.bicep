param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppName string
param imageName string
param customDomains array
param cpuCores string
param memory string
param minReplicas int
param maxReplicas int
param environmentVariables array

param containerRegistryName string
param containerRegistryConfiguration object
@secure()
param containerRegistryPasswordSecret object

param databaseUrlSecret object

var internalPort = 80

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-11-01-preview' existing = {
  name: containerAppsEnvironmentName
  scope: resourceGroup()
}
var containerAppsEnvironmentId = containerAppsEnvironment.id

resource certificates 'Microsoft.App/managedEnvironments/managedCertificates@2022-11-01-preview' existing = [for customDomain in customDomains: {
  parent: containerAppsEnvironment
  name: customDomain.certificateName
}]

var secrets = [containerRegistryPasswordSecret, databaseUrlSecret]

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'Multiple'
      secrets: secrets
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
        targetPort: internalPort
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        customDomains: [for i in range(0, length(customDomains)): {
            name: customDomains[i].domainName
            bindingType: 'SniEnabled'
            certificateId: certificates[i].id
        }]
      }
    }
    template: {
      containers: [
        {
          name: imageName
          image: '${containerRegistryName}.azurecr.io/${imageName}:latest'
          env: environmentVariables
          resources: {
            cpu: json(cpuCores)
            memory: memory
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}
