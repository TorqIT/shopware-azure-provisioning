param containerAppName string
param generalMetricAlertsActionGroupName string

module memoryAlerts './container-app-memory-alerts.bicep' = {
  name: '${containerAppName}-memory-alerts'
  params: {
    containerAppName: containerAppName
    generalMetricAlertsActionGroupName: generalMetricAlertsActionGroupName
  }
}
module replicaRestartAlerts './container-app-restarts-alerts.bicep' = {
  name: '${containerAppName}-restarts-alerts'
  params: {
    containerAppName: containerAppName
    generalMetricAlertsActionGroupName: generalMetricAlertsActionGroupName
  }
}
