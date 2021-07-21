terraform {
  required_version = ">= 1.0.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
  backend "azurerm" {
    storage_account_name = "__TerraformStorageAccount__"
    container_name       = "__TerraformContainer__"
    key                  = "terraform.tfstate"
    access_key           = "__StorageKey__"
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Use existing Resource Group
data "azurerm_resource_group" "rg" {
  name = "MacroLife"
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "macrolife-vnet"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
  tags = {
    environment = "dev"
    source      = "terraform"
    owner       = "cristian.balan"
  }
}

# Create Subnets within the Virtual Network
resource "azurerm_subnet" "snet1" {
  name                 = "snet1"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_subnet" "snet2" {
  name                 = "snet2"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "macrolife-nsg"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTPS"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    environment = "dev"
    source      = "terraform"
    owner       = "cristian.balan"
  }
}

# Create Public IPs
resource "azurerm_public_ip" "pip1" {
  name                = "macrolife-pip1"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  allocation_method   = "Static"
  tags = {
    environment = "dev"
    source      = "terraform"
    owner       = "cristian.balan"
  }
}
resource "azurerm_public_ip" "pip2" {
  name                = "macrolife-pip2"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  allocation_method   = "Static"
  tags = {
    environment = "dev"
    source      = "terraform"
    owner       = "cristian.balan"
  }
}

# Create Network Interface 1
resource "azurerm_network_interface" "nic1" {
  name                = "macrolife-nic1"
  depends_on          = [data.azurerm_resource_group.rg, azurerm_subnet.snet1, azurerm_public_ip.pip1]
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "ipconf1"
    subnet_id                     = azurerm_subnet.snet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
    public_ip_address_id          = azurerm_public_ip.pip1.id
  }
  tags = {
    environment = "dev"
    source      = "terraform"
    owner       = "cristian.balan"
  }
}

# Associate Network Interface 1 with NSG
resource "azurerm_network_interface_security_group_association" "nsgassoc1" {
  network_interface_id      = azurerm_network_interface.nic1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create VM 1
resource "azurerm_windows_virtual_machine" "vm1" {
  name                  = "macrolife-vm1"
  depends_on            = [data.azurerm_resource_group.rg, azurerm_network_interface.nic1]
  resource_group_name   = data.azurerm_resource_group.rg.name
  location              = data.azurerm_resource_group.rg.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  admin_password        = "__VM1AdminPWD__"
  network_interface_ids = [azurerm_network_interface.nic1.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  tags = {
    environment = "dev"
    source      = "terraform"
    owner       = "cristian.balan"
  }
}

# Create Network Interface 2
resource "azurerm_network_interface" "nic2" {
  name                = "macrolife-nic2"
  depends_on          = [data.azurerm_resource_group.rg, azurerm_subnet.snet2, azurerm_public_ip.pip2]
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "ipconf2"
    subnet_id                     = azurerm_subnet.snet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.4"
    public_ip_address_id          = azurerm_public_ip.pip2.id
  }
  tags = {
    environment = "dev"
    source      = "terraform"
    owner       = "cristian.balan"
  }
}

# Associate Network Interface 2 with NSG
resource "azurerm_network_interface_security_group_association" "nsgassoc2" {
  network_interface_id      = azurerm_network_interface.nic2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create VM 2
resource "azurerm_windows_virtual_machine" "vm2" {
  name                  = "macrolife-vm2"
  depends_on            = [data.azurerm_resource_group.rg, azurerm_network_interface.nic2]
  resource_group_name   = data.azurerm_resource_group.rg.name
  location              = data.azurerm_resource_group.rg.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  admin_password        = "__VM2AdminPWD__"
  network_interface_ids = [azurerm_network_interface.nic2.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  tags = {
    environment = "dev"
    source      = "terraform"
    owner       = "cristian.balan"
  }
}

# Create Storage Account
resource "azurerm_storage_account" "st1" {
  name                     = "macrolifest1"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "dev"
    source      = "terraform"
    owner       = "cristian.balan"
  }
}
