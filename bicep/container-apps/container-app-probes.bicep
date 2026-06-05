param provisionStartupProbe bool
param startupProbePath string
param startupProbeInitialDelaySeconds int
param startupProbePeriodSeconds int
param startupProbeFailureThreshold int

param provisionLivenessProbe bool
param livenessProbePath string
param livenessProbeInitialDelaySeconds int
param livenessProbePeriodSeconds int
param livenessProbeFailureThreshold int

param provisionReadinessProbe bool
param readinessProbePath string
param readinessProbeInitialDelaySeconds int
param readinessProbePeriodSeconds int
param readinessProbeFailureThreshold int

param probePort int

var startupProbe = provisionStartupProbe ? [
  {
    type: 'Startup'
    httpGet: {
      scheme: 'HTTP'
      port: probePort
      path: startupProbePath
    }
    initialDelaySeconds: startupProbeInitialDelaySeconds
    periodSeconds: startupProbePeriodSeconds
    failureThreshold: startupProbeFailureThreshold
  }
] : []

var livenessProbe = provisionLivenessProbe ? [
  {
    type: 'Liveness'
    httpGet: {
      scheme: 'HTTP'
      port: probePort
      path: livenessProbePath
    }
    initialDelaySeconds: livenessProbeInitialDelaySeconds
    periodSeconds: livenessProbePeriodSeconds
    failureThreshold: livenessProbeFailureThreshold
  }
] : []

var readinessProbe = provisionReadinessProbe ? [
  {
    type: 'Readiness'
    httpGet: {
      scheme: 'HTTP'
      port: probePort
      path: readinessProbePath
    }
    initialDelaySeconds: readinessProbeInitialDelaySeconds
    periodSeconds: readinessProbePeriodSeconds
    failureThreshold: readinessProbeFailureThreshold
  }
] : []

output probes array = concat(startupProbe, livenessProbe, readinessProbe)
