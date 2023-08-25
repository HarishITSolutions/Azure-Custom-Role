# File decode
locals {
  policySource = yamldecode(file("${path.root}/${var.sourceYAML}"))
}

# Policy Definition locals
locals {
  flattened_policies = flatten([
    for mg in local.policySource.policyrootctrl :
    [
      for policy in mg.policies :
      {
        mgName = mg.scope
        policyValue = jsondecode(
          file("${path.root}/policies/${mg.scope}/${policy}.json")
        )
      }
    ]
  ])
}

# Azure Policy Definition
resource "azurerm_policy_definition" "policies" {
  for_each = { for idx, p in local.flattened_policies : idx => p }

  name                = each.value.policyValue.properties.Name
  management_group_id = "/providers/Microsoft.Management/managementGroups/${each.value.mgName}"
  policy_type         = "Custom"
  mode                = each.value.policyValue.properties.mode
  display_name        = each.value.policyValue.properties.displayName
  description         = each.value.policyValue.properties.description
  metadata            = jsonencode(each.value.policyValue.properties.metadata)
  policy_rule         = jsonencode(each.value.policyValue.properties.policyRule)
  parameters          = jsonencode(each.value.policyValue.properties.parameters)

  lifecycle {
    # Use ignore_changes to ignore changes in below attributes
    ignore_changes = [
      name,
      display_name,
      description,
      metadata,
      parameters,
      policy_rule,
      management_group_id
    ]
  }
}

# Set Definition locals
locals {
  initiatives_mapping = flatten([
    for mg in local.policySource.policyrootctrl :
    [
      for init in mg.initiatives :
      {
        mgName                = mg.scope
        initiativeName        = init.name
        initiativeDisplayName = init.displayName
        initiativeDescription = init.description
        policy_id             = init.Policies
      }
    ]
  ])
}


# Azure Policy Initiative
resource "azurerm_policy_set_definition" "initiatives" {
  for_each = {
    for initiative in local.initiatives_mapping :
    "${initiative.mgName}-${initiative.initiativeName}" => initiative
  }

  name                = each.value.initiativeName
  management_group_id = "/providers/Microsoft.Management/managementGroups/${each.value.mgName}"
  policy_type         = "Custom"
  display_name        = each.value.initiativeDisplayName
  description         = each.value.initiativeDescription
  depends_on          = [azurerm_policy_definition.policies]
  dynamic "policy_definition_reference" {
    for_each = toset(each.value.policy_id)

    content {
      policy_definition_id = "/providers/Microsoft.Management/managementGroups/${each.value.mgName}/providers/Microsoft.Authorization/policyDefinitions/${policy_definition_reference.value}"
      reference_id         = policy_definition_reference.key
    }
  }
}
