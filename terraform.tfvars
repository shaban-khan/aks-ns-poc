aks_name               = "aksdemo02"
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