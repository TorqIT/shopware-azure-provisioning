param location string = resourceGroup().location

param profileName string
param endpointName string
param storageAccountName string
param publicContainerName string
param customDomains array
param sku string

var originHost = '${storageAccountName}.blob.${environment().suffixes.storage}'

resource frontDoorProfile 'Microsoft.Cdn/profiles@2025-06-01' = {
  name: profileName
  location: 'Global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }

  resource endpoint 'afdEndpoints' = {
    name: endpointName
    location: location
    properties: {
      enabledState: 'Enabled'
    }

    resource route 'routes' = {
      name: 'route-to-storage'
      properties: {
        originGroup: {
          id: frontDoorProfile::originGroup.id
        }
        supportedProtocols: [
          'Http'
          'Https'
        ]
        patternsToMatch: [
          '/*'
        ]
        forwardingProtocol: 'MatchRequest'
        httpsRedirect: 'Enabled'
        enabledState: 'Enabled'
      }
    }
  }

  // Child: Origin Group
  resource originGroup 'originGroups' = {
    name: 'storage-origin-group'
    properties: {
      loadBalancingSettings: {
        sampleSize: 4
        successfulSamplesRequired: 3
      }
      healthProbeSettings: {
        probePath: '/'
        probeProtocol: 'Https'
        probeRequestType: 'HEAD'
        probeIntervalInSeconds: 120
      }
      sessionAffinityState: 'Disabled'
    }

    // Child of originGroup: Origin
    resource origin 'origins' = {
      name: 'storage-origin'
      properties: {
        hostName: originHost
        httpPort: 80
        httpsPort: 443
        originHostHeader: originHost
        priority: 1
        weight: 1000
        enabledState: 'Enabled'
      }
    }
  }
}
