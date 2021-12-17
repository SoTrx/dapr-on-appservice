output "redis_ip_address" {
  value       = azurerm_container_group.redis.ip_address
  description = "The IP address allocated to the Redis instance"
}


output "placement_ip_address" {
  value       = azurerm_container_group.dapr-placement.ip_address
  description = "The IP address allocated to the placement instance"
}

