param provisionHttpScaleRule bool
param provisionCronScaleRule bool
param cronScaleRuleDesiredReplicas int
param cronScaleRuleStartSchedule string
param cronScaleRuleEndSchedule string
param cronScaleRuleTimezone string
param httpScaleRuleConcurrentRequestsThreshold int

var httpScaleRule = [
  {
    name: 'default-http-scale-rule'
    http: {
      metadata: {
        concurrentRequests: string(httpScaleRuleConcurrentRequestsThreshold)
      }
    }
  }
]

module cronScaleRule './container-app-cron-scale-rule.bicep' = if (provisionCronScaleRule) {
  name: 'cron-scale-rule'
  params: {
    desiredReplicas: cronScaleRuleDesiredReplicas
    start: cronScaleRuleStartSchedule
    end: cronScaleRuleEndSchedule
    timezone: cronScaleRuleTimezone
  }
}

var scaleRules = concat(
  provisionHttpScaleRule ? httpScaleRule : [],
  provisionCronScaleRule ? [cronScaleRule.outputs.cronScaleRule] : []
)

output scaleRules array = scaleRules
