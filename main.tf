data "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_name
  resource_group_name = var.aks_resource_group
}

resource "azapi_resource" "managed_namespace" {
  for_each = var.managed_namespaces

  type      = "Microsoft.ContainerService/managedClusters/managedNamespaces@2025-10-02-preview"
  name      = each.key
  parent_id = data.azurerm_kubernetes_cluster.aks_cluster.id
  location  = data.azurerm_kubernetes_cluster.aks_cluster.location

  schema_validation_enabled = false

  body = {
    properties = {
      labels               = each.value.labels
      annotations          = each.value.annotations
      adoptionPolicy       = each.value.adoptionPolicy
      deletePolicy         = each.value.deletePolicy
      defaultResourceQuota = each.value.defaultResourceQuota
      defaultNetworkPolicy = each.value.defaultNetworkPolicy
    }
  }
}

resource "azurerm_role_assignment" "rbac" {
  for_each = local.rbac_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = each.value.principal
  principal_type       = "Group"
}
