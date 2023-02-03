@minLength(5)
@maxLength(50)
param containerRegistryName string = 'acr${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
param sku string = 'Basic'

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
