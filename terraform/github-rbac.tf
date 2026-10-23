resource "azurerm_role_assignment" "github_actions" {
  scope                = azurerm_resource_group.bg.id
  role_definition_name = "Contributor"
  principal_id         = "7b33ec79-400a-4f74-8c35-798400a84d37"
  principal_type       = "ServicePrincipal"
}
