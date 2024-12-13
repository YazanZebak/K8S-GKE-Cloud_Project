resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "grafana-dashboards"
    namespace = "monitoring"
  }

  data = {
    "node-dashboard.json" = file("${path.module}/grafana-dashboards/node-dashboard.json")
    "pod-dashboard.json"  = file("${path.module}/grafana-dashboards/pod-dashboard.json")
    "dashboards.yaml"     = file("${path.module}/grafana-dashboards/dashboards.yaml")
  }
}

resource "kubernetes_deployment" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "grafana"
      }
    }

    template {
      metadata {
        labels = {
          app = "grafana"
        }
      }

      spec {
        container {
          name  = "grafana"
          image = "grafana/grafana:9.4.7"

          env {
            name  = "GF_SECURITY_ADMIN_PASSWORD"
            value = "admin"
          }

          volume_mount {
            name       = "dashboards-volume"
            mount_path = "/var/lib/grafana/dashboards"
          }

          port {
            container_port = 3000
          }
        }

        volume {
          name = "dashboards-volume"

          config_map {
            name = kubernetes_config_map.grafana_dashboards.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    selector = {
      app = "grafana"
    }

    port {
      port        = 3000
      target_port = 3000
    }
  }
}
