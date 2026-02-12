resource "kubernetes_network_policy_v1" "allow_envoy_gateway" {
  for_each = var.managed_namespaces

  metadata {
    name      = "allow-envoy-gateway"
    namespace = each.key
  }

  spec {
    pod_selector {}

    policy_types = [
      "Ingress",
      "Egress"
    ]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "envoy-gateway"
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = 80
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "envoy-gateway"
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = 80
      }
    }
  }

  depends_on = [
    azapi_resource.managed_namespace
  ]
}
