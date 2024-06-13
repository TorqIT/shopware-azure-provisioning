param location string = resourceGroup().location

param backupVaultName string
param databaseServerName string

resource database 'Microsoft.DBforMySQL/flexibleServers@2024-02-01-preview' existing = {
  name: databaseServerName
}

resource backupVault 'Microsoft.DataProtection/backupVaults@2024-04-01' existing = {
  name: backupVaultName
}

resource policy 'Microsoft.DataProtection/backupVaults/backupPolicies@2024-04-01' = {
  parent: backupVault
  name: 'database-backup-policy'
  properties: {
    objectType: 'BackupPolicy'
    datasourceTypes: [
        'Microsoft.DBforMySQL/flexibleServers'
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
        name: 'BackupWeekly'
        objectType: 'AzureBackupRule'
        backupParameters: {
          objectType: 'AzureBackupParams'
          backupType: 'Full'
        }
        trigger: {
          objectType: 'ScheduleBasedTriggerContext'
          schedule: {
            repeatingTimeIntervals: [
                // This does not seem to function without a "start" date, so we place an arbitrary one here
                'R/2024-07-01T00:00:00+00:00/P1W'
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

// Built-in role definition for Backup Contributor. We get this definition so that we 
// can assign it to the Backup Vault on the database, allowing it to perform its backups.
resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: '5e467623-bb1f-42f4-a55d-6e525e11384b'
}
resource backupVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: database
  name: guid(resourceGroup().id, roleDefinition.id)
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: backupVault.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource instance 'Microsoft.DataProtection/backupVaults/backupInstances@2024-04-01' = {
  parent: backupVault
  name: 'database-backup-instance'
  dependsOn: [backupVaultRoleAssignment]
  properties: {
    friendlyName: 'database-backup-instance'
    objectType: 'BackupInstance'
    dataSourceInfo: {
      resourceName: database.name
      resourceID: database.id
      objectType: 'Datasource'
      resourceLocation: location
      datasourceType: 'Microsoft.DBforMySQL/flexibleServers'
    }
    policyInfo: {
      policyId: policy.id
    }
  }
}
