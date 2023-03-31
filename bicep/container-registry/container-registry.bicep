param location string = resourceGroup().location

@minLength(5)
@maxLength(50)
param containerRegistryName string
param sku string

resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true
  }
}
