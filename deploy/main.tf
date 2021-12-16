provider "azurerm" {
  features {}
}

module "infra" {
    source = "./modules/infra"
}