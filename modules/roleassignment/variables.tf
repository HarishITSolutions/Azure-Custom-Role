variable "input" {
  description = "List of Custom Roles"
  type = list(object({
    Name               = string
    RoleName           = string
    Description        = string
    // GroupLevel            = number
  }))
}

variable "sourcecustroleYAML" {
  type = string
}