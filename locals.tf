locals {

  # 🔹 Expand namespace RBAC (Reader / Writer / Admin)
  namespace_rbac = merge([
    for ns_name, ns in var.managed_namespaces : merge([
      for role, principals in ns.rbac.namespace_roles : {
        for principal in principals :
        "${ns_name}-${role}-${principal}" => {
          scope     = azapi_resource.managed_namespace[ns_name].id
          role      = role
          principal = principal
        }
      }
    ]...)
  ]...)

  # 🔹 Collect all unique principals from namespace RBAC
  namespace_principals = distinct([
    for v in values(local.namespace_rbac) : v.principal
  ])

  # 🔹 Automatically grant Cluster User Role
  cluster_user_rbac = {
    for p in local.namespace_principals :
    "cluster-user-${p}" => {
      scope     = data.azurerm_kubernetes_cluster.aks_cluster.id
      role      = "Azure Kubernetes Service Cluster User Role"
      principal = p
    }
  }

  # 🔹 Final RBAC set (cluster + namespace)
  rbac_assignments = merge(
    local.cluster_user_rbac,
    local.namespace_rbac
  )
}
