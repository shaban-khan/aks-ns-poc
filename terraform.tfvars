aks_name               = "aksdemo03"
aks_resource_group     = "rg-skdemo-aks-02"
managed_namespace_name = "moon"

# Azure AD Group Object ID
ns_admin_aad_group_object_id  = "0e8a217c-29a5-480d-980f-5381ccb07647"
ns_writer_aad_group_object_id = "076c7d16-1623-4252-a845-5b36b067368c"
ns_reader_aad_group_object_id = "c7734397-7757-40a6-90c9-8964494e0851"
cluster_user_aad_group_object_id = "9c0ad534-04f3-4104-9ed6-3ab8c690a1af"
# Optional (can omit to use default)
rbac_role_name  = "Azure Kubernetes Service RBAC Admin"
subscription_id = "1175a59b-96b9-40b1-816d-23b7f16e38b8"

# managed_namespaces = {
#   moon = {
#     defaultResourceQuota = {
#       cpuLimit      = "1000m"
#       cpuRequest    = "500m"
#       memoryLimit   = "2Gi"
#       memoryRequest = "1Gi"
#     }
#     defaultNetworkPolicy = {
#       ingress = "AllowSameNamespace"
#       egress  = "AllowSameNamespace"
#     }
#   }
#   sun = {
#     defaultResourceQuota = {
#       cpuLimit      = "2000m"
#       cpuRequest    = "1000m"
#       memoryLimit   = "4Gi"
#       memoryRequest = "2Gi"
#     }

#     defaultNetworkPolicy = {
#       ingress = "AllowSameNamespace"
#       egress  = "AllowSameNamespace"
#     }
#   }
# }

managed_namespaces = {
  dev = {
    labels = {
      team = "platform"
      env  = "dev"
    }
    annotations = {
      owner = "retail"
    }
    adoptionPolicy = "Always"
    deletePolicy   = "Delete"

    defaultResourceQuota = {
      cpuLimit      = "1000m"
      cpuRequest    = "500m"
      memoryLimit   = "2Gi"
      memoryRequest = "1Gi"
    }

    defaultNetworkPolicy = {
      ingress = "AllowSameNamespace"
      egress  = "AllowSameNamespace"
    }

    rbac = {
      namespace_roles = {
        # "Azure Kubernetes Service RBAC Reader" = [
        #   "c7734397-7757-40a6-90c9-8964494e0851"
        # ]
        "Azure Kubernetes Service RBAC Writer" = [
          "076c7d16-1623-4252-a845-5b36b067368c"
        ]
        "Azure Kubernetes Service RBAC Admin" = [
          "0e8a217c-29a5-480d-980f-5381ccb07647"
        ]
      }
    }
  }
  test = {
    labels = {
      team = "platform"
      env  = "test"
    }
    annotations = {
      owner = "retail"
    }
    adoptionPolicy = "Always"
    deletePolicy   = "Delete"

    defaultResourceQuota = {
      cpuLimit      = "1000m"
      cpuRequest    = "500m"
      memoryLimit   = "2Gi"
      memoryRequest = "1Gi"
    }

    defaultNetworkPolicy = {
      ingress = "AllowSameNamespace"
      egress  = "AllowSameNamespace"
    }

    rbac = {
      namespace_roles = {
        # "Azure Kubernetes Service RBAC Reader" = [
        #   "c7734397-7757-40a6-90c9-8964494e0851"
        # ]
        # "Azure Kubernetes Service RBAC Writer" = [
        #   "076c7d16-1623-4252-a845-5b36b067368c"
        # ]
        "Azure Kubernetes Service RBAC Admin" = [
          "0e8a217c-29a5-480d-980f-5381ccb07647"
        ]
      }
    }
  }
  prd = {
    labels = {
      team = "platform"
      env  = "prd"
    }
    annotations = {
      owner = "retail"
    }
    adoptionPolicy = "Always"
    deletePolicy   = "Delete"

    defaultResourceQuota = {
      cpuLimit      = "1000m"
      cpuRequest    = "500m"
      memoryLimit   = "2Gi"
      memoryRequest = "1Gi"
    }

    defaultNetworkPolicy = {
      ingress = "AllowSameNamespace"
      egress  = "AllowSameNamespace"
    }

    rbac = {
      namespace_roles = {
        # "Azure Kubernetes Service RBAC Reader" = [
        #   "c7734397-7757-40a6-90c9-8964494e0851"
        # ]
        # "Azure Kubernetes Service RBAC Writer" = [
        #   "076c7d16-1623-4252-a845-5b36b067368c"
        # ]
        "Azure Kubernetes Service RBAC Admin" = [
          "c0d8a014-04c8-4f9f-b44a-556c2e64cf3d",
          "25910c7a-ea7c-4cd6-bc3b-7450c5761e49",
          "6e960790-23e7-4d45-a48f-ceae35048c4a"
        ]
      }
    }
  }  
}

