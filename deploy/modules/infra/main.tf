provider "azurerm" {
  features {}
}

# Ressource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.global_prefix}-rg"
  location = var.location
}

# Storage account
resource "azurerm_storage_account" "st" {
  # An Storage account name cannot contains hyphens, so let's sanitize it
  name                     = join("", split("-", "${var.global_prefix}-sa"))
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# File share for the components
resource "azurerm_storage_share" "st_bindings_share" {
  name                 = "bindings"
  storage_account_name = azurerm_storage_account.st.name
  quota                = 50
}

# File share for the config
resource "azurerm_storage_share" "st_config_share" {
  name                 = "config"
  storage_account_name = azurerm_storage_account.st.name
  quota                = 50
}

# Vnet + Subnet
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.global_prefix}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}


# Create a subnet for the App Service Env
resource "azurerm_subnet" "ase" {
  name                 = "ase-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.0.1.0/24"]

  # A subnet hosting an ASEv3 must have this delegation 
  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.Web/hostingEnvironments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# And another for every containerized service
resource "azurerm_subnet" "containers" {
  name                 = "containers-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}


# Create an external ASE...
resource "azurerm_app_service_environment_v3" "ase" {
  name                = "${var.global_prefix}-ase"
  subnet_id           = azurerm_subnet.ase.id
  resource_group_name = azurerm_resource_group.rg.name
}

#...And its associated Isolated plan
resource "azurerm_app_service_plan" "plan" {
  name                       = "${var.global_prefix}-ase-plan"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  kind                       = "Linux"
  reserved                   = true
  app_service_environment_id = azurerm_app_service_environment_v3.ase.id

  sku {
    tier = "IsolatedV2"
    size = "I1V2"
    # Workaround for https://github.com/hashicorp/terraform-provider-azurerm/issues/1708
    capacity = 2
  }
}

#########################################################
# Consul (DNS resolver) deployment
#########################################################

# Create a network interface for Consul...
resource "azurerm_network_profile" "consulNic" {
  name                = "containers-subnet-consul-np"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  container_network_interface {
    name = "containers-subnet-consul-np-nic"

    ip_configuration {
      name      = "containers-subnet-consul-np-ip"
      subnet_id = azurerm_subnet.containers.id
    }
  }
}

# ... And then create the instance
resource "azurerm_container_group" "consul" {
  name                = "consul"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "private"
  network_profile_id  = azurerm_network_profile.consulNic.id
  os_type             = "Linux"

  container {
    name   = "consul"
    image  = "consul"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
    ports {
      port     = 8500
      protocol = "TCP"
    }
    ports {
      port     = 8600
      protocol = "UDP"
    }
  }

}

#########################################################
# Redis (PubSub support) deployment
#########################################################

# Create a network interface for the Redis container group...
resource "azurerm_network_profile" "redisNic" {
  name                = "containers-subnet-redis-np"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  container_network_interface {
    name = "containers-subnet-redis-np-nic"

    ip_configuration {
      name      = "containers-subnet-redis-np-ip"
      subnet_id = azurerm_subnet.containers.id
    }
  }
}

# ... And then create the instance
resource "azurerm_container_group" "redis" {
  name                = "redis"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "private"
  network_profile_id  = azurerm_network_profile.redisNic.id
  os_type             = "Linux"

  container {
    name   = "placement"
    image  = "redis"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 6379
      protocol = "TCP"
    }
  }
}

#########################################################
# Dapr placement (Actors model support) deployment
#########################################################
# Create a network interface for the Dapr placement pod
resource "azurerm_network_profile" "placementNic" {
  name                = "containers-subnet-placement-np"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  container_network_interface {
    name = "containers-subnet-placement-np-nic"

    ip_configuration {
      name      = "containers-subnet-placement-np-ip"
      subnet_id = azurerm_subnet.containers.id
    }
  }
}


# ... And then create the instance
resource "azurerm_container_group" "dapr-placement" {
  name                = "dapr-placement"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "private"
  network_profile_id  = azurerm_network_profile.placementNic.id
  os_type             = "Linux"

  container {
    name   = "placement"
    image  = "daprio/dapr"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 50006
      protocol = "TCP"
    }
    commands = ["./placement -port 50006"]
  }
}

