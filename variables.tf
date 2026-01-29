variable "aks_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "aks_resource_group" {
  description = "Resource group where AKS is deployed"
  type        = string
}

variable "managed_namespace_name" {
  description = "Name of the managed Kubernetes namespace"
  type        = string
}
variable "ns_admin_aad_group_object_id" {
  description = "Azure AD Group Object ID to grant admin access to the managed namespace"
  type        = string  
}

variable "ns_writer_aad_group_object_id" {
  description = "Azure AD Group Object ID to grant access to the managed namespace"
  type        = string
}

variable "ns_reader_aad_group_object_id" {
  description = "Azure AD Group Object ID to grant access to the managed namespace"
  type        = string
}

variable "cluster_user_aad_group_object_id" {
  description = "Azure AD Group Object ID to assign Cluster User Role on the AKS cluster"
  type        = string
}
variable "rbac_role_name" {
  description = "Azure RBAC role to assign to the managed namespace"
  type        = string
  default     = "Azure Kubernetes Service RBAC Admin"
}

variable "subscription_id" {
  type = string
}