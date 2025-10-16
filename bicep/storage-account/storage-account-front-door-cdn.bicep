param location string = resourceGroup().location

param frontDoorProfileName string
param endpointName string
param storageAccountName string
param storageAccountPublicContainerName string

param ipRules array

resource frontDoorProfile 'Microsoft.Cdn/profiles@2025-06-01' = {
  name: frontDoorProfileName
  location: 'global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2025-06-01' = {
  name: endpointName
  parent: frontDoorProfile
  location: location
}

// TODO custom domains

var storageAccountOriginHostName = '${storageAccountName}.blob.${environment().suffixes.storage}'
resource storageAccountOriginGroup 'Microsoft.Cdn/profiles/originGroups@2025-06-01' = {
  name: 'storage-account'
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
  }
}
resource storageAccountOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2025-06-01' = {
  name: 'storage-account'
  parent: storageAccountOriginGroup
  properties: {
    hostName: storageAccountOriginHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: storageAccountOriginHostName
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource cdnRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2025-06-01' = {
  name: 'cdn'
  parent: endpoint
  dependsOn: [
    storageAccountOrigin
  ]
  properties: {
    originGroup: {
      id: storageAccountOriginGroup.id
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
    linkToDefaultDomain: 'Enabled'
  }
}

resource cdnSecurityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2025-06-01' = {
  name: 'cdn-security-policy'
  parent: frontDoorProfile
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: cdnWafPolicy.id
      }
      associations: [
        {
          domains: [
            {
              id: endpoint.id
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }
      ]
    }
  }
}

var ipAllowances = map(filter(ipRules, ipRule => ipRule.action == 'Allow'), ipRule => ipRule.ipAddressRange)
resource cdnWafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2025-03-01' = if (!empty(ipAllowances)) {
  name: 'cdnWafPolicy'
  location: location
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
  properties: {
    customRules: {
      rules: [
        // IP rule allowances
        {
          name: 'ipAllowances'
          ruleType: 'MatchRule'
          priority: 100
          matchConditions: [
            {
              operator: 'IPMatch'
              matchVariable: 'SocketAddr'
              matchValue: ipAllowances
            }
          ]
          action: 'Allow'
        }
        // Catch all rule to block everything else
        {
          name: 'catchAllBlock'
          priority: 200
          ruleType: 'MatchRule'
          matchConditions: [
            {
              operator: 'IPMatch'
              matchVariable: 'SocketAddr'
              matchValue: [
                '0.0.0.0/0'
                '::/0'
              ]
            }
          ]
          action: 'Block'
        }
      ]
    }
  }
}
