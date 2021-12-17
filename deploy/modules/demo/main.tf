# Renders the redis binfind and store it in the storage account 
data "template_file" "statestore" {
  template = file("${path.module}/statestore.yaml.tpl")
  vars = {
    REDIS_HOST  = "${var.redis_ip_address}"
    REDIS_PORT  = 6379
  }
}

resource "azurerm_storage_share_file" "example" {
  name             = "my-awesome-content.zip"
  storage_share_id = azurerm_storage_share.example.id
  //source           = "some-local-file.zip"
  source_content         = data.template_file.statestore.rendered
}

resource "null_resource" "uploadfile" {

  provisioner "local-exec" {
  command = <<-EOT
  $storageAcct = Get-AzStorageAccount -ResourceGroupName "${azurerm_resource_group.example.name}" -Name "${azurerm_storage_account.example.name}"
    Set-AzStorageFileContent `
    -Context $storageAcct.Context `
    -ShareName "${azurerm_storage_share.example.name}" `
    -Source "C:\Users\xxx\terraform\test.txt" `
    -Path "test.txt"

  EOT

  interpreter = ["PowerShell", "-Command"]
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

resource "azurerm_container_group" "example" {
  name                = "${var.prefix}-continst"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  ip_address_type     = "public"
  dns_name_label      = "${var.prefix}-continst"
  os_type             = "linux"

  container {
    name   = "webserver"
    image  = "seanmckenna/aci-hellofiles"
    cpu    = "1"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }

    volume {
      name       = "logs"
      mount_path = "/aci/logs"
      read_only  = false
      share_name = azurerm_storage_share.example.name

      storage_account_name = azurerm_storage_account.example.name
      storage_account_key  = azurerm_storage_account.example.primary_access_key
    }
  }

  tags = {
    environment = "testing"
  }
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

