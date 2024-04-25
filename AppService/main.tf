# 指定使用之 Azure Provider 來源與版本號碼
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100.0"
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
resource "azurerm_resource_group" "app-rg" {
  name     = "appsvc-rg"
  location = "southeastasia"
}

# 建立個 Azure App Service Plan，建立 Windows Server 之免費版本
resource "azurerm_service_plan" "appsvcplan" {
  name                = "tomfreeappsvcplan"
  resource_group_name = azurerm_resource_group.app-rg.name
  location            = azurerm_resource_group.app-rg.location
  sku_name            = "F1"
  os_type             = "Windows"  
}

# 建立個 Azure App Service Web App 搭配前面的免費版 App Service Plan
resource "azurerm_windows_web_app" "webapp" {
  name                = "freewebapp${random_string.serialnumber.result}"
  resource_group_name = azurerm_resource_group.app-rg.name
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

# 建立個 Azure SQL Database 用途之資源群組
resource "azurerm_resource_group" "sql-rg" {
  name     = "database-rg"
  location = "southeastasia"
}

# 建立 Azure SQL Database Server
resource "azurerm_mssql_server" "sqlsvr" {
  name                         = "mssqlserver${random_string.serialnumber.result}"
  resource_group_name          = azurerm_resource_group.sql-rg.name
  location                     = azurerm_resource_group.sql-rg.location
  version                      = "12.0"
  administrator_login          = "tomleedemo"
  administrator_login_password = "4-v3ry-53xxU-p455w0rd"
  minimum_tls_version          = "1.2"
  public_network_access_enabled = true  
}

# 建立 Azure SQL Database Single Database
resource "azurerm_mssql_database" "sqldb" {
  name           = "tomsqldatabase"
  server_id      = azurerm_mssql_server.sqlsvr.id
  collation      = "Chinese_Taiwan_Stroke_CI_AS"
  sku_name       = "Basic" 
}

# 建立 Azure SQL Database 防火牆允許存取 IP 範圍
resource "azurerm_mssql_firewall_rule" "firewall" {
  name             = "TomFirewallRule"
  server_id        = azurerm_mssql_server.sqlsvr.id
  start_ip_address = "1.1.1.1"
  end_ip_address   = "255.255.255.255"
}  


