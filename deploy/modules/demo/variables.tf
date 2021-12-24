variable "global_prefix" {
  default     = "dapr-on-ext-ase"
  description = "The name of the container group"
}

variable "rg_name" {
  description = "Name of the resource group to put the resources in"
}

variable "location" {
  default     = "West Europe"
  description = "Az region to put resources in"
}

variable "app_plan_id" {
  description = "ASE plan's ID"
}

variable "containers_subnet_id" {
  description = "ID of the subnet the apps should be placed in"
}

variable "ase_name" {
  description = "ASE name"
}

variable "redis_ip_address" {
  description = "Ip adress of the redis instance"
}
variable "placement_ip_address" {
  description = "Ip adress of Dapr's placement instance"
}
variable "consul_ip_address" {
  description = "Ip adress of Consul instance"
}

variable "st_account_name" {
  description = "Name of the shared storage account between resources"
}
variable "st_account_key" {
  description = "Key of the shared storage account"
}
variable "dapr_components_share_name" {
  description = "Dapr components file share name"
}

variable "dapr_config_share_name" {
  description = "Dapr config file share name"
}

variable "dapr_components_share_id" {
  description = "Dapr components file share id"
}

variable "dapr_config_share_id" {
  description = "Dapr config file share id"
}
