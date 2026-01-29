//https://learn.microsoft.com/en-us/azure/templates/microsoft.containerservice/managedclusters/managednamespaces?pivots=deployment-language-terraform

data "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_name
  resource_group_name = var.aks_resource_group
}

resource "azapi_resource" "managed_namespace" {
  type                      = "Microsoft.ContainerService/managedClusters/managedNamespaces@2025-10-02-preview"
  name                      = var.managed_namespace_name
  parent_id                 = data.azurerm_kubernetes_cluster.aks_cluster.id
  location                  = data.azurerm_kubernetes_cluster.aks_cluster.location
  schema_validation_enabled = false
  body = {
    properties = {
      # The labels of managed namespace.
      labels = {
        team = "platform"
        env  = "dev"
      }
      //The annotations of managed namespace.
      annotations = {
        "owner" = "retail"
      }
      // Action if Kubernetes namespace with same name already exists. Possible values: 'Always', 'IfIdentical', 'Never'
      adoptionPolicy = "Never"
      //Delete options of a namespace. Possible values: 'Delete' 'Keep'
      deletePolicy = "Keep"
      # Limited quota example
      defaultResourceQuota = {
        cpuLimit      = "1000m"
        cpuRequest    = "500m"
        memoryLimit   = "2Gi"
        memoryRequest = "1Gi"
      }
      //egress 	Egress policy for the network. 	'AllowAll' 'AllowSameNamespace' 'DenyAll'
      // ingress 	Ingress policy for the network. 	'AllowAll' 'AllowSameNamespace' 'DenyAll'
      defaultNetworkPolicy = {
        ingress = "AllowAll"
        egress  = "AllowAll"
      }
    }
  }
  response_export_values = ["*"]
}


# No accessConfig block at all

resource "azurerm_role_assignment" "cluster_user_assignment" {
  scope                = data.azurerm_kubernetes_cluster.aks_cluster.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = var.cluster_user_aad_group_object_id
  principal_type       = "Group"
}

# resource "azurerm_role_assignment" "ns_user_assignment" {
#   scope                = azapi_resource.managed_namespace.id
#   role_definition_name = "Azure Kubernetes Service Namespace User"
#   principal_id         = var.ns_reader_aad_group_object_id
#   principal_type       = "Group"
# }

resource "azurerm_role_assignment" "rbac_reader_assignment" {
  scope                = azapi_resource.managed_namespace.id
  role_definition_name = "Azure Kubernetes Service RBAC Reader"
  principal_id         = var.ns_reader_aad_group_object_id
  principal_type       = "Group"
}

resource "azurerm_role_assignment" "rbac_writer_assignment" {
  scope                = azapi_resource.managed_namespace.id
  role_definition_name = "Azure Kubernetes Service RBAC Writer"
  principal_id         = var.ns_writer_aad_group_object_id
  principal_type       = "Group"
}

resource "azurerm_role_assignment" "rbac_admin_assignment" {
  scope                = azapi_resource.managed_namespace.id
  role_definition_name = "Azure Kubernetes Service RBAC Admin"
  principal_id         = var.ns_admin_aad_group_object_id
  principal_type       = "Group"
}
