terraform {
  backend "azurerm" {
    resource_group_name   = "my-resource-group"
    storage_account_name  = "mystorageaccount"
    container_name        = "mycontainer"
    key                   = "terraform.tfstate"

    use_oidc              = true
    tenant_id             = "4c5bf8b2-f805-4d46-b440-e7c825226aa2"
    client_id             = "91f29e34-9a90-48b3-9e6d-ffdc2cad31f4"
  }
}



provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  tenant_id       = var.tenant_id
}

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
  admin_password        = "P@ssw0rd1234!"
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

output "vm_private_ip" {
  value = azurerm_network_interface.NF.ip_configuration[0].private_ip_address
}
