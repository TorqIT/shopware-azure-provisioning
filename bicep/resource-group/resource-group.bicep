targetScope = 'subscription'

param location string
param name string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  location: location
  name: name
}
