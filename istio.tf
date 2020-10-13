resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

resource "local_file" "istio-config" {
  content = templatefile("${path.module}/istio.tmpl", {
    enableGrafana = false
    enableKiali   = false
    enableTracing = false
  })
  filename = "istio.yaml"
}

# Need istioctl 1.5.4 on machine running this
resource "null_resource" "istio" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "istioctl manifest apply -f \"istio.yaml\" --kubeconfig $(find . -type f -name \"kubeconfig_*\")"
  }
  depends_on = [kubernetes_namespace.istio_system, kubernetes_deployment.exercise]
}