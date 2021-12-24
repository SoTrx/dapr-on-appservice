# Renders the Dapr bindings/config and upload them on the previously created File share 

# First, Load the template and fill in the variables
data "template_file" "statestore" {
  template = file("${path.module}/bindings/statestore.yaml.tpl")
  vars = {
    REDIS_HOST = "${var.redis_ip_address}"
    REDIS_PORT = 6379
  }
}

data "template_file" "pubsub" {
  template = file("${path.module}/bindings/pubsub.yaml.tpl")
  vars = {
    REDIS_HOST = "${var.redis_ip_address}"
    REDIS_PORT = 6379
  }
}

data "template_file" "config" {
  template = file("${path.module}/config/config.yaml.tpl")
  vars = {
    CONSUL_HOST = "${var.consul_ip_address}"
    CONSUL_PORT = 8500
    # Dapr and Terraform are using the same template for variable interpolation.
    # So we must cheat and render the dynamic template as another layer of interpolation
    APP_ID            = "$${APP_ID}"
    APP_PORT          = "$${APP_PORT}"
    HOST_ADDRESS      = "$${HOST_ADDRESS}"
    DAPR_METRICS_PORT = "$${DAPR_METRICS_PORT}"
    DAPR_PROFILE_PORT = "$${DAPR_PROFILE_PORT}"
  }
}

# Then, write the rendered remplates to disk
resource "local_file" "rendered-statestore" {
  content  = data.template_file.statestore.rendered
  filename = "${path.module}/bindings/statestore.yaml"
}

resource "local_file" "rendered-pubsub" {
  content  = data.template_file.pubsub.rendered
  filename = "${path.module}/bindings/pubsub.yaml"
}

resource "local_file" "rendered-config" {
  content  = data.template_file.config.rendered
  filename = "${path.module}/config/config.yaml"
}

# Finally, upload them on the file share
resource "azurerm_storage_share_file" "upload-statestore" {
  depends_on = [
    local_file.rendered-statestore
  ]
  name             = "statestore.yaml"
  storage_share_id = var.dapr_components_share_id
  source           = "${path.module}/bindings/statestore.yaml"
}

resource "azurerm_storage_share_file" "upload-pubsub" {
  depends_on = [
    local_file.rendered-pubsub
  ]
  name             = "pubsub.yaml"
  storage_share_id = var.dapr_components_share_id
  source           = "${path.module}/bindings/pubsub.yaml"
}

resource "azurerm_storage_share_file" "upload-config" {
  depends_on = [
    local_file.rendered-config
  ]
  name             = "config.yaml"
  storage_share_id = var.dapr_config_share_id
  source           = "${path.module}/config/config.yaml"
}

#########################################################
# Pythonapp deployment
#########################################################

# Create a network interface for the Python sidecar container group...
resource "azurerm_network_profile" "python-sidecar-nic" {
  name                = "${var.global_prefix}-python-sidecar-np"
  location            = var.location
  resource_group_name = var.rg_name

  container_network_interface {
    name = "containers-subnet-python-sidecar-np-nic"

    ip_configuration {
      name      = "containers-subnet-python-sidecar-np-ip"
      subnet_id = var.containers_subnet_id
    }
  }
}

resource "azurerm_container_group" "satcar-python" {
  name                = "${var.global_prefix}-satcar-python"
  location            = var.location
  resource_group_name = var.rg_name
  ip_address_type     = "private"
  network_profile_id  = azurerm_network_profile.python-sidecar-nic.id
  os_type             = "linux"

  container {
    name   = "satcar-python"
    image  = "dockerutils/dapr-on-ase-satcar"
    cpu    = "1"
    memory = "1.5"

    # Main app to Dapr HTTP communication
    ports {
      port     = 3500
      protocol = "TCP"
    }

    # Cross Dapr GRPC port
    ports {
      port     = 5555
      protocol = "TCP"
    }

    environment_variables = {
      # Dapr placement pod private IP address
      PLACEMENT_HOST = var.placement_ip_address
      # Dapr placement pod private IP port
      PLACEMENT_PORT = "50006"
      # Main app host 
      # @NOTE : the "p" should be removed for an internal ASE
      # @WARNING : MUST BE THE SAME AS app service pythonapp name. Cannot
      # add a variable as terraform would abort on the cycle
      APP_HOST = "${var.global_prefix}-pythonapp.${var.ase_name}.p.azurewebsites.net"
      # Main app port 
      APP_PORT = "80"
      # Name of the main app for Dapr registration
      APP_ID = "pythonapp"
    }

    volume {
      name                 = "components"
      mount_path           = "/components"
      read_only            = true
      share_name           = var.dapr_components_share_name
      storage_account_name = var.st_account_name
      storage_account_key  = var.st_account_key
    }
    volume {
      name                 = "config"
      mount_path           = "/config"
      read_only            = true
      share_name           = var.dapr_config_share_name
      storage_account_name = var.st_account_name
      storage_account_key  = var.st_account_key
    }
  }
}

# Create the Python Publisher app on the ASE
resource "azurerm_app_service" "pythonapp" {
  # @WARNING : MUST BE THE SAME AS container group APP_HOST name
  name                = "${var.global_prefix}-pythonapp"
  location            = var.location
  resource_group_name = var.rg_name
  app_service_plan_id = var.app_plan_id

  app_settings = {
    # Sidecar ip adress
    "DAPR_HOST" = "${azurerm_container_group.satcar-python.ip_address}",
    # Update the container on new push
    "DOCKER_ENABLE_CI" = "true",
    # Enable filesystem logs. Easier to debug
    "WEBSITE_HTTPLOGGING_RETENTION_DAYS" = "7",
    # Route all traffic thru VNet. Mandatory for ASE 
    "WEBSITE_VNET_ROUTE_ALL" = "1",
    # No need for volumes in these
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }

  site_config {
    linux_fx_version = "DOCKER|dockerutils/dapr-on-ase-pythonapp:latest"
    always_on        = "true"
  }
}

#########################################################
# Pythonapp deployment
#########################################################

# Create a network interface for the Python sidecar container group...
resource "azurerm_network_profile" "node-sidecar-nic" {
  name                = "${var.global_prefix}-node-sidecar-np"
  location            = var.location
  resource_group_name = var.rg_name

  container_network_interface {
    name = "containers-subnet-node-sidecar-np-nic"

    ip_configuration {
      name      = "containers-subnet-node-sidecar-np-ip"
      subnet_id = var.containers_subnet_id
    }
  }
}

resource "azurerm_container_group" "satcar-node" {
  name                = "${var.global_prefix}-satcar-node"
  location            = var.location
  resource_group_name = var.rg_name
  ip_address_type     = "private"
  network_profile_id  = azurerm_network_profile.node-sidecar-nic.id
  os_type             = "linux"

  container {
    name   = "satcar-node"
    image  = "dockerutils/dapr-on-ase-satcar"
    cpu    = "1"
    memory = "1.5"

    # Main app to Dapr HTTP communication
    ports {
      port     = 3500
      protocol = "TCP"
    }

    # Cross Dapr GRPC port
    ports {
      port     = 5555
      protocol = "TCP"
    }

    environment_variables = {
      # Dapr placement pod private IP address
      PLACEMENT_HOST = var.placement_ip_address
      # Dapr placement pod private IP port
      PLACEMENT_PORT = "50006"
      # Main app host 
      # @NOTE : the "p" should be removed for an internal ASE
      # @WARNING : MUST BE THE SAME AS app service pythonapp name. Cannot
      # add a variable as terraform would abort on the cycle
      APP_HOST = "${var.global_prefix}-nodeapp.${var.ase_name}.p.azurewebsites.net"
      # Main app port 
      APP_PORT = "80"
      # Name of the main app for Dapr registration
      APP_ID = "nodeapp"
    }

    volume {
      name                 = "components"
      mount_path           = "/components"
      read_only            = true
      share_name           = var.dapr_components_share_name
      storage_account_name = var.st_account_name
      storage_account_key  = var.st_account_key
    }
    volume {
      name                 = "config"
      mount_path           = "/config"
      read_only            = true
      share_name           = var.dapr_config_share_name
      storage_account_name = var.st_account_name
      storage_account_key  = var.st_account_key
    }
  }
}

# Create the Node Subscriber app on the ASE
resource "azurerm_app_service" "nodeapp" {
  depends_on = [
    azurerm_container_group.satcar-node
  ]
  # @WARNING : MUST BE THE SAME AS container group APP_HOST name
  name                = "${var.global_prefix}-nodeapp"
  location            = var.location
  resource_group_name = var.rg_name
  app_service_plan_id = var.app_plan_id

  app_settings = {
    # Sidecar ip adress
    "DAPR_HOST" = "${azurerm_container_group.satcar-node.ip_address}",
    # Update the container on new push
    "DOCKER_ENABLE_CI" = "true",
    # Enable filesystem logs. Easier to debug
    "WEBSITE_HTTPLOGGING_RETENTION_DAYS" = "7",
    # Route all traffic thru VNet. Mandatory for ASE 
    "WEBSITE_VNET_ROUTE_ALL" = "1",
    # No need for volumes in these
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }

  site_config {
    linux_fx_version = "DOCKER|dockerutils/dapr-on-ase-nodeapp:latest"
    always_on        = "true"
  }
}
