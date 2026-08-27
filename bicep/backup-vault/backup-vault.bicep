param location string = resourceGroup().location

param name string

resource backupVault 'Microsoft.DataProtection/backupVaults@2022-12-01' = {
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
