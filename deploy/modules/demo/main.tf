# Renders the redis binfind and store it in the storage account 
data "template_file" "statestore" {
  template = file("${path.module}/statestore.yaml.tpl")
  vars = {
    REDIS_HOST  = "${output.redis_ip_address}"
    REDIS_PORT  = var.ANSIBLE_VERSION
  }
}

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

# Deploy DAPR bindings in the storage account
resource "azurerm_storage_blob" "daprStateStore" {
  name                   = "pubsub.yaml"
  storage_account_name   = azurerm_storage_account.st.name
  storage_container_name = azurerm_storage_container.componentsCtn.name
  type                   = "Block"
  source_content         = data.template_file.statestore.rendered
}



resource "azurerm_storage_blob" "daprPubSub" {
  name                   = "statestore.yaml"
  storage_account_name   = azurerm_storage_account.st.name
  storage_container_name = azurerm_storage_container.componentsCtn.name
  type                   = "Block"
  source                 = "some-local-file.zip"
}


# resource "azurerm_resource_group" "rg" {
#   name     = "example-resources"
#   location = "West Europe"
# }

# resource "azurerm_container_registry" "acr" {
#   name                     = "containerRegistry1"
#   resource_group_name      = azurerm_resource_group.rg.name
#   location                 = azurerm_resource_group.rg.location
#   sku                      = "Premium"
#   admin_enabled            = true
#   georeplication_locations = ["East US", "West Europe"]
# }

# resource "azurerm_azuread_application" "acr-app" {
#   name = "acr-app"
# }

# resource "azurerm_azuread_service_principal" "acr-sp" {
#   application_id = "${azurerm_azuread_application.acr-app.application_id}"
# }

# resource "azurerm_azuread_service_principal_password" "acr-sp-pass" {
#   service_principal_id = "${azurerm_azuread_service_principal.acr-sp.id}"
#   value                = "Password12"
#   end_date             = "2022-01-01T01:02:03Z"
# }

# resource "azurerm_role_assignment" "acr-assignment" {
#   scope                = "${azurerm_container_registry.acr.id}"
#   role_definition_name = "Contributor"
#   principal_id         = "${azurerm_azuread_service_principal_password.acr-sp-pass.service_principal_id}"
# }

#    resource "null_resource" "docker_push" {
#       provisioner "local-exec" {
#       command = <<-EOT
#         docker login ${azurerm_container_registry.acr.login_server} 
#         docker push ${azurerm_container_registry.acr.login_server}
#       EOT
#       }
#     }

