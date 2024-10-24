param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppName string
param imageName string
param environmentVariables array
param containerRegistryName string
param containerRegistryConfiguration object
param customDomains array
param cpuCores string
param memory string
param useProbes bool
param minReplicas int
param maxReplicas int

@secure()
param databasePasswordSecret object
@secure()
param containerRegistryPasswordSecret object
@secure()
param storageAccountKeySecret object

// Optional Portal Engine provisioning
param provisionForPortalEngine bool
param portalEnginePublicBuildStorageMountName string
@secure()
param portalEngineStorageAccountKeySecret object

// Optional scaling rules
param provisionCronScaleRule bool
param cronScaleRuleDesiredReplicas int
param cronScaleRuleStartSchedule string
param cronScaleRuleEndSchedule string
param cronScaleRuleTimezone string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerAppsEnvironmentName
}
var containerAppsEnvironmentId = containerAppsEnvironment.id

resource certificates 'Microsoft.App/managedEnvironments/managedCertificates@2022-11-01-preview' existing = [for customDomain in customDomains: {
  parent: containerAppsEnvironment
  name: customDomain.certificateName
}]

// Secrets
var defaultSecrets = [databasePasswordSecret, containerRegistryPasswordSecret, storageAccountKeySecret]
var portalEngineSecrets = provisionForPortalEngine ? [portalEngineStorageAccountKeySecret] : []
var secrets = concat(defaultSecrets, portalEngineSecrets)

// Volume mounts
module portalEngineVolumeMounts './portal-engine/container-app-portal-engine-volume-mounts.bicep' = if (provisionForPortalEngine) {
  name: 'portal-engine-volume-mounts'
  params: {
    portalEnginePublicBuildStorageMountName: portalEnginePublicBuildStorageMountName
  }
}
var defaultVolumes = []
var portalEngineVolume = provisionForPortalEngine ? [portalEngineVolumeMounts.outputs.portalEngineVolume] : []
var volumes = concat(defaultVolumes, portalEngineVolume)
var defaultVolumeMounts = []
var portalEngineVolumeMount = provisionForPortalEngine ? [portalEngineVolumeMounts.outputs.portalEngineVolumeMount] : []
var volumeMounts = concat(defaultVolumeMounts, portalEngineVolumeMount)

module scaleRules './scale-rules/container-app-scale-rules.bicep' = {
  name: 'container-app-scale-rules'
  params: {
    provisionCronScaleRule: provisionCronScaleRule
    cronScaleRuleTimezone: cronScaleRuleTimezone
    cronScaleRuleStartSchedule: cronScaleRuleStartSchedule
    cronScaleRuleEndSchedule: cronScaleRuleEndSchedule
    cronScaleRuleDesiredReplicas: cronScaleRuleDesiredReplicas
  }
}

resource phpContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
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
        targetPort: 80
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
          volumeMounts: volumeMounts
        }
      ]
      volumes: volumes
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: scaleRules.outputs.scaleRules
      }
    }
  }
}
