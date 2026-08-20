param databaseServerName string
param generalActionGroupName string
param criticalActionGroupName string

resource criticalActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: criticalActionGroupName
}
resource databaseServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01-preview' existing = {
  name: databaseServerName
}

resource cpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${databaseServerName}-95-cpu-alert'
  location: 'Global'
  properties: {
    description: 'Alert when average CPU usage reaches 95% for at least 5 minutes'
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

resource unavailableAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${databaseServerName}-unavailable-alert'
  location: 'Global'
  properties: {
    description: 'Alert when the database reports unavailable (is_db_alive = 0) for at least 1 minute, e.g. due to an unplanned restart'
    severity: 0 // Critical
    enabled: true
    evaluationFrequency: 'PT1M'
    windowSize: 'PT1M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'DbAlive'
          metricName: 'is_db_alive'
          timeAggregation: 'Minimum'
          operator: 'LessThan'
          threshold: 1
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
