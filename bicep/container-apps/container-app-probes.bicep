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
param probeScheme string

var isTcp = probeScheme == 'TCP'
var tcpSocketConfig = { tcpSocket: { port: probePort } }
var startupHttpConfig = { httpGet: { scheme: probeScheme, port: probePort, path: startupProbePath } }
var livenessHttpConfig = { httpGet: { scheme: probeScheme, port: probePort, path: livenessProbePath } }
var readinessHttpConfig = { httpGet: { scheme: probeScheme, port: probePort, path: readinessProbePath } }

var startupProbe = provisionStartupProbe ? [
  union(
    {
      type: 'Startup'
      initialDelaySeconds: startupProbeInitialDelaySeconds
      periodSeconds: startupProbePeriodSeconds
      failureThreshold: startupProbeFailureThreshold
    },
    isTcp ? tcpSocketConfig : startupHttpConfig
  )
] : []

var livenessProbe = provisionLivenessProbe ? [
  union(
    {
      type: 'Liveness'
      initialDelaySeconds: livenessProbeInitialDelaySeconds
      periodSeconds: livenessProbePeriodSeconds
      failureThreshold: livenessProbeFailureThreshold
    },
    isTcp ? tcpSocketConfig : livenessHttpConfig
  )
] : []

var readinessProbe = provisionReadinessProbe ? [
  union(
    {
      type: 'Readiness'
      initialDelaySeconds: readinessProbeInitialDelaySeconds
      periodSeconds: readinessProbePeriodSeconds
      failureThreshold: readinessProbeFailureThreshold
    },
    isTcp ? tcpSocketConfig : readinessHttpConfig
  )
] : []

output probes array = concat(startupProbe, livenessProbe, readinessProbe)
