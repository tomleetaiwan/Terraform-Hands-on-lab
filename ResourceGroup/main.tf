# 定義使用 Azure Resource Provider 並限定版本號碼
provider "azurerm" {
  version = "~> 1.37"
}

# 定義變數 name
variable "name" {
  default = "TomDemoTerraformRG"
}

# 建立 2 個 Azure Resource Group，使用變數 name 並在其後加上序號作為 Resource Group 名稱
resource "azurerm_resource_group" "rg" {
  count = 2
  name = format ("%s%02d",var.name,count.index)
  location = "eastasia"
}

# 定義要取得之資料
data "azurerm_virtual_machine" "vm" {
  name                = "TomWin10"
  resource_group_name = "TomRG"
}

# 取得 Azure VM : TomWin10 Resource ID
output "virtual_machine_id" {
  value = data.azurerm_virtual_machine.vm.id
}

# 輸出所建立的 Resource Group 全部資訊
output "resource_group" {
  value  = azurerm_resource_group.rg[*]
  description = "建立 Azure Resource Group 資訊."
}

# 只輸所出建立的 Resource Group 所在的資料中心地點
output "resource_group_location" {
  value  = azurerm_resource_group.rg[*].location
  description = "建立 Azure Resource Group 資訊."
}