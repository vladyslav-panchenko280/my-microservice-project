resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace

    labels = {
      name        = var.namespace
      environment = var.environment
    }
  }
}

resource "helm_release" "grafana" {
  name       = var.release_name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = var.chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = concat(
    [
      file("${path.module}/../../../charts/grafana/values.yaml")
    ],
    var.values_file != "" ? [
      file("${path.module}/../../../charts/grafana/${var.values_file}")
    ] : [],
    [
      yamlencode({
        environment = var.environment
        namespace   = var.namespace
        grafana = {
          adminUser     = var.grafana_admin_user
          adminPassword = var.grafana_admin_password
          persistence = {
            storageClassName = var.storage_class
          }
          datasources = {
            "datasources.yaml" = {
              datasources = [
                {
                  name      = "Prometheus"
                  type      = "prometheus"
                  url       = var.prometheus_url
                  access    = "proxy"
                  isDefault = true
                }
              ]
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
