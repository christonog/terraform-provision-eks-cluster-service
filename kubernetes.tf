provider "kubernetes" {
  load_config_file       = "false"
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

resource "kubernetes_service" "exercise" {
  for_each = { for service in var.services : service.name => service }
  metadata {
    name = each.key
  }
  spec {
    selector = {
      app = each.key
    }
    port {
      name = "tcp-${each.key}"
      protocol = "TCP"
      port        = each.value.port
      target_port = each.value.port
    }

    type = "NodePort"
  }
}

resource "kubernetes_deployment" "exercise" {
  for_each = { for service in var.services : service.name => service }

  metadata {
    name = each.key
    labels = {
      app = each.key
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = each.key
      }
    }
    template {
      metadata {
        labels = {
          app = each.key
        }
      }
      spec {
        container {
          image = "christonog/christ-services:${each.key}v1.0.0"
          name  = each.key
          }
      }
    }
  }
}

variable "services" {
  type = set(object( { name = string, port = number }))
  default = [
    { name: "books", port: 3001 },
    { name: "reviews", port: 3002 }
  ]
}