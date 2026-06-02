param containerAppName string
param generalMetricAlertsActionGroupName string
param responseTimeAlertThreshold int
param responseTimeAlertTimeWindow string

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

module responseTimeAlert './container-app-response-time-alert.bicep' = {
  name: '${containerAppName}-response-time-alert'
  params: {
    containerAppName: containerAppName
    generalMetricAlertsActionGroupName: generalMetricAlertsActionGroupName
    threshold: responseTimeAlertThreshold
    alertTimeWindow: responseTimeAlertTimeWindow
  }
}
