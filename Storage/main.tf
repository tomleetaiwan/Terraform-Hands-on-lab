# 定義使用 Azure Resource Provider 並限定版本號碼
provider "azurerm" {
  version = "~> 1.37"
}

# 定義變數 location 來決定資料中心
# 使用 az account list-locations -o table 列出可用的資料中心
variable "location" {
  default = "eastasia"
}

# 定義變數 resource_group_name 來決定建立之 Azure Resource Group 名稱
variable "resource_group_name" {
  default = "TomDemoTerraformRG"
}

# 定義變數 storage_name 來決定建立之 Azure Storage 名稱
variable "storage_name" {
  default = "tomterraformstorage"
}

# 建立 Azure Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# 建立 3 個 Azure Storage Account 使用變數 storage_name 並在其後加上序號作為 Storage Account 名稱
resource "azurerm_storage_account" "sa" {
  count                    = 3
  name                     = format("%s%02d", var.storage_name, count.index)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
}