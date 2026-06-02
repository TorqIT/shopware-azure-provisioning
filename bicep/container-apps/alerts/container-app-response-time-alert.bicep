param containerAppName string
param generalMetricAlertsActionGroupName string

param threshold int
param alertTimeWindow string

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: generalMetricAlertsActionGroupName
}
resource containerApp 'Microsoft.App/containerApps@2024-03-01' existing = {
  name: containerAppName
}

resource alert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${containerAppName}-response-time-alert'
  location: 'Global'
  properties: {
    description: 'Alert when average request latency exceeds the configured threshold'
    severity: 2 // Warning
    enabled: true
    evaluationFrequency: 'PT1M'
    windowSize: alertTimeWindow
    scopes: [
      containerApp.id
    ]
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'ResponseTime'
          metricName: 'ResponseTime'
          timeAggregation: 'Average'
          operator: 'GreaterThan'
          threshold: threshold
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}
