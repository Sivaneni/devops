

# Configure the Microsoft Azure Provider

#provides authentication and authorization by adding service principle to iam roles of subscription with owner access
provider "azurerm" {
  features {}
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

}
variable "client_id" {
  description = "The Client ID for the Service Principal"
  type        = string
}

variable "client_secret" {
  description = "The Client Secret for the Service Principal"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "The Tenant ID for the Service Principal"
  type        = string
}

variable "subscription_id" {
  description = "The Subscription ID for the Azure account"
  type        = string
}



resource "azurerm_resource_group" "kube-rg" {
  name     = "kube-rg"
  location = "Central India"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic"
  location            = azurerm_resource_group.kube-rg.location
  resource_group_name = azurerm_resource_group.kube-rg.name

  ip_configuration {
    name = "vm_ipconfig"
    #already exsitng subnet with nsg attached
    subnet_id                     = "/subscriptions/ee7895f1-8afc-49c0-91cf-cf21219d8fdb/resourceGroups/kube-rg/providers/Microsoft.Network/virtualNetworks/vnet-1/subnets/web-subnet"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "pip"
  location            = azurerm_resource_group.kube-rg.location
  resource_group_name = azurerm_resource_group.kube-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}




resource "azurerm_virtual_machine" "Terraformvm" {
  name                  = "vm"
  location              = azurerm_resource_group.kube-rg.location
  resource_group_name   = azurerm_resource_group.kube-rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage" #change to "Attach" from "FromImage" if already exsiting with the name
    managed_disk_type = "Standard_LRS"
    #managed_disk_id = azurerm_managed_disk.os_disk.id
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "azuser"

  }
  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azuser/.ssh/authorized_keys"
      key_data = file("${path.module}/id_rsa.pub")
    }
  }
}
