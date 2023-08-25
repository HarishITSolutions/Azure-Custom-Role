locals {
  management_groups_map = { for mg in var.scope : mg.Name => mg }
}

# Management Group
resource "azurerm_management_group" "this" {
  for_each = local.management_groups_map

  name                       = each.value.Name
  display_name               = each.value.DisplayName
  parent_management_group_id = "/providers/Microsoft.Management/managementGroups/${each.value.ParentManagementGroup}"
}

locals {
  mgSource = yamldecode(file("${path.root}/${var.sourceMGYAML}"))

  dynamic_role_assignments = flatten([
    for mg in local.mgSource.managementGroups :
    [
      for eachrole in mg.roleassignments :
      {
        mgName = mg.Name
        pName  = eachrole.principal
        type   = eachrole.type
        rName  = eachrole.role
      }
    ]
  ])
}

data "azuread_user" "users" {
  for_each            = { for ra in local.dynamic_role_assignments : ra.pName => ra if ra.type == "user" }
  user_principal_name = each.value.pName
}

data "azuread_group" "groups" {
  for_each     = { for ra in local.dynamic_role_assignments : ra.pName => ra if ra.type == "group" }
  display_name = each.value.pName
}

data "azuread_service_principal" "servicePrincipal" {
  for_each     = { for ra in local.dynamic_role_assignments : ra.pName => ra if ra.type == "ServicePrincipal" }
  display_name = each.value.pName
}


locals {
  get_principal_id = {
    for ra in local.dynamic_role_assignments : ra.pName => {
      user             = ra.type == "user" ? try(data.azuread_user.users[ra.pName].id, null) : null
      group            = ra.type == "group" ? try(data.azuread_group.groups[ra.pName].id, null) : null
      ServicePrincipal = ra.type == "ServicePrincipal" ? try(data.azuread_service_principal.servicePrincipal[ra.pName].object_id, null) : null
    }
  }
}

# Role Assignment
resource "azurerm_role_assignment" "roles" {
  for_each = { for idx, ra in local.dynamic_role_assignments : idx => ra }

  principal_id         = lookup(local.get_principal_id[each.value.pName], each.value.type, null)
  role_definition_name = each.value.rName
  scope                = "/providers/Microsoft.Management/managementGroups/${each.value.mgName}"
  depends_on           = [azurerm_management_group.this]

  lifecycle {
    # Avoid unnecessary updates
    ignore_changes = [role_definition_name]
  }
}

locals {
  flattened_policy_assignment = flatten([
    for mg in local.mgSource.managementGroups :
    mg.policyAssignmentEnabled && mg.policyAssignment != null ? [
      for eachPolicyAssignment in mg.policyAssignment :
      {
        parentMGName         = mg.ParentManagementGroup
        mgName               = mg.Name
        policyDefinitionName = eachPolicyAssignment.policyName
        assignmentName       = eachPolicyAssignment.assignmentName
      }
    ] : [] # Add this if else condition, if policyAssignmentEnabled is false resource(azurerm_management_group_policy_assignment) will ignore creation, else policy_assignment will be created. 
  ])
}

# Azure Policy Definition Assignment
resource "azurerm_management_group_policy_assignment" "policy_assignment" {
  for_each = { for idx, p in local.flattened_policy_assignment : idx => p }

  name                 = each.value.assignmentName
  policy_definition_id = "/providers/Microsoft.Management/managementGroups/${each.value.parentMGName}/providers/Microsoft.Authorization/policyDefinitions/${each.value.policyDefinitionName}"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/${each.value.mgName}"
  depends_on           = [azurerm_role_assignment.roles]
}

locals {
  flattened_initiative_assignment = flatten([
    for mg in local.mgSource.managementGroups :
    mg.initiativeAssignmentEnabled && mg.initiativeAssignment != null ? [
      for eachInitiativeAssignment in mg.initiativeAssignment :
      {
        mgName         = mg.Name
        parentMGName   = mg.ParentManagementGroup
        initiativeID   = eachInitiativeAssignment.initiativeName
        assignmentName = eachInitiativeAssignment.assignmentName
      }
    ] : [] # Add this if else condition, if initiativeAssignmentEnabled is false resource(azurerm_management_group_policy_assignment) will ignore creation, else initiative_assignment will be created. 
  ])
}

# Azure Policy Definition Assignment
resource "azurerm_management_group_policy_assignment" "initiative_assignment" {
  for_each = { for idx, p in local.flattened_initiative_assignment : idx => p }

  name                 = each.value.assignmentName
  policy_definition_id = "/providers/Microsoft.Management/managementGroups/${each.value.parentMGName}/providers/Microsoft.Authorization/policySetDefinitions/${each.value.initiativeID}"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/${each.value.mgName}"
  depends_on           = [azurerm_management_group_policy_assignment.policy_assignment]
}
