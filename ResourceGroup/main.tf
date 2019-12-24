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

# 定義要取得之資料，此範例是以一個之前已經建立過的 Azure Virtual Machines 作為示範
data "azurerm_virtual_machine" "vm" {
  name                = "<您的 Azure Virttual Machine 名稱>"
  resource_group_name = "<您的 Azure Virtual Machine 所在的 Resource Group 名稱>"
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