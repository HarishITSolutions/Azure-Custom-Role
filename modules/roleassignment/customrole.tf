locals {
  croles_map = { for croles in var.scope : croles.Name => croles }
}


resource "azurerm_role_definition" "customrole" {
  for_each = { for croles in local.croles_map : croles.RoleName => croles }

  name        = each.value.RoleName
  scope       = "/providers/Microsoft.Management/managementGroups/${each.value.Name}"
  description = each.value.Description

  permissions {
    actions     = [
        "*/read",
        "Microsoft.Authorization/locks/delete",
        "Microsoft.Authorization/locks/write",
        "Microsoft.Authorization/policies/auditIfNotExists/action",
        "Microsoft.Authorization/roleAssignments/delete",
        "Microsoft.Authorization/roleAssignments/write",
        "Microsoft.Compute/disks/beginGetAccess/action",
        "Microsoft.Compute/disks/delete",
        "Microsoft.Compute/disks/write",
        "Microsoft.Compute/snapshots/delete",
        "Microsoft.Compute/snapshots/write",
        "Microsoft.Compute/virtualMachines/delete",
        "Microsoft.Compute/virtualMachines/write",
        "Microsoft.KeyVault/vaults/write",
        "Microsoft.Network/applicationSecurityGroups/delete",
        "Microsoft.Network/applicationSecurityGroups/joinIpConfiguration/action",
        "Microsoft.Network/applicationSecurityGroups/write",
        "Microsoft.Network/networkInterfaces/delete",
        "Microsoft.Network/networkInterfaces/join/action",
        "Microsoft.Network/networkInterfaces/write",
        "Microsoft.Network/networkSecurityGroups/delete",
        "Microsoft.Network/networkSecurityGroups/join/action",
        "Microsoft.Network/networkSecurityGroups/write",
        "Microsoft.Network/publicIpAddresses/write",
        "Microsoft.Network/publicIPAddresses/join/action",
        "Microsoft.Network/publicIPAddresses/delete",
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Resources/subscriptions/resourceGroups/delete",
        "Microsoft.Resources/subscriptions/resourceGroups/write",
        "Microsoft.Storage/storageAccounts/listKeys/action",
        "Microsoft.Compute/virtualMachines/extensions/write"
    ]
    not_actions = []
  }

  assignable_scopes = []
}