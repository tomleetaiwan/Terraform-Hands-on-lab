# 定義使用 Terraform 版本號碼
terraform {
  required_version = "~> 0.12"
}

# 定義使用 Azure Resource Provider 並限定版本號碼
provider "azurerm" {
  version = "~> 1.37"
}

# 定義變數資料中心位置 
# 使用 az account list-locations -o table 列出可用的資料中心

variable "location" {
  default = "eastasia"
}

# 定義變數 Resource Group 名稱 
variable "resource_group_name" {
  default = "TomDemoTerraformRG"
}

# 定義變數 SQL Server 名稱 
variable "sqlserver_name" {
  default = "tomdemoterraformdbsvr"
}

# 定義變數 Database 名稱
variable "database_name" {
  default = "tomdemoterraformdb"
}

# 建立 Azure SQL Database Server
resource "azurerm_sql_server" "sqlserver" {
  name                         = var.sqlserver_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "tomleedemo"
  administrator_login_password = "4-v3ry-53xxU-p455w0rd"
}

# 建立 Azure SQL Database Single Database
resource "azurerm_sql_database" "sqldb" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  location            = var.location
  server_name         = azurerm_sql_server.sqlserver.name
  edition = "Basic"
}

# 建立 Azure SQL Database 防火牆允許存取 IP 範圍
resource "azurerm_sql_firewall_rule" "firewall" {
  name                = "TomFirewallRule"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_sql_server.sqlserver.name
  start_ip_address    = "1.1.1.1"
  end_ip_address      = "255.255.255.255"
}
