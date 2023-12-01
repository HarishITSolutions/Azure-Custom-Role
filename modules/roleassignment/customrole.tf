locals {
  croles_map = { for croles in var.input : croles.RoleName => croles }
}


resource "azurerm_role_definition" "customrole" {
  for_each = { for croles in local.croles_map : croles.RoleName => croles }

  name        = each.value.RoleName
  scope       = "/providers/Microsoft.Management/managementGroups/${each.value.scope}"
  description = each.value.Description

  permissions {
    actions     = each.value.actions
    not_actions = []
  }

  assignable_scopes = []
}