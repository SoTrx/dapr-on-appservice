provider "azurerm" {
  features {}
}

module "infra" {
    source = "./modules/infra"
    location = "${var.location}"

}

module "demo" {
    source = "./modules/demo"
    redis_ip_address = module.infra.redis_ip_address
    location = "${var.location}"
}