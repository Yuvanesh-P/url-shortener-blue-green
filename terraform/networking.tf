resource "azurerm_resource_group" "bg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    project = "url-shortener-blue-green"
    managed = "terraform"
  }
}

resource "azurerm_virtual_network" "bg" {
  name                = "vnet-urlshortener-bg"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.bg.location
  resource_group_name = azurerm_resource_group.bg.name
}

resource "azurerm_subnet" "bg" {
  name                 = "snet-urlshortener-bg"
  resource_group_name  = azurerm_resource_group.bg.name
  virtual_network_name = azurerm_virtual_network.bg.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_network_security_group" "bg" {
  name                = "nsg-urlshortener-bg"
  location            = azurerm_resource_group.bg.location
  resource_group_name = azurerm_resource_group.bg.name

  security_rule {
    name                       = "Allow-HTTP-From-Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-LB-Health-Probe"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "bg" {
  subnet_id                 = azurerm_subnet.bg.id
  network_security_group_id = azurerm_network_security_group.bg.id
}

resource "azurerm_subnet" "postgres" {
  name                 = "snet-urlshortener-postgres"
  resource_group_name  = azurerm_resource_group.bg.name
  virtual_network_name = azurerm_virtual_network.bg.name
  address_prefixes     = ["10.20.2.0/24"]

  delegation {
    name = "postgres-flexible-server-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "urlshortener-bg.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.bg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "urlshortener-bg-postgres-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.bg.id
  resource_group_name   = azurerm_resource_group.bg.name
}
