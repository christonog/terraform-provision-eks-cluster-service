resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
  depends_on = ["module.eks"]
}

resource "null_resource" "set-kube-config" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${local.cluster_name}"
  }
  depends_on = ["module.eks"]
}

resource "local_file" "istio-config" {
  content = templatefile("${path.module}/istio.tmpl", {
    enableGrafana = false
    enableKiali   = false
    enableTracing = false
  })
  filename = "istio.yaml"
}

# Need istioctl 1.7.3 on machine running this
resource "null_resource" "istio" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "istioctl install --set-profile=demo"
  }
  depends_on = [kubernetes_namespace.istio_system, null_resource.set-kube-config]
}