# 指定使用之 Azure Provider 來源與版本號碼
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Microsoft Azure Provider 相關之組態設定
provider "azurerm" {
  features {}
}

# 以亂數產生序號名稱以避免重複 
resource "random_string" "serialnumber" {
  length  = 4
  upper   = false
  lower   = false
  numeric = true
  special = false
}

# 建立個 Azure App Service 用途之 Azure Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "demo-rg"
  location = "southeastasia"
}

# 建立個 Azure App Service Plan，建立 Windows Server 之免費版本
resource "azurerm_service_plan" "appsvcplan" {
  name                = "tomfreeappsvcplan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = "F1"
  os_type             = "Windows"  
}

# 建立個 Azure App Service Web App 搭配前面的免費版 App Service Plan
resource "azurerm_windows_web_app" "webapp" {
  name                = "demowebapp${random_string.serialnumber.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.appsvcplan.location
  service_plan_id     = azurerm_service_plan.appsvcplan.id
  # 建立個 Azure App Service Web App ，注意免費版必須使用 32 bit worker process
  site_config {    
    always_on = false
    use_32_bit_worker = true
    application_stack {
      current_stack = "dotnet"
      dotnet_version = "v4.0"
    }
  }
}

module "SQLDatabase" {
  source = "./sqldb"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sqlserver_name = "demosqlsvr${random_string.serialnumber.result}"
  database_name = "demodb"
}
