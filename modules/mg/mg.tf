# Azure Management Group Locals
locals {
  management_groups_map = { for mg in var.scope : mg.Name => mg }
}

# Create Level 1 Management Groups
resource "azurerm_management_group" "mg_level_1" {
  for_each = { for mg in local.management_groups_map : mg.Name => mg if mg.GroupLevel == 1 }

  name                       = each.value.Name
  display_name               = each.value.DisplayName
  parent_management_group_id = "/providers/Microsoft.Management/managementGroups/${each.value.ParentManagementGroup}"

  lifecycle {
    # Avoid unnecessary updates
    ignore_changes = [name]
  }
}

# Create Level 2 Management Groups
resource "azurerm_management_group" "mg_level_2" {
  for_each = { for mg in local.management_groups_map : mg.Name => mg if mg.GroupLevel == 2 }

  name                       = each.value.Name
  display_name               = each.value.DisplayName
  parent_management_group_id = "/providers/Microsoft.Management/managementGroups/${each.value.ParentManagementGroup}"
  depends_on                 = [azurerm_management_group.mg_level_1]

  lifecycle {
    # Avoid unnecessary updates
    ignore_changes = [name]
  }
}

# Create Level 3 Management Groups
resource "azurerm_management_group" "mg_level_3" {
  for_each = { for mg in local.management_groups_map : mg.Name => mg if mg.GroupLevel == 3 }

  name                       = each.value.Name
  display_name               = each.value.DisplayName
  parent_management_group_id = "/providers/Microsoft.Management/managementGroups/${each.value.ParentManagementGroup}"
  depends_on                 = [azurerm_management_group.mg_level_2]

  lifecycle {
    # Avoid unnecessary updates
    ignore_changes = [name]
  }
}

# Create Level 4 Management Groups
resource "azurerm_management_group" "mg_level_4" {
  for_each = { for mg in local.management_groups_map : mg.Name => mg if mg.GroupLevel == 4 }

  name                       = each.value.Name
  display_name               = each.value.DisplayName
  parent_management_group_id = "/providers/Microsoft.Management/managementGroups/${each.value.ParentManagementGroup}"
  depends_on                 = [azurerm_management_group.mg_level_3]

  lifecycle {
    # Avoid unnecessary updates
    ignore_changes = [name]
  }
}

# Create Level 5 Management Groups
resource "azurerm_management_group" "mg_level_5" {
  for_each = { for mg in local.management_groups_map : mg.Name => mg if mg.GroupLevel == 5 }

  name                       = each.value.Name
  display_name               = each.value.DisplayName
  parent_management_group_id = "/providers/Microsoft.Management/managementGroups/${each.value.ParentManagementGroup}"
  depends_on                 = [azurerm_management_group.mg_level_4]

  lifecycle {
    # Avoid unnecessary updates
    ignore_changes = [name]
  }
}

# Azure Role Assignment Locals - 1
locals {
  mgSource = yamldecode(file("${path.root}/${var.sourceMGYAML}"))
  dynamic_role_assignments = flatten([
    for mg in local.mgSource.managementGroups : [
      for eachrole in mg.roleassignments : {
        roleenabled = mg.roleAssignmentsEnabled
        mgName      = mg.Name
        pName       = eachrole.principal
        type        = eachrole.type
        rName       = eachrole.role
      }
      if mg.roleAssignmentsEnabled
    ]
  ])
}

# Read UPN of Users
data "azuread_user" "users" {
  for_each            = { for ra in local.dynamic_role_assignments : "${ra.mgName}-${ra.pName}-${ra.rName}" => ra if ra.roleenabled == true && ra.type == "user" }
  user_principal_name = each.value.pName
}

# Read Display Name of Groups
data "azuread_group" "groups" {
  for_each     = { for ra in local.dynamic_role_assignments : "${ra.mgName}-${ra.pName}-${ra.rName}" => ra if ra.roleenabled == true && ra.type == "group" }
  display_name = each.value.pName
}

# Read Display Name of ServicePrincipal
data "azuread_service_principal" "servicePrincipal" {
  for_each     = { for ra in local.dynamic_role_assignments : "${ra.mgName}-${ra.pName}-${ra.rName}" => ra if ra.roleenabled == true && ra.type == "ServicePrincipal" }
  display_name = each.value.pName
}

# Azure Role Assignment Locals - 2
locals {
  get_principal_id = {
    for ra in local.dynamic_role_assignments : "${ra.mgName}-${ra.pName}-${ra.rName}" => {
      user             = ra.type == "user" ? try(data.azuread_user.users["${ra.mgName}-${ra.pName}-${ra.rName}"].id, null) : null
      group            = ra.type == "group" ? try(data.azuread_group.groups["${ra.mgName}-${ra.pName}-${ra.rName}"].id, null) : null
      ServicePrincipal = ra.type == "ServicePrincipal" ? try(data.azuread_service_principal.servicePrincipal["${ra.mgName}-${ra.pName}-${ra.rName}"].object_id, null) : null
    }
  }
}

# Create Role Assignments
resource "azurerm_role_assignment" "roles" {
  for_each = { for idx, ra in local.dynamic_role_assignments : idx => ra }

  principal_id         = lookup(local.get_principal_id["${each.value.mgName}-${each.value.pName}-${each.value.rName}"], each.value.type, null)
  role_definition_name = each.value.rName
  scope                = "/providers/Microsoft.Management/managementGroups/${each.value.mgName}"
  depends_on           = [azurerm_management_group.mg_level_1, azurerm_management_group.mg_level_2, azurerm_management_group.mg_level_3, azurerm_management_group.mg_level_4, azurerm_management_group.mg_level_5]

  lifecycle {
    # Avoid unnecessary updates
    ignore_changes = [role_definition_name, principal_id, scope]
  }
}

# Azure Role Assignment Locals
# locals {
#   mgSource = yamldecode(file("${path.root}/${var.sourceMGYAML}"))
#   dynamic_role_assignments = flatten([
#     for mg in local.mgSource.managementGroups : [
#       for eachrole in mg.roleassignments : {
#         roleenabled = mg.roleAssignmentsEnabled
#         mgName      = mg.Name
#         pName       = eachrole.principal
#         type        = eachrole.type
#         rName       = eachrole.role
#       }
#       if mg.roleAssignmentsEnabled
#     ]
#   ])
# }

# Create Role Assignments
# resource "azurerm_role_assignment" "roles" {
#   for_each = { for idx, ra in local.dynamic_role_assignments : idx => ra }

#   principal_id         = each.value.pName
#   role_definition_name = each.value.rName
#   scope                = "/providers/Microsoft.Management/managementGroups/${each.value.mgName}"
#   depends_on           = [azurerm_management_group.mg_level_1, azurerm_management_group.mg_level_2, azurerm_management_group.mg_level_3, azurerm_management_group.mg_level_4, azurerm_management_group.mg_level_5]

#   lifecycle {
#     # Avoid unnecessary updates
#     ignore_changes = [role_definition_name, principal_id, scope]
#   }
# }

# Azure Initiative Locals
locals {
  flattened_initiative_assignment = flatten([
    for mg in local.mgSource.managementGroups :
    mg.initiativeAssignmentEnabled && mg.initiativeAssignment != null ? [
      for eachInitiativeAssignment in mg.initiativeAssignment : {
        mgName         = mg.Name
        parentMGName   = mg.ParentManagementGroup
        initiativeID   = eachInitiativeAssignment.initiativeName
        assignmentName = eachInitiativeAssignment.assignmentName
      }
    ] : [] # Add this if else condition, if initiativeAssignmentEnabled is false resource(azurerm_management_group_policy_assignment) will ignore creation, else initiative_assignment will be created. 
  ])
}

# Azure Intiative Assignment
resource "azurerm_management_group_policy_assignment" "initiative_assignment" {
  for_each = { for idx, p in local.flattened_initiative_assignment : idx => p }

  name                 = each.value.assignmentName
  policy_definition_id = "/providers/Microsoft.Management/managementGroups/${var.rootMG}/providers/Microsoft.Authorization/policySetDefinitions/${each.value.initiativeID}"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/${each.value.mgName}"
  #depends_on           = [azurerm_role_assignment.roles, data.azuread_user.users, data.azuread_group.groups, data.azuread_service_principal.servicePrincipal]
  depends_on = [azurerm_role_assignment.roles]
  location   = "EastUS"

  identity {
    type = "SystemAssigned"
  }
}

# Azure Custom Policy Assignment Locals
locals {
  flattened_policy_assignment = flatten([
    for mg in local.mgSource.managementGroups :
    mg.customPolicyAssignmentEnabled && mg.customPolicyAssignment != null ? [
      for eachPolicyAssignment in mg.customPolicyAssignment : {
        parentMGName         = mg.ParentManagementGroup
        mgName               = mg.Name
        policyDefinitionName = eachPolicyAssignment.policyName
        assignmentId         = eachPolicyAssignment.assignmentName
      }
    ] : [] # Add this if else condition, if customPolicyAssignmentEnabled is false resource(azurerm_management_group_policy_assignment) will ignore creation, else custom_policy_assignment will be created. 
  ])
}

# Azure Custom Policy Assignment
resource "azurerm_management_group_policy_assignment" "custom_policy_assignment" {
  for_each = { for idx, p in local.flattened_policy_assignment : idx => p }

  name                 = each.value.assignmentId
  policy_definition_id = "/providers/Microsoft.Management/managementGroups/${var.rootMG}/providers/Microsoft.Authorization/policyDefinitions/${each.value.policyDefinitionName}"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/${each.value.mgName}"
  depends_on           = [azurerm_management_group_policy_assignment.initiative_assignment]
  location             = "EastUS"

  identity {
    type = "SystemAssigned"
  }
}

# Azure Built-in Policy Assignment Locals
locals {
  flattened_policy_builtin_assignment = flatten([
    for mg in local.mgSource.managementGroups :
    mg.builtinPolicyAssignmentEnabled && mg.builtinPolicyAssignment != null ? [
      for policies in mg.builtinPolicyAssignment : {
        parentMGName       = mg.ParentManagementGroup
        mgName             = mg.Name
        policyDefinitionID = policies.policyName
        assignmentId       = policies.assignmentName
      }
    ] : [] # Add this if else condition, if builtinPolicyAssignmentEnabled is false resource(azurerm_management_group_policy_assignment) will ignore creation, else builtin_policy_assignment will be created. 
  ])
}

# Azure Built-in Policy Assignment
resource "azurerm_management_group_policy_assignment" "builtin_policy_assignment" {
  for_each = { for idx, p in local.flattened_policy_builtin_assignment : idx => p }

  name                 = each.value.assignmentId
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/${each.value.policyDefinitionID}"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/${each.value.mgName}"
  depends_on           = [azurerm_management_group_policy_assignment.custom_policy_assignment]
  location             = "EastUS"

  identity {
    type = "SystemAssigned"
  }
}

