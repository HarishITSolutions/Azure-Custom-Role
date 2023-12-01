locals {
  roleSource = yamldecode(file("${path.root}/${var.sourcecustrole-YAML}"))
  croles     = local.roleSource.CustomRoles
}

module "RoleAssignmentCreation" {
  source     = "./modules/roleassignment/"
  input      = local.croles
  sourcecustroleYAML = var.sourcecustrole-YAML
}
