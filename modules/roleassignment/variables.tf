variable "input" {
  description = "List of Custom Roles"
  type = list(object({
    scope              = string
    RoleName           = string
    Description        = string
    // GroupLevel            = number
  }))
}

variable "sourcecustroleYAML" {
  type = string
}

variable "actionROLESYAML" {
  type = string
}