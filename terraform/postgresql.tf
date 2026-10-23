resource "azurerm_postgresql_flexible_server" "bg" {
  name                = "urlshortener-bg-demo-psql"
  resource_group_name = azurerm_resource_group.bg.name
  location            = azurerm_resource_group.bg.location

  version                       = "16"
  delegated_subnet_id           = azurerm_subnet.postgres.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false

  administrator_login    = var.postgres_admin
  administrator_password = var.postgres_password

  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768

  backup_retention_days = 7

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres
  ]

  tags = {
    project = "url-shortener-blue-green"
  }
}

resource "azurerm_postgresql_flexible_server_database" "bg" {
  name      = "urlshortener"
  server_id = azurerm_postgresql_flexible_server.bg.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

