# Configure the Azure provider
provider "azurerm" {
  features {}
}

# Create a resource group for the storage account
resource "azurerm_resource_group" "state_rg" {
  name     = "tfstate-rg"
  location = "East US"
}

# Create a storage account for Terraform state
resource "azurerm_storage_account" "tfstate_storage" {
  name                     = "tfstatestorage8247"  # Change this to a unique name
  resource_group_name      = azurerm_resource_group.state_rg.name
  location                 = azurerm_resource_group.state_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a container in the storage account for the state file
resource "azurerm_storage_container" "tfstate_container" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate_storage.name
  container_access_type = "private"
}

# Configure the Terraform backend to use Azure Storage
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestorage8247"  # Match the storage account name above
    container_name       = "tfstate"
    key                  = "KEY"
  }
}

# Your existing resources
resource "azurerm_resource_group" "example" {
  name     = "example"
  location = "East US"
}

resource "azurerm_virtual_network" "VNET1" {
  name                = "VNET1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "SUBNET1" {
  name                 = "SUBNET1"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.VNET1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "NF" {
  name                = "NF"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SUBNET1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "VM1" {
  name                  = "VM1"
  resource_group_name   = azurerm_resource_group.example.name
  location              = azurerm_resource_group.example.location
  size                  = "Standard_B1s"
  admin_username        = "pranayvm"
  admin_password        = "P@ssw0rd1234!" # Replace with a strong password
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.NF.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "osdisk1"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  computer_name = "linuxvm"
}

output "vm_public_ip" {
  value = azurerm_network_interface.NF.ip_configuration[0].private_ip_address
}
