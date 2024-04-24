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

# 定義變數資料中心位置 
# 使用 az account list-locations -o table 列出可用的資料中心

variable "location" {
  default = "southeastasia"
}

# 定義變數 Resource Group 名稱 
variable "resource_group_name" {
  default = "demo-rg"
}

# 定義變數 SQL Server 名稱 
variable "sqlserver_name" {
  default = "demosqlsvr"
}

# 定義變數 Database 名稱
variable "database_name" {
  default = "demodb"
}

# 建立 Azure SQL Database Server
resource "azurerm_mssql_server" "sqlsvr" {
  name                         = var.sqlserver_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "tomleedemo"
  administrator_login_password = "4-v3ry-53xxU-p455w0rd"
  minimum_tls_version          = "1.2"
  public_network_access_enabled = true  
}

# 建立 Azure SQL Database Single Database
resource "azurerm_mssql_database" "sqldb" {
  name           = var.database_name
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
