param provisionCronScaleRule bool
param cronScaleRuleDesiredReplicas int
param cronScaleRuleStartSchedule string
param cronScaleRuleEndSchedule string
param cronScaleRuleTimezone string

var defaultScaleRules = []

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
  defaultScaleRules, 
  provisionCronScaleRule ? [cronScaleRule.outputs.cronScaleRule] : []
)

output scaleRules array = scaleRules
