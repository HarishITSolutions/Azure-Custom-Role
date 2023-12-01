resource "azurerm_role_definition" "custom_roles" {
  for_each = { for role in local.roles : role.name => role }

  name        = each.value.name
  scope       = "/providers/Microsoft.Management/managementGroups/${each.value.scope}"
  description = each.value.Description

  permissions {
    actions = each.value.actions
    not_actions = []
  }

  assignable_scopes = []
}