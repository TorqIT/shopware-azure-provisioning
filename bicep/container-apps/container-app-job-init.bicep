param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppJobName string
param imageName string
param cpuCores string
param memory string
param replicaTimeoutSeconds int

// Environment variables shared with the PHP and supervisord Container Apps
param defaultEnvVars array

param containerRegistryName string
param containerRegistryConfiguration object

param databaseServerName string
param databaseUser string
param databaseName string

// Whether to run the pimcore-install command when this job runs. 
// This should only be set to true on first deployment and set to false on all subsequent deploys.
param runPimcoreInstall bool

@secure()
param databasePasswordSecret object
@secure()
param containerRegistryPasswordSecret object
@secure()
param storageAccountKeySecret object
@secure()
param pimcoreAdminPassword string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-11-01-preview' existing = {
  name: containerAppsEnvironmentName
  scope: resourceGroup()
}
var containerAppsEnvironmentId = containerAppsEnvironment.id

resource database 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' existing = {
  name: databaseServerName
}

var adminPasswordSecret = {
  name: 'admin-psswd'
  value: pimcoreAdminPassword
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

resource containerAppJob 'Microsoft.App/jobs@2023-05-02-preview' = {
  location: location
  name: containerAppJobName
  properties: {
    environmentId: containerAppsEnvironmentId
    configuration: {
      replicaTimeout: replicaTimeoutSeconds
      secrets: [containerRegistryPasswordSecret, databasePasswordSecret, storageAccountKeySecret, adminPasswordSecret]
      triggerType: 'Manual'
      eventTriggerConfig: {
        scale: {
          minExecutions: 0
          maxExecutions: 1
        }
      }
      registries: [
        containerRegistryConfiguration
      ]
    }
    template: {
      containers: [
        {
          image: '${containerRegistryName}.azurecr.io/${imageName}:latest'
          env: concat(defaultEnvVars, initEnvVars)
          name: imageName
          resources: {
            cpu: json(cpuCores)
            memory: memory
          }
        }
      ]
    }
  }
}
