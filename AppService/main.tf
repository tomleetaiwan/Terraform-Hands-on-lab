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

# 建立 Azure SQL Database Server
resource "azurerm_sql_server" "sqlserver" {
  name                         = "tomdemosqlserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "tomleedemo"
  administrator_login_password = "4-v3ry-53xxU-p455w0rd"
}

# 建立 Azure SQL Database Single Database
resource "azurerm_sql_database" "sqldb" {
  name                = "tomsqldatabase"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_sql_server.sqlserver.name
  edition = "Basic"
}

# 建立 Azure SQL Database 防火牆允許存取 IP 範圍
resource "azurerm_sql_firewall_rule" "firewall" {
  name                = "TomFirewallRule"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.sqlserver.name
  start_ip_address    = "1.1.1.1"
  end_ip_address      = "255.255.255.255"
}
