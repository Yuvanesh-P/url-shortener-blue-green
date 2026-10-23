data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "app" {
  name                          = "kvusbg-${substr(sha256(var.subscription_id), 0, 12)}"
  location                      = azurerm_resource_group.bg.location
  resource_group_name           = azurerm_resource_group.bg.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  public_network_access_enabled = true
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false

  tags = {
    project = "url-shortener-blue-green"
  }
}

resource "azurerm_role_assignment" "github_kv_secrets_officer" {
  scope                = azurerm_key_vault.app.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = "7b33ec79-400a-4f74-8c35-798400a84d37"
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "blue_kv_secrets_user" {
  scope                = azurerm_key_vault.app.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine.blue.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "green_kv_secrets_user" {
  scope                = azurerm_key_vault.app.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine.green.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}