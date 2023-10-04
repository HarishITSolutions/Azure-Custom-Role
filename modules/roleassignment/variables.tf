variable "scope" {
  description = "List of management groups"
  type = list(object({
    Name                  = string
    DisplayName           = string
    ParentManagementGroup = string
    GroupLevel            = number
  }))
}

variable "custroleYAML" {
  type = string
}