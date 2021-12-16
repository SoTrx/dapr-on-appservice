# output "redis_ip_address" {
#   value       = module.infra.redis_ip_address
#   description = "The IP address allocated to the Redis instance"
# }


output "placement_ip_address" {
  value       = module.infra.placement_ip_address
  description = "The IP address allocated to the placement instance"
}
