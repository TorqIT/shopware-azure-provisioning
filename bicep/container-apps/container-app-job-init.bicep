param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppJobName string
param imageName string
param cpuCores string
param memory string
param replicaTimeoutSeconds int

// Environment variables shared with the PHP and supervisord Container Apps
param defaultEnvVars array

param additionalSecrets array

param additionalVolumesAndMounts array

param containerRegistryName string

param databaseServerName string
param databaseUser string
param databaseName string

param keyVaultName string

// Whether to run the pimcore-install command when this job runs. 
// This should only be set to true on first deployment and set to false on all subsequent deploys.
param runPimcoreInstall bool

@secure()
param storageAccountKeySecret object

param databasePasswordSecret object
param pimcoreAdminPasswordSecretName string

param managedIdentityId string

// Optional Portal Engine provisioning
param provisionForPortalEngine bool
param portalEnginePublicBuildStorageMountName string
@secure()
param portalEngineStorageAccountKeySecret object

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-11-01-preview' existing = {
  name: containerAppsEnvironmentName
}
resource database 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' existing = {
  name: databaseServerName
}

// Secrets
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}
resource pimcoreAdminPasswordInKeyVault 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' existing = {
  parent: keyVault
  name: pimcoreAdminPasswordSecretName
}
var adminPasswordSecret = {
  name: 'admin-psswd'
  keyVaultUrl: pimcoreAdminPasswordInKeyVault.properties.secretUri
  identity: managedIdentityId
}
var defaultSecrets = [databasePasswordSecret, storageAccountKeySecret, adminPasswordSecret]
var portalEngineSecrets = provisionForPortalEngine ? [portalEngineStorageAccountKeySecret] : []
var secrets = concat(defaultSecrets, additionalSecrets, portalEngineSecrets)

module volumesModule './container-apps-volumes.bicep' = {
  name: 'container-app-job-init-volumes'
  params: {
    provisionForPortalEngine: provisionForPortalEngine
    portalEnginePublicBuildStorageMountName: portalEnginePublicBuildStorageMountName
    additionalVolumesAndMounts: additionalVolumesAndMounts
  }
}

var initEnvVars = [
  {
    name: 'PIMCORE_INSTALL'
    value: runPimcoreInstall ? 'true' : 'false'
  }
  {
    name: 'PIMCORE_INSTALL_MYSQL_HOST_SOCKET'
    value: database.properties.fullyQualifiedDomainName
  }
  {
    name: 'PIMCORE_INSTALL_MYSQL_PORT'
    value: '3306'
  }
  {
    name: 'PIMCORE_INSTALL_MYSQL_USERNAME'
    value: databaseUser
  }
  {
    name: 'PIMCORE_INSTALL_MYSQL_PASSWORD'
    secretRef: 'database-password' 
  }
  {
    name: 'PIMCORE_INSTALL_MYSQL_DATABASE'
    value: databaseName
  }
  {
    name: 'PIMCORE_INSTALL_MYSQL_SSL_CERT_PATH'
    value: '/var/www/html/config/db/DigiCertGlobalRootCA.crt.pem'
  }
  {
    name: 'PIMCORE_INSTALL_ADMIN_USERNAME'
    value: 'admin'
  }
  {
    name: 'PIMCORE_INSTALL_ADMIN_PASSWORD'
    secretRef: 'admin-psswd'
  }
]
var envVars = concat(defaultEnvVars, initEnvVars)

resource containerAppJob 'Microsoft.App/jobs@2023-05-02-preview' = {
  location: location
  name: containerAppJobName
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      replicaTimeout: replicaTimeoutSeconds
      secrets: secrets
      triggerType: 'Manual'
      eventTriggerConfig: {
        scale: {
          minExecutions: 0
          maxExecutions: 1
        }
      }
      registries: [
        {
          identity: managedIdentityId
          server: '${containerRegistryName}.azurecr.io'
        }
      ]
    }
    template: {
      containers: [
        {
          image: '${containerRegistryName}.azurecr.io/${imageName}:latest'
          env: envVars
          name: imageName
          resources: {
            cpu: json(cpuCores)
            memory: memory
          }
          volumeMounts: volumesModule.outputs.volumeMounts
        }
      ]
      volumes: volumesModule.outputs.volumes
    }
  }
}
