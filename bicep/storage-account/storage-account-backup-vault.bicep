param name string
param storageAccountName string
param containerName string
param assetsContainerName string
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
  scope: resourceGroup()
}

resource backupVault 'Microsoft.DataProtection/backupVaults@2022-09-01-preview' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    storageSettings: [
      {
        datastoreType: 'VaultStore'
        type: 'LocallyRedundant'
      }
    ]
    securitySettings: {
      softDeleteSettings: {
        state: 'Off'
      }
    }
  }
}

resource policy 'Microsoft.DataProtection/backupVaults/backupPolicies@2022-09-01-preview' = {
  parent: backupVault
  name: 'storage-account-backup-policy'
  properties: {
    objectType: 'BackupPolicy'
    datasourceTypes: [
        'Microsoft.Storage/storageAccounts/blobServices'
    ]
    policyRules: [
      {
        name: 'Default'
        objectType: 'AzureRetentionRule'
        isDefault: true
        lifecycles: [
          {
            deleteAfter: {
                objectType: 'AbsoluteDeleteOption'
                duration: 'P365D'
            }
            targetDataStoreCopySettings: []
            sourceDataStore: {
                dataStoreType: 'VaultStore'
                objectType: 'DataStoreInfoBase'
            }
          }
        ]
      }
      {
        name: 'BackupMonthly'
        objectType: 'AzureBackupRule'
        backupParameters: {
          objectType: 'AzureBackupParams'
          backupType: 'Discrete'
        }
        trigger: {
          objectType: 'ScheduleBasedTriggerContext'
          schedule: {
            repeatingTimeIntervals: [
                // This does not seem to function without a "start" date, so we place an arbitrary one here
                'R/2023-07-01T00:00:00+00:00/P1M'
            ]
            timeZone: 'UTC'
          }
          taggingCriteria: [
            {
              tagInfo: {
                  tagName: 'Default'
              }
              taggingPriority: 99
              isDefault: true
            }
          ]
        }
        dataStore: {
          dataStoreType: 'VaultStore'
          objectType: 'DataStoreInfoBase'
        }
      }
    ]
  }
}

// Built-in role definition for Storage Account Backup Contributor. We get this definition so that we 
// can assign it to the Backup Vault on the Storage Account, allowing it to perform its backups.
resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: 'e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1' 
}
resource backupVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(resourceGroup().id, roleDefinition.id)
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: backupVault.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource instance 'Microsoft.DataProtection/backupVaults/backupInstances@2023-01-01' = {
  parent: backupVault
  name: 'storage-account-backup-instance'
  dependsOn: [backupVaultRoleAssignment]
  properties: {
    friendlyName: 'storage-account-backup-instance'
    objectType: 'BackupInstance'
    dataSourceInfo: {
      resourceName: storageAccount.name
      resourceID: storageAccount.id
      objectType: 'Datasource'
      resourceLocation: location
      datasourceType: 'Microsoft.Storage/storageAccounts/blobServices'
    }
    policyInfo: {
      policyId: policy.id
      policyParameters: {
        backupDatasourceParametersList: [
          {
            containersList: [
              containerName
              assetsContainerName
            ]
            objectType: 'BlobBackupDatasourceParameters'
          }
        ]
      }
    }
  }
}
