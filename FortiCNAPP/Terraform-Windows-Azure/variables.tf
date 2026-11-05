variable "subscription_id" {
  type = string
}
variable "windows_vms" {
  description = "Existing Windows VMs in this subscription. Keep map keys stable."
  type = map(object({
    resource_group_name = string
    vm_name             = string
  }))
  validation {
    condition     = length(var.windows_vms) > 0 && length(distinct([for vm in values(var.windows_vms) : lower("${vm.resource_group_name}/${vm.vm_name}")])) == length(var.windows_vms)
    error_message = "Provide at least one VM, with no duplicate resource-group/VM combinations."
  }
}
variable "lacework_token" {
  type      = string
  sensitive = true
}
variable "lacework_endpoint" {
  type = string
}
variable "lacework_msi_url" {
  type = string
}
variable "lacework_ps_script" {
  type = string
}
variable "lacework_defender" {
  type    = bool
  default = false
}

variable "vm_count" {
  description = "Number of existing Windows VMs to target; must match windows_vms."
  type        = number
  validation {
    condition     = var.vm_count >= 1 && floor(var.vm_count) == var.vm_count
    error_message = "vm_count must be a positive whole number."
  }
}

