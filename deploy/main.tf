provider "azurerm" {
  features {}
}

module "infra" {
  source        = "./modules/infra"
  global_prefix = var.global_prefix
  location      = var.location
}

module "demo" {
  source                     = "./modules/demo"
  global_prefix              = var.global_prefix
  rg_name                    = module.infra.rg_name
  location                   = var.location
  app_plan_id                = module.infra.app_plan_id
  ase_name                   = module.infra.ase_name
  redis_ip_address           = module.infra.redis_ip_address
  consul_ip_address          = module.infra.consul_ip_address
  containers_subnet_id       = module.infra.containers_subnet_id
  placement_ip_address       = module.infra.placement_ip_address
  st_account_name            = module.infra.st_account_name
  st_account_key             = module.infra.st_account_key
  dapr_components_share_name = module.infra.dapr_components_share_name
  dapr_components_share_id   = module.infra.dapr_components_share_id
  dapr_config_share_name     = module.infra.dapr_config_share_name
  dapr_config_share_id       = module.infra.dapr_config_share_id
}
