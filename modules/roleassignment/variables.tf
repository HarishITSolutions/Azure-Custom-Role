variable "input" {
  description = "List of Custom Roles"
  type = list(object({
    scope              = string
    RoleName           = string
    Description        = string
    actions            = string
  }))
}

variable "sourcecustroleYAML" {
  type = string
}