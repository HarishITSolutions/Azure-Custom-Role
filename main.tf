locals {
  roles = yamldecode(file("${path.root}/${var.sourcecustrole-YAML}")).custom_roles
}

module "RoleAssignmentCreation" {
  source     = "./modules/roleassignment/"
  sourcecustroleYAML = var.sourcecustrole-YAML
}
