provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "WindowsSG"
  location = "eastus2"
}

resource "azurerm_virtual_network" "main" {
  name                = "vm-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "public" {
  name                 = "public"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_public_ip" "pip" {
  name                = "windows-publicip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"

 
}

resource "azurerm_network_security_group" "securityGroup" {
    name = "WindowsSG"
    resource_group_name = azurerm_resource_group.main.name
    location            = azurerm_resource_group.main.location
  
}
resource "azurerm_network_security_rule" "rdp" {
    name = "allowAllRDP"
    priority = 100
    direction = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "3389"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.securityGroup.name

  
}
resource "azurerm_network_interface" "main" {
  name                = "windows-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.securityGroup.id
}
resource "azurerm_windows_virtual_machine" "main" {
  name                            = "windows10-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_B2s"
  admin_username                  = "adminuser"
  admin_password                  = "P@ssw0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  source_image_reference {
    publisher = "microsoftwindowsdesktop"
    offer     = "windows-10"
    sku       = "win10-21h2-pro"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}