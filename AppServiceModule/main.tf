# 定義使用 Terraform 版本號碼
terraform {
  required_version = "~> 0.12"
}

# 定義使用 Azure Resource Provider 並限定版本號碼
provider "azurerm" {
  version = "~> 1.37"
}

# 建立個 Azure Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "tomappfreesvcRG"
  location = "southeastasia"
}

# 建立個 Azure App Service Plan，建立 Windows Server 之免費版本
resource "azurerm_app_service_plan" "appsvc_plan" {
  name                = "tomfreewebapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Windows"

  sku {
    tier = "Free"
    size = "F1"
  }
}

# 建立個 Azure App Service Web App ，注意免費版必須使用 32 bit worker process
resource "azurerm_app_service" "webapp" {
  name                = "tomfreewebapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.appsvc_plan.id

  site_config {
    dotnet_framework_version  = "v4.0"
    use_32_bit_worker_process = "true"
  }
}

module "SQLDatabase" {
  source = "./sqldb"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sqlserver_name = "tomdemosqlsvr"
  database_name = "tomdemosqldb"
}
