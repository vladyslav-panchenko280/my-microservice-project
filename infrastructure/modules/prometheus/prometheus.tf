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


  values = [
    file("${path.module}/../../../charts/prometheus/values.yaml")
  ]


  values = var.values_file != "" ? [
    file("${path.module}/../../../charts/prometheus/${var.values_file}")
  ] : []


  dynamic "set" {
    for_each = var.set_values
    content {
      name  = set.key
      value = set.value
    }
  }

  set {
    name  = "environment"
    value = var.environment
  }

  set {
    name  = "namespace"
    value = var.namespace
  }


  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = var.storage_class
  }


  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  timeout       = 600
  wait          = true
  reset_values  = false
  force_update  = false
  recreate_pods = false

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}
