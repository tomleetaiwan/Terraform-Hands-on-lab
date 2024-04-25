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

# 建立 Azure Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "vm-demo-rg"
  location = "eastasia"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "example-network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "demo-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                = "demo-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vm_size             = "Standard_DS1_v2"  
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_profile_linux_config {
    disable_password_authentication = false
  }

  os_profile {
    computer_name  = "demo-vm"
    admin_username = "<登入帳號>"
    admin_password = "<登入密碼>"
  }

  storage_os_disk {
    name                 = "demo-dsk"
    managed_disk_type    = "Standard_LRS"
    create_option        = "FromImage"    
    caching              = "ReadWrite"
  }
  
  storage_image_reference {
    publisher           = "Canonical"
    offer               = "0001-com-ubuntu-server-focal"    
    sku                 = "20_04-lts-gen2"
    version             = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "ext" {
  name                 = "extension-AMA"
  virtual_machine_id   = azurerm_virtual_machine.vm.id  
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = "true"
 } 

