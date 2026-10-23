output "load_balancer_public_ip" {
  description = "Public IP address of the Blue-Green Load Balancer"
  value       = azurerm_public_ip.lb.ip_address
}

output "load_balancer_fqdn" {
  description = "Public DNS name of the Load Balancer"
  value       = azurerm_public_ip.lb.fqdn
}

output "postgres_server_fqdn" {
  description = "Private PostgreSQL server hostname"
  value       = azurerm_postgresql_flexible_server.bg.fqdn
}

output "active_color" {
  description = "Currently configured active backend color"
  value       = var.active_color
}
output "key_vault_name" {
  description = "Key Vault used for application secrets"
  value       = azurerm_key_vault.app.name
}