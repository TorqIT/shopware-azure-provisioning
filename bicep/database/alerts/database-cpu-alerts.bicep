param databaseServerName string
param generalActionGroupName string
param criticalActionGroupName string

resource generalActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: generalActionGroupName
}
resource criticalActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: criticalActionGroupName
}
resource databaseServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' existing = {
  name: databaseServerName
}

resource eightyPercentAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${databaseServerName}-80-cpu-alert'
  location: 'Global'
  properties: {
    description: 'Alert when average CPU usage exceeds 80% or for at least 5 minutes'
    severity: 2 // Warning
    enabled: true
    evaluationFrequency: 'PT1M' 
    windowSize: 'PT5M' 
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'CPUUsage'
          metricName: 'cpu_percent'
          timeAggregation: 'Average'
          operator: 'GreaterThan'
          threshold: 80
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    scopes: [
      databaseServer.id
    ]
    actions: [
      {
        actionGroupId: generalActionGroup.id
      }
    ]
  }
}

resource oneHundredPercentAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${databaseServerName}-95-cpu-alert'
  location: 'Global'
  properties: {
    description: 'Alert when average CPU usage reaches 95% or for at least 5 minutes'
    severity: 1 // Error
    enabled: true
    evaluationFrequency: 'PT1M' 
    windowSize: 'PT5M' 
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'CPUUsage'
          metricName: 'cpu_percent'
          timeAggregation: 'Average'
          operator: 'GreaterThanOrEqual'
          threshold: 95
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    scopes: [
      databaseServer.id
    ]
    actions: [
      {
        actionGroupId: criticalActionGroup.id
      }
    ]
  }
}
