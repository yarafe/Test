# FortiCNAPP Windows Agent on Azure — Terraform

Install the FortiCNAPP Windows agent on selected **existing Azure Windows VMs**, verify the service, and uninstall the agent when its Terraform extension is destroyed.

## What it does

- Targets only the VMs listed in `windows_vms`, across resource groups in one subscription.
- Installs the agent through Azure Custom Script Extension.
- Verifies that `lwdatacollector` is running using Azure Run Command.
- Uninstalls agents from selected VMs when you remove their entries and apply, or from all managed VMs with `terraform destroy`.
- Prints per-VM `[INSTALLED]` and `[UNINSTALLED]` messages after successful verification.

The configuration does not create or delete VMs, NICs, public IPs, or NSGs.

## Requirements

**On the computer running Terraform:**

- Windows with Windows PowerShell (`PowerShell.exe`).
- Terraform **1.6 or later** and Azure CLI.
- Azure permissions to manage VM extensions and invoke Run Command on the target VMs.

**On each target VM:**

- A FortiCNAPP-supported Windows Server version.
- A running VM with a healthy Azure VM Agent and extension operations enabled.
- DNS and outbound HTTPS connectivity for Azure VM operations, installer downloads, and the FortiCNAPP agent endpoint.

You also need a **FortiCNAPP Windows agent token** and the correct agent server endpoint. Azure CLI is **not required on the target VMs**.

Check for an existing Windows Custom Script Extension before deploying; reconcile it instead of creating a conflicting extension.

## Files

| File | Purpose |
|---|---|
| `main.tf` | Installation, service verification, and uninstall hook |
| `variables.tf` | Input definitions and validation |
| `outputs.tf` | Last verified agent status and managed VM count |
| `terraform.tfvars` | Your subscription, VM list, and agent settings |

## Deploy

1. Edit `terraform.tfvars`:
   - Set `subscription_id`.
   - List your existing VM names and resource groups in `windows_vms`.
   - Set `vm_count` to the number of listed VMs.
   - Set `lacework_token` and verify `lacework_endpoint`.
   - Verify `lacework_msi_url` and `lacework_ps_script` for the desired agent release.
   - Keep `lacework_defender = false` unless you want the installer to configure a Defender exclusion.

2. From the Terraform directory, run:

```powershell
az login
terraform init
terraform validate
terraform plan
terraform apply
terraform output agent_status
```

For three VMs, an initial deployment adds three Azure extensions and three Terraform verification records. It does not create VM infrastructure.

Example console message:

```text
[INSTALLED] VM=windows-vm-01 | RG=rg-production
```

`agent_status` shows the **last successful verification**, not continuous live health. Change `verification_revision` and apply to rerun checks. Setting it to `0` does not disable verification.

## Uninstall

**Selected VMs:** remove their entries from `windows_vms`, update `vm_count`, then run:

```powershell
terraform plan
terraform apply
```

Keep the remaining VM map keys unchanged. The removed VMs remain running; only their agents and installation extensions are removed.

**All managed VMs:**

```powershell
terraform plan -destroy
terraform destroy
```

Uninstall confirmations appear in the console:

```text
[UNINSTALLED] VM=windows-vm-02 | RG=rg-production
```

Target VMs must remain running and reachable through Azure Run Command. An uninstall error or pending reboot stops deletion of that extension. Resolve the issue, reboot if required, and retry.

## Notes

- Keep the Terraform state and resource blocks until removal finishes. Destroy hooks are skipped for tainted extensions, removed resource blocks, or `create_before_destroy`.
- When adopting this code into an existing deployment, preserve resource names, VM map keys, and state; review the plan for unexpected replacements.
- Do not commit real tokens, populated `terraform.tfvars`, plan files, or state files to GitHub. Sensitive values can remain in Terraform state.
- Outputs do not retain uninstall history and disappear after full destruction; save console logs if needed.
- Formatting was checked. Full validation was blocked by a local provider-cache checksum mismatch; no live Azure deployment was tested. Validate and test on a nonproduction VM first.

## References

- [Fortinet: Windows agent installation with Terraform](https://docs.fortinet.com/document/forticnapp/latest/administration-guide/768934)
- [Fortinet: Uninstalling the Windows agent](https://docs.fortinet.com/document/forticnapp/26.2.0/administration-guide/558434/uninstalling-the-windows-agent)
- [Microsoft: Azure Windows Run Command](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/run-command)
- [HashiCorp: Terraform provisioners](https://developer.hashicorp.com/terraform/language/provisioners)
