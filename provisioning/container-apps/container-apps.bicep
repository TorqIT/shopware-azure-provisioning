param location string = resourceGroup().location

param containerAppsEnvironmentName string

param virtualNetworkName string
param virtualNetworkSubnetName string

param databaseServerName string
param isDatabaseIncludedInVirtualNetwork bool = true

param containerRegistryName string

param storageAccountName string
param storageAccountContainerName string

param phpFpmContainerAppName string
param phpFpmImageName string
param supervisordContainerAppName string
param supervisordImageName string
param redisContainerAppName string
param redisImageName string

// Environment variables for PHP-FPM and supervisord containers
param appDebug string
param appEnv string
param databaseName string
@secure()
param databasePassword string
param databaseUser string
param pimcoreDev string
param pimcoreEnvironment string
param redisDb string
param redisHost string
param redisSessionDb string

var subnetId = resourceId('Microsoft.Network/VirtualNetworks/subnets', virtualNetworkName, virtualNetworkSubnetName)

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: containerAppsEnvironmentName
  location: location
  properties: {
    vnetConfiguration: {
      internal: false
      infrastructureSubnetId: subnetId
    }
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryName
  scope: resourceGroup()
}
var containerRegistryPasswordSecret = {
  name: 'container-registry-password'
  value: containerRegistry.listCredentials().passwords[0].value
}
var containerRegistryConfiguration = {
  server: '${containerRegistryName}.azurecr.io'
  username: containerRegistry.listCredentials().username
  passwordSecretRef: 'container-registry-password'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
  scope: resourceGroup()
}
var storageAccountKeySecret = {
  name: 'storage-account-key'
  value: storageAccount.listKeys().keys[0].value  
}

var databasePasswordSecret = {
  name: 'database-password'
  value: databasePassword
}

var databaseHost = '${databaseServerName}.mysql.database.azure.com'

// Common environment variable configuration shared by the PHP-FPM and supervisord containers
var environmentVariables = [
  {
    name: 'APP_DEBUG'
    value: appDebug
  }
  {
    name: 'APP_ENV'
    value: appEnv
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_CONTAINER'
    value: storageAccountContainerName
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_KEY'
    secretRef: 'storage-account-key'
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_NAME'
    value: storageAccountName
  }
  {
    name: 'DATABASE_HOST'
    value: databaseHost
  }
  {
    name: 'DATABASE_NAME'
    value: databaseName
  }
  {
    name: 'DATABASE_PASSWORD'
    secretRef: 'database-password'
  }
  {
    name: 'DATABASE_USER'
    value: databaseUser
  }
  {
    name: 'PIMCORE_DEV'
    value: pimcoreDev
  }
  {
    name: 'PIMCORE_ENVIRONMENT'
    value: pimcoreEnvironment
  }
  {
    name: 'REDIS_DB'
    value: redisDb
  }
  {
    name: 'REDIS_HOST'
    value: redisHost
  }
  {
    name: 'REDIS_SESSION_DB'
    value: redisSessionDb
  }
]

resource phpFpmContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: phpFpmContainerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Multiple'
      secrets: [
        containerRegistryPasswordSecret
        databasePasswordSecret
        storageAccountKeySecret
      ]
      registries: [
        containerRegistryConfiguration
      ]
      ingress: {
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
          name: phpFpmImageName
          image: '${containerRegistryName}.azurecr.io/${phpFpmImageName}:latest'
          env: environmentVariables
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          // TODO readiness probe
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

resource supervisordContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: supervisordContainerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: [
        containerRegistryPasswordSecret
        databasePasswordSecret
        storageAccountKeySecret
      ]
      registries: [
        containerRegistryConfiguration
      ]
    }
    template: {
      containers: [
        {
          name: supervisordImageName
          image: '${containerRegistryName}.azurecr.io/${supervisordImageName}:latest'
          env: environmentVariables
          // TODO readiness probe?
          resources: {
            cpu: 1
            memory: '2Gi'
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

// TODO TCP transport is not yet supported for Container Apps, so leaving this commented out for now. See
// container-apps.sh where we instead use the CLI command instead.
// resource redisContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
//   name: redisContainerAppName
//   location: location
//   properties: {
//     managedEnvironmentId: containerAppsEnvironment.id
//     configuration: {
//       activeRevisionsMode: 'Single'
//       secrets: [
//         containerRegistryPasswordSecret
//       ]
//       registries: [
//         containerRegistryConfiguration
//       ]
//       ingress: {
//         targetPort: 6379
//         external: false
//         transport: 'Tcp'
//         exposedPort: 6379
//       }
//     }
//     template: {
//       containers: [
//         {
//           name: redisImageName
//           image: '${containerRegistryName}.azurecr.io/${redisImageName}:latest'
//           resources: {
//             cpu: 1
//             memory: '2Gi'
//           }
//         }
//       ]
//       scale: {
//         minReplicas: 1
//         maxReplicas: 1 
//       }
//     }
//   }
// }
