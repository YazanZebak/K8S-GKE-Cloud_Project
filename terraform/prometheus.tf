provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "prometheus.yml" = <<YAML
      global:
        scrape_interval: 15s
      scrape_configs:
        - job_name: 'kubernetes-nodes'
          static_configs:
            - targets: ['node-exporter.monitoring.svc.cluster.local:9100']

        - job_name: 'kubernetes-pods'
          static_configs:
            - targets: ['cadvisor.monitoring.svc.cluster.local:8080']
    YAML
  }
}

resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }

      spec {
        container {
          name  = "prometheus"
          image = "prom/prometheus:v2.37.1"

          volume_mount {
            name       = "config-volume"
            mount_path = "/etc/prometheus/"
          }

          port {
            container_port = 9090
          }
        }

        volume {
          name = "config-volume"

          config_map {
            name = kubernetes_config_map.prometheus_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    selector = {
      app = "prometheus"
    }

    port {
      port        = 9090
      target_port = 9090
    }
  }
}

resource "kubernetes_deployment" "node_exporter" {
  metadata {
    name      = "node-exporter"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "node-exporter"
      }
    }

    template {
      metadata {
        labels = {
          app = "node-exporter"
        }
      }

      spec {
        container {
          name  = "node-exporter"
          image = "quay.io/prometheus/node-exporter:v1.5.0"

          port {
            container_port = 9100
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "node_exporter" {
  metadata {
    name      = "node-exporter"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    selector = {
      app = "node-exporter"
    }

    port {
      port        = 9100
      target_port = 9100
    }
  }
}

resource "kubernetes_deployment" "cadvisor" {
  metadata {
    name      = "cadvisor"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "cadvisor"
      }
    }

    template {
      metadata {
        labels = {
          app = "cadvisor"
        }
      }

      spec {
        container {
          name  = "cadvisor"
          image = "gcr.io/cadvisor/cadvisor:v0.47.0"

          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "cadvisor" {
  metadata {
    name      = "cadvisor"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    selector = {
      app = "cadvisor"
    }

    port {
      port        = 8080
      target_port = 8080
    }
  }
}
