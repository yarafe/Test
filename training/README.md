# Terraform CH1 Errors

The examples focus on two common Terraform troubleshooting patterns:

1. **Provider schema changes** — an argument is no longer supported because its name changed.
2. **Resource dependency and attribute references** — manually constructing an Azure resource ID can cause Terraform to miss the dependency on the resource being referenced.

## 1. Unsupported Argument: `enable_ip_forwarding`

### Error

```text
Error: Unsupported argument

  on main.tf line 163, in resource "azurerm_network_interface" "external":
  163:   enable_ip_forwarding = true

An argument named "enable_ip_forwarding" is not expected here.
```

### Root Cause

The AzureRM provider changed the property name for IP forwarding on `azurerm_network_interface`.

In **AzureRM 4.x**, the deprecated `enable_ip_forwarding` property was removed and replaced with `ip_forwarding_enabled`.

### Fix

Replace:

```hcl
enable_ip_forwarding = true
```

with:

```hcl
ip_forwarding_enabled = true
```

## 2. Virtual Machine Not Found When Attaching a Data Disk

### Error

```text
Error: Virtual Machine (Subscription: ""
Resource Group Name: "tf-fgt-rg"
Virtual Machine Name: "tf-fgt") was not found

  with azurerm_virtual_machine_data_disk_attachment.fgt_data,
  on main.tf line 281, in resource "azurerm_virtual_machine_data_disk_attachment" "fgt_data":
  281: resource "azurerm_virtual_machine_data_disk_attachment" "fgt_data" {
```

### Original Configuration

The VM ID was manually constructed as a string:

```hcl
virtual_machine_id = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.fgt.name}/providers/Microsoft.Compute/virtualMachines/${var.prefix}-fgt"
```

### Recommended Fix

Reference the Terraform-managed VM resource directly:

```hcl
virtual_machine_id = azurerm_linux_virtual_machine.fgt.id
```
### Why This Is Better

Terraform understands references between resources. By using:

```hcl
azurerm_linux_virtual_machine.fgt.id
```

Terraform creates an **implicit dependency** between the disk attachment and the Linux VM.

The attachment therefore depends on the VM resource being created and its ID being available.

By contrast, this:

```hcl
"/subscriptions/${var.subscription_id}/.../virtualMachines/${var.prefix}-fgt"
```

is primarily just a string assembled from variables and attributes. Terraform does not get a direct dependency on `azurerm_linux_virtual_machine.fgt` from that expression.


