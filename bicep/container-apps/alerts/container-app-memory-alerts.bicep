param containerAppName string
param generalMetricAlertsActionGroupName string

param threshold int = 80 // RAM usage threshold percentage
param timeAggregation string = 'Average'
param alertTimeWindow string = 'PT5M' // 5 minutes

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: generalMetricAlertsActionGroupName
}
resource containerApp 'Microsoft.App/containerApps@2024-03-01' existing = {
  name: containerAppName
}

resource alert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${containerAppName}-memory-alert'
  location: 'Global'
  properties: {
    description: 'Alert when average memory usage reaches 80% for at least 5 minutes'
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
          name: 'MemoryPercentage'
          metricName: 'MemoryPercentage'
          timeAggregation: timeAggregation
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
