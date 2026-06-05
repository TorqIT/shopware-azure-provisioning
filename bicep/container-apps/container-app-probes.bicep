param provisionStartupProbe bool
param startupProbePath string

param provisionLivenessProbe bool
param livenessProbePath string

param provisionReadinessProbe bool
param readinessProbePath string

param probePort int

var startupProbe = provisionStartupProbe ? [
  {
    type: 'Startup'
    httpGet: {
      port: probePort
      path: startupProbePath
    }
  }
] : []

var livenessProbe = provisionLivenessProbe ? [
  {
    type: 'Liveness'
    httpGet: {
      port: probePort
      path: livenessProbePath
    }
  }
] : []

var readinessProbe = provisionReadinessProbe ? [
  {
    type: 'Readiness'
    httpGet: {
      port: probePort
      path: readinessProbePath
    }
  }
] : []

output probes array = concat(startupProbe, livenessProbe, readinessProbe)
