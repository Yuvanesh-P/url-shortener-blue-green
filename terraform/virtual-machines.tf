
resource "azurerm_network_interface" "blue" {
  name                = "nic-urlshortener-blue"
  location            = azurerm_resource_group.bg.location
  resource_group_name = azurerm_resource_group.bg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.bg.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "green" {
  name                = "nic-urlshortener-green"
  location            = azurerm_resource_group.bg.location
  resource_group_name = azurerm_resource_group.bg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.bg.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "blue" {
  identity {
    type = "SystemAssigned"
  }
  name                = "vm-urlshortener-blue"
  resource_group_name = azurerm_resource_group.bg.name
  location            = azurerm_resource_group.bg.location
  size                = var.vm_size
  admin_username      = var.admin_username

  custom_data = filebase64("${path.module}/../app-deployment/cloud-init-blue.yaml")

  network_interface_ids = [
    azurerm_network_interface.blue.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = {
    project = "url-shortener-blue-green"
    color   = "blue"
    version = "v1"
  }
}

resource "azurerm_linux_virtual_machine" "green" {
  identity {
    type = "SystemAssigned"
  }
  name                = "vm-urlshortener-green"
  resource_group_name = azurerm_resource_group.bg.name
  location            = azurerm_resource_group.bg.location
  size                = var.vm_size
  admin_username      = var.admin_username

  custom_data = filebase64("${path.module}/../app-deployment/cloud-init-green.yaml")

  network_interface_ids = [
    azurerm_network_interface.green.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = {
    project = "url-shortener-blue-green"
    color   = "green"
    version = "v2"
  }
}
