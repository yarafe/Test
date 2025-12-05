# FortiGate VM Backup and Restore in Azure

[![[FGT] ARM - A-Single-VM](https://github.com/40net-cloud/fortinet-azure-solutions/actions/workflows/fgt-arm-a-single-vm.yml/badge.svg)](https://github.com/40net-cloud/fortinet-azure-solutions/actions/workflows/fgt-arm-a-single-vm.yml) 

:wave: - [Introduction](#introduction) - [Design](#design) - [Deployment](#deployment) - [Requirements](#requirements-and-limitations) - [Configuration](#configuration) - :wave:

# Introduction

Backing up and restoring FortiGate Virtual Machines (VMs) in Microsoft Azure is a critical part of maintaining business continuity, minimizing downtime, and protecting firewall configurations against data loss or corruption. This document provides a comprehensive overview of the procedures and best practices for creating, managing, and restoring backups of FortiGate VMs deployed in Azure environments. 
To protect your FortiGate configurations and data, you can use several backup methods including: 
- Backup FortiGate VM with agentless multi-disk crash-consistent.
- Taking Azure-managed disk snapshots at scheduled intervals.
You can also back up only the FortiGate configuration as described in the [documentation](https://docs.fortinet.com/document/fortigate/7.6.4/administration-guide/702257)

## Backup FortiGate VM with Agentless Multi-Disk Crash-Consistent

Azure Backup provides agentless VM backups using multi-disk crash-consistent restore points, available only with the Enhanced VM Backup Policy and supported in all Azure public regions. It supports Premium Storage–capable VM sizes (those with an “s” in the name, e.g., DSv2).
Unsupported disks include Ultra Disks, Premium SSD v2, Ephemeral OS Disks, Shared Disks, and Write Accelerator–enabled disks.
For details, see [Microsoft’s guide](https://docs.fortinet.com/document/fortigate/7.6.4/administration-guide/702257).

### Backup Procedure

- Create a Recovery Services vault as described from [documentation](https://learn.microsoft.com/en-us/azure/backup/backup-create-recovery-services-vault#create-a-recovery-services-vault)
- Go to your Recovery Services vault, select Manage > Backup policies, and click + Add to create a new policy.
![Crash-Consistent Backup1](images/agentless_backup1.png)
- Select Policy type as Virtual machine, set Policy subtype to Enhanced, and choose Consistency type as Only crash-consistent snapshot to enable agentless backups.
![Crash-Consistent Backup2](images/agentless_backup2.png)
- Start configuring backup for virtual machine in Azure.
![Crash-Consistent Backup3](images/agentless_backup3.png)
- Select the Enhanced policy created in the previous step, add the FortiGate VM, and enable the backup.
![Crash-Consistent Backup4](images/agentless_backup4.png)
- Azure Backup service creates a separate resource group to store the instant recovery points of managed virtual machines. The default naming format of resource group created by Azure Backup service is AzureBackupRG_{Geo}_{n}. 
- You can backup now Fortigate VM or disable backup from protected items > Backup items.
![Crash-Consistent Backup5](images/agentless_backup5.png)

More information can be found from [link](https://learn.microsoft.com/en-us/azure/backup/backup-azure-vms-agentless-multi-disk-crash-consistent).

### Restore Procedure

You can choose the option that best fits your requirements: either deploy a new FortiGate VM or recover the faulty disk.

#### Restore FortiGate with VM image version

- Use or create [Azure compute gallery](https://learn.microsoft.com/en-us/azure/virtual-machines/create-gallery)
- Create an image definition using PowerShell

<code><pre>
$imageDefinition = New-AzGalleryImageDefinition -GalleryName yourGallery -ResourceGroupName yourRG -Location RGLocation -Name 'Fortigate' -OsState generalized -OsType Linux -Publisher 'fortinet' -Offer ' fortinet_fortigate-vm_v5' -Sku ' fortinet_fg-vm' -PurchasePlanPublisher fortinet -PurchasePlanProduct fortinet_fortigate-vm_v5 -PurchasePlanName fortinet_fg-vm -HyperVGeneration "V1" -Feature @(@{Name='IsAcceleratedNetworkSupported';Value='True'})

</code></pre>

The above PowerShell command is related to VM generation g1. For generation2 use SKU “fortinet_fg-vm_g2” and for arm64 use SKU “fortinet_fg-vm_arm64”.
More details from [link](https://learn.microsoft.com/en-us/powershell/module/az.compute/new-azgalleryimagedefinition)

- Navigate to the resource group AzureBackupRG_{Geo}_{n} where the restore point collections are stored.
![Crash-Consistent restore_image1](images/restore_image1.png)
- Select the desired restore point and choose OS_disk
![Crash-Consistent restore_image2](images/restore_image2.png)
- Click on create VM image version
![Crash-Consistent restore_image3](images/restore_image3.png)
- Add version number and select your Azure compute gallery and your VM definition
![Crash-Consistent restore_image4](images/restore_image4.png)
- Set default storage SKU and the replica count 
![Crash-Consistent restore_image5](images/restore_image5.png)

Once VM image version is created, you can use it to deploy a new FortiGate instance.
-	Go to Fortinet [Azure solutions repository](https://github.com/40net-cloud/fortinet-azure-solutions/tree/main/FortiGate/A-Single-VM) and deploy to Azure Fortigate VM.
- During the deployment in “Advanced” tab, add the resource id of the created vm image version. 
![Crash-Consistent restore_image6](images/restore_image6.png)
- After deployment you can detach the newly created data disk and attach your existing one or alternatively create a new data disk from the restore point and attach it to the FortiGate VM.
![Crash-Consistent restore_image7](images/restore_image7.png)

## Support

Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/40net-cloud/fortinet-azure-solutions/issues) tab of this GitHub project.

## License

[License](/../../blob/main/LICENSE) © Fortinet Technologies. All rights reserved.
