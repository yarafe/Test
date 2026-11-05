output "managed_vm_count" {
  description = "Number of VMs whose agent extensions remain managed."
  value       = length(azurerm_virtual_machine_extension.forticnapp)
}
