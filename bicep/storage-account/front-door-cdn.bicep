param location string = resourceGroup().location

param profileName string
param endpointName string
param storageAccountName string
param publicContainerName string
param customDomains array
param sku string

resource frontDoorProfile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: profileName
  location: 'Global'
  sku: {
    name: sku
  }
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/endpoints@2021-06-01' = {
  parent: frontDoorProfile
  name: endpointName
  location: location
  properties: {
    origins: [
      {
        name: 'storage-origin'
        properties: {
          hostName: '${storageAccountName}.blob.${environment().suffixes.storage}'
          httpPort: 80
          httpsPort: 443
          originHostHeader: '${storageAccountName}.blob.${environment().suffixes.storage}'
          priority: 1
          weight: 1000
          enabled: true
        }
      }
    ]
    originGroups: [
      {
        name: 'storage-origin-group'
        properties: {
          origins: [
            {
              id: resourceId('Microsoft.Cdn/profiles/endpoints/origins', profileName, endpointName, 'storage-origin')
            }
          ]
          healthProbeSettings: {
            probePath: '/${publicContainerName}/'
            probeRequestType: 'GET'
            probeProtocol: 'Https'
            probeIntervalInSeconds: 120
          }
        }
      }
    ]
    isHttpAllowed: false
    isHttpsAllowed: true
  }
}

resource frontDoorCustomDomain 'Microsoft.Cdn/profiles/customDomains@2021-06-01' = [for domain in customDomains: {
  name: domain
  parent: frontDoorProfile
  properties: {
    hostName: domain
  }
  dependsOn: [
    frontDoorEndpoint
  ]
}]
