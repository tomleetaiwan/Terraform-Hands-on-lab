terraform {
  required_version = "~> 0.12"
}

# 定義使用 Azure Resource Provider 並限定版本號碼
provider "azurerm" {
  version = "~> 1.43"
}

# 建立 Azure Resource Group
resource "azurerm_resource_group" "main" {
  name     = format("%sRG", var.prefix)
  location = var.location
}

# 定義建立的 VM 數量
locals {
  instance_count = 2
}

# 建立 Virtual Network (VNET)
resource "azurerm_virtual_network" "main" {
  name                = format("%s-network", var.prefix) 
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# 在 VNET 內建立 Subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = "10.0.2.0/24"
}

# 建立 public IPs
resource "azurerm_public_ip" "pip" {
  name                = format("%s-pip", var.prefix) 
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Dynamic"
}

# 為每個 VM 建立 Network Interface
resource "azurerm_network_interface" "main" {
  count               = local.instance_count
  name                = format("%s-nic%02d", var.prefix, count.index) 
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

# 建立可用性群組 (Availability Set) 確保 VM 不會落在同一個機櫃
resource "azurerm_availability_set" "avset" {
  name                         = format("%s-avset", var.prefix)
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

# 建立 NSG (Network Security Group) 開放 HTTP 通訊協定 80 TCP Port
resource "azurerm_network_security_group" "webserver" {
  name                = "http_webserver"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "tls"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "80"
    destination_address_prefix = azurerm_subnet.internal.address_prefix
  }
}

# 建立 Layer 4 的 Azure 負載平衡器，並將之前建立的 Public IP Address 綁定
resource "azurerm_lb" "example" {
  name                = format("%s-lb", var.prefix)
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

# 建立負載平衡器的 Backend Address Pool
resource "azurerm_lb_backend_address_pool" "example" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.example.id
  name                = "BackEndAddressPool"
}

# 定義負載平衡流入之 NAT 規則
resource "azurerm_lb_nat_rule" "example" {
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "HTTPAccess"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.example.frontend_ip_configuration[0].name
}

# 將各 VM 的 Network Interafce 加入負載平衡器的 Backend Address Pool
resource "azurerm_network_interface_backend_address_pool_association" "example" {
  count                   = local.instance_count
  backend_address_pool_id = azurerm_lb_backend_address_pool.example.id
  ip_configuration_name   = "primary"
  network_interface_id    = element(azurerm_network_interface.main.*.id, count.index)
}

# 建立 Azure Virtual Machine 與 Managed Disk
resource "azurerm_virtual_machine" "main" {
  count                           = local.instance_count
  name                            = format("%s-vm%02d", var.prefix, count.index)
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  vm_size                         = "Standard_DS1_v2"
  availability_set_id             = azurerm_availability_set.avset.id
  network_interface_ids = [
    azurerm_network_interface.main[count.index].id,
  ]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name                 = format("%s-OsDisk%02d", var.prefix, count.index)
    managed_disk_type    = "Standard_LRS"
    create_option        = "FromImage"    
    caching              = "ReadWrite"
  }
  
  os_profile {
    computer_name  = format("%s-webserver%02d", var.prefix, count.index)
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}