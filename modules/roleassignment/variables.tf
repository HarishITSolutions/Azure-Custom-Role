variable "scope" {
  description = "List of Custom Roles"
  type = list(object({
    Name               = string
    RoleName           = string
    // ParentManagementGroup = string
    // GroupLevel            = number
  }))
}

variable "sourcecustroleYAML" {
  type = string
}