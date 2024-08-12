param location string = resourceGroup().location

param storageAccountName string
param storageAccountFileShareName string

param containerAppsEnvironmentName string
param containerAppsEnvironmentStorageMountName string
param volumeName string

param containerAppName string
param cpuCores string
param memory string
param minReplicas int
param maxReplicas int
param customDomains array

param databaseServerName string
param databaseName string
param databaseUser string
@secure()
param databasePassword string

param provisionCronScaleRule bool
param cronScaleRuleDesiredReplicas int
param cronScaleRuleStartSchedule string
param cronScaleRuleEndSchedule string
param cronScaleRuleTimezone string

resource database 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01-preview' existing = {
  name: databaseServerName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-11-02-preview' existing = {
  name: containerAppsEnvironmentName
}

resource storageMount 'Microsoft.App/managedEnvironments/storages@2023-11-02-preview' = {
  parent: containerAppsEnvironment
  name: containerAppsEnvironmentStorageMountName
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccount.listKeys().keys[0].value
      shareName: storageAccountFileShareName
      accessMode: 'ReadWrite'
    }
  }
}

resource certificates 'Microsoft.App/managedEnvironments/managedCertificates@2022-11-01-preview' existing = [for customDomain in customDomains: {
  parent: containerAppsEnvironment
  name: customDomain.certificateName
}]

var databasePasswordSecret = {
  name: 'database-password'
  value: databasePassword
}

var defaultScaleRules = []
module cronScaleRule './scale-rules/container-app-cron-scale-rule.bicep' = if (provisionCronScaleRule) {
  name: 'cron-scale-rule'
  params: {
    desiredReplicas: cronScaleRuleDesiredReplicas
    start: cronScaleRuleStartSchedule
    end: cronScaleRuleEndSchedule
    timezone: cronScaleRuleTimezone
  }
}
var scaleRules = concat(
  defaultScaleRules, 
  provisionCronScaleRule ? [cronScaleRule.outputs.cronScaleRule] : []
)

resource n8nContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  dependsOn: [storageMount]
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        allowInsecure: false
        targetPort: 5678
        customDomains: [for i in range(0, length(customDomains)): {
            name: customDomains[i].domainName
            bindingType: 'SniEnabled'
            certificateId: certificates[i].id
        }]
      }
      secrets: [databasePasswordSecret]
    }
    template: {
      containers: [
        {
          name: 'n8n'
          image: 'n8nio/n8n:latest'
          resources: {
            cpu: json(cpuCores)
            memory: memory
          }
          env: [
            {
              name: 'DB_TYPE'
              value: 'postgresdb'
            }
            {
              name: 'DB_POSTGRESDB_DATABASE'
              value: databaseName
            }
            {
              name: 'DB_POSTGRESDB_HOST'
              value: database.properties.fullyQualifiedDomainName
            }
            {
              name: 'DB_POSTGRESDB_PORT'
              value: '5432'
            }
            {
              name: 'DB_POSTGRESDB_USER'
              value: databaseUser
            }
            {
              name: 'DB_POSTGRESDB_PASSWORD'
              secretRef: 'database-password'
            }
            {
              name: 'DB_POSTGRESDB_SCHEMA'
              value: 'public'
            }
          ]
          volumeMounts: [
            {
              mountPath: '/home/node/.n8n'
              volumeName: volumeName
            }
          ]
        }
      ]
      volumes: [
        {
          name: volumeName
          storageName: containerAppsEnvironmentStorageMountName
          storageType: 'AzureFile'
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: scaleRules
      }
    }
  }
}
