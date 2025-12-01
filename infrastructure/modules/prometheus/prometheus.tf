resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace

    labels = {
      name        = var.namespace
      environment = var.environment
    }
  }
}

resource "helm_release" "prometheus" {
  name       = var.release_name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = concat(
    [
      file("${path.module}/../../../charts/prometheus/values.yaml")
    ],
    var.values_file != "" ? [
      file("${path.module}/../../../charts/prometheus/${var.values_file}")
    ] : [],
    [
      yamlencode({
        environment = var.environment
        namespace   = var.namespace
        prometheus = {
          prometheusSpec = {
            storageSpec = {
              volumeClaimTemplate = {
                spec = {
                  storageClassName = var.storage_class
                }
              }
            }
          }
        }
      })
    ]
  )

  timeout       = 600
  wait          = true
  reset_values  = false
  force_update  = false
  recreate_pods = false

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}
