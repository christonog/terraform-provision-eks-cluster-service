provider "kubernetes" {
  load_config_file       = "false"
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

locals {
  namespace = "bookapp"
}

resource "kubernetes_namespace" "exercise" {
  metadata {
    labels = {
     istio-injection = "enabled"
    }

    name = local.namespace
  }
  depends_on = ["null_resource.istio"]
}

resource "kubernetes_service" "exercise" {
  for_each = { for service in var.services : service.name => service }
  metadata {
    name = each.key
    namespace = local.namespace
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
  depends_on = ["kubernetes_namespace.exercise"]
}

resource "kubernetes_deployment" "exercise" {
  for_each = { for service in var.services : service.name => service }

  metadata {
    name = each.key
    labels = {
      app = each.key
    }
    namespace = local.namespace
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
          image = "christonog/${each.key}:1.0"
          name  = each.key
          }
      }
    }
  }
  depends_on = ["kubernetes_namespace.exercise"]
}

variable "services" {
  type = set(object( { name = string, port = number }))
  default = [
    { name: "books", port: 3000 },
    { name: "reviews", port: 3002 }
  ]
}