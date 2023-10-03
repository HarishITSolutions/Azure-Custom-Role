module "RoleAssignmentCreation" {
  source     = "./modules/roleassignment/"
}


module "PolicyandInitiativeCreation" {
  source     = "./modules/policy/"
  sourceYAML = var.sourcePolicyYAML
}

locals {
  mgSource = yamldecode(file("${path.root}/${var.sourceMG-YAML}"))
  mg       = local.mgSource.managementGroups
}

module "MG-RA-POL-INI-Assignment" {
  source       = "./modules/mg/"
  scope        = local.mg
  sourceMGYAML = var.sourceMG-YAML
  rootMG       = var.tenantrootMG
  #depends_on   = [module.PolicyandInitiativeCreation]
}