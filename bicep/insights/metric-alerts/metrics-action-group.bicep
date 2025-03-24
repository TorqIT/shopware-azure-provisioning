param name string
param shortName string
param emailReceivers array

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: name
  location: 'Global'
  properties: {
    groupShortName: shortName
    enabled: true
    emailReceivers: [for emailReceiver in emailReceivers: {
        name: emailReceiver
        emailAddress: emailReceiver
      }
    ]
  }
}
