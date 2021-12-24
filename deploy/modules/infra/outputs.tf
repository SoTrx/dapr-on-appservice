output "rg_name" {
  value       = azurerm_resource_group.rg.name
  description = "Name of the Resource group the resources were created in"
}

output "app_plan_id" {
  value       = azurerm_app_service_plan.plan.id
  description = "ASE plan's ID"
}

output "containers_subnet_id" {
  value       = azurerm_subnet.containers.id
  description = "ID of the subnet the apps should be placed in"
}

output "ase_name" {
  value       = azurerm_app_service_environment_v3.ase.name
  description = "ASE name"
}

output "redis_ip_address" {
  value       = azurerm_container_group.redis.ip_address
  description = "The IP address allocated to the Redis instance"
}

output "placement_ip_address" {
  value       = azurerm_container_group.dapr-placement.ip_address
  description = "The IP address allocated to the placement instance"
}

output "consul_ip_address" {
  value       = azurerm_container_group.consul.ip_address
  description = "The IP address allocated to the consul instance"
}

output "st_account_name" {
  value       = azurerm_storage_account.st.name
  description = "Name of the shared storage account between resources"
}

output "st_account_key" {
  value       = azurerm_storage_account.st.primary_access_key
  description = "Key of the shared storage account"
}

output "dapr_components_share_name" {
  value       = azurerm_storage_share.st_bindings_share.name
  description = "Name of the storage share use to store DAPR components"
}

output "dapr_config_share_name" {
  value       = azurerm_storage_share.st_config_share.name
  description = "Name of the storage share use to store DAPR config"

}

output "dapr_components_share_id" {
  value       = azurerm_storage_share.st_bindings_share.id
  description = "ID of the storage share use to store DAPR components"
}

output "dapr_config_share_id" {
  value       = azurerm_storage_share.st_config_share.id
  description = "ID of the storage share use to store DAPR config"

}

