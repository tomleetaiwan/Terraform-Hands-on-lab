terraform {
  required_version = "~> 0.12"
}

# 定義使用 Azure Resource Provider 並限定版本號碼
provider "azurerm" {
  version = "~> 1.43"
}

# 變數宣告
variable "Username" {
  default     =  "<<您的登入帳號名稱>>"
}

variable "Password" {
  default     =  "<<您的密碼>>"
}

variable "StorageName" {
  default     =  "tomlad01"
}

# 建立 Azure Resource Group
resource "azurerm_resource_group" "tom-rg" {
  name     = "tomleelinuxvmRG"
  location = "southeastasia"
}

# 建立 Virtual Network (VNET)
resource "azurerm_virtual_network" "tom-vnet" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.tom-rg.location 
    resource_group_name = azurerm_resource_group.tom-rg.name
}

# 在 VNET 內建立 Subnet
resource "azurerm_subnet" "tom-subnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.tom-rg.name
    virtual_network_name = azurerm_virtual_network.tom-vnet.name
    address_prefix       = "10.0.1.0/24"
}

# 建立 public IPs
resource "azurerm_public_ip" "tom-public-ip" {
    name                         = "myPublicIP"
    location                     = azurerm_resource_group.tom-rg.location 
    resource_group_name          = azurerm_resource_group.tom-rg.name
    allocation_method            = "Dynamic"
}

# 建立 NSG (Network Security Group)
resource "azurerm_network_security_group" "tom-nsg" {
    name                = "myNetworkSecurityGroup"
    location            = azurerm_resource_group.tom-rg.location 
    resource_group_name = azurerm_resource_group.tom-rg.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# 建立 Network Interface
resource "azurerm_network_interface" "tom-nic" {
    name                      = "myNIC"
    location                  = azurerm_resource_group.tom-rg.location  
    resource_group_name       = azurerm_resource_group.tom-rg.name
    network_security_group_id = azurerm_network_security_group.tom-nsg.id

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.tom-subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.tom-public-ip.id
    }
}

# 建立 Azure Virtual Machine 與 Managed Disk
resource "azurerm_virtual_machine" "tom-vm" {
  name                  = "mylinuxvm"
  location              = azurerm_resource_group.tom-rg.location  
  resource_group_name   = azurerm_resource_group.tom-rg.name
  network_interface_ids = [azurerm_network_interface.tom-nic.id] 
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = var.Username
    admin_password = var.Password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

}

# 建立 Azure Storage Account 以儲存 Linux Diagnostic Extension (LAD) 送出之資料
resource "azurerm_storage_account" "tom-storage" {
  name                      = var.StorageName
  resource_group_name       = azurerm_resource_group.tom-rg.name
  location                  = azurerm_resource_group.tom-rg.location
  account_replication_type  = "LRS"
  account_tier              = "Standard"
}


# 產生具備寫入 Azure Storage 權限之 SAS Token，期效為 2020/1/1-2120/1/1
data "azurerm_storage_account_sas" "diagnostics" {
  connection_string = azurerm_storage_account.tom-storage.primary_connection_string
  https_only        = true

  resource_types {
    service   = false
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = true
    file  = false
  }

  start  = "2020-01-01"
  expiry = "2120-01-01"

  permissions {
    read    = true
    write   = true
    delete  = false
    list    = true
    add     = true
    create  = true
    update  = true
    process = false
  }
}

# 定義給 Azure VM Extension - Linux Diagnostic Extension (LAD) 3.0 使用的組態設定之樣板
data "template_file" "vm-example-ladcfg" {
  template = file("custom_data/ladcfg.json.tpl")
  vars = {
    DIAGNOSTIC_STORAGE_ACCOUNT = azurerm_storage_account.tom-storage.name
    VM_RESOURCE_ID = azurerm_virtual_machine.tom-vm.id
  }
}

# 定義儲存 LAD 3.0 時之存取權限，一定要使用 SAS Token，SAS 格式中不能包含第一個字元 "?"
data "template_file" "vm-example-lad-protected-cfg" {
  template = file("custom_data/lad_protected_settings.json.tpl")
  vars = {
    DIAGNOSTIC_STORAGE_ACCOUNT = azurerm_storage_account.tom-storage.name
    DIAGNOSTIC_STORAGE_SAS = substr(data.azurerm_storage_account_sas.diagnostics.sas,1,-1)
  }
}

# 建立 Azure VM Extension - Linux Diagnostic Extension (LAD) 3.0
resource "azurerm_virtual_machine_extension" "tom-vm-lad" {
  name                 = "tom-vmlad"
  virtual_machine_id   = azurerm_virtual_machine.tom-vm.id
  publisher            = "Microsoft.Azure.Diagnostics"
  type                 = "LinuxDiagnostic"
  type_handler_version = "3.0"
  settings = data.template_file.vm-example-ladcfg.rendered
  protected_settings = data.template_file.vm-example-lad-protected-cfg.rendered
}