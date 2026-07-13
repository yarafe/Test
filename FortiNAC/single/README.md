# FortiNAC

:wave: - [Introduction](#introduction) - [Design](#design) - [Deployment](#deployment) - [Post-deployment configuration](#post-deployment-configuration) :wave:

## Introduction

FortiNAC is a zero-trust access solution that oversees and protects all digital assets connected to the enterprise network, covering devices ranging from IT, IoT, OT/ICS, to IoMT.

## Design

In Microsoft Azure, this single FortiNAC-VM setup is a basic setup to start exploring the capabilities.

This Azure ARM template will automatically deploy a full working environment containing the following components.

- 1 FortiNAC VM (Azure Marketplace image, FortiNAC-F 7.6.x) with a configurable data disk for log storage (100 GB by default)
- 1 VNET containing a subnet for the FortiNAC
- 1 Network Security Group
- Optional: 1 Standard public IP

This Azure ARM template can also be extended or customized based on your requirements. Additional subnets besides the ones mentioned above are not automatically generated.

The VM is deployed with a single network interface attached to `port1`, which is used for management and communication with your network infrastructure. If you plan to use an isolation network served by the FortiNAC Service Network Interface (`port2`), a second subnet and network interface are required. Configuring `port1` and `port2` in the same network is not recommended or supported.

## Deployment

For the deployment, you can use the Azure Portal, Azure CLI, Powershell or Azure Cloud Shell. The Azure ARM templates are exclusive to Microsoft Azure and can't be used in other cloud environments. The main template is the `mainTemplate.json` which you can use in the Azure Portal. You'll be prompted to provide at least the required variables:

- PREFIX : This prefix will be added to each of the resources created by the template for ease of use and visibility.
- LOCATION : This is the Azure region where the deployment will be deployed.
- USERNAME : The username used to login to the FortiNAC GUI and SSH management UI.
- PASSWORD : The password used for the FortiNAC GUI and SSH management UI.

Licensing can be provided during deployment as a BYOL license file or a FortiFlex token via the optional `FortiNACLicenseBYOL` and `FortiNACLicenseFortiFlex` parameters.

### Azure Portal

Azure Portal Wizard:
[![Azure Portal Wizard](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiNAC%2Fsingle%2FmainTemplate.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiNAC%2Fsingle%2FcreateUiDefinition.json)

Custom deployment:
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiNAC%2Fsingle%2FmainTemplate.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiNAC%2Fsingle%2FmainTemplate.json)

## Post-deployment configuration

After the VM is deployed, the initial appliance configuration is completed using the FortiNAC **Config Wizard**, used in conjunction with the [FortiNAC-F Deployment Guide](https://docs.fortinet.com/document/fortinac-f/7.6.0/fortinac-deployment-guide/452316/overview). For virtual appliances, the appliance is reached over `port1`.

Before starting the Config Wizard, have the following available:

- License key(s)
- Appliance passwords
- Appliance network addressing: hostname, IP address and network mask for `port1` and `port2`, default gateway, domain name, DNS server(s) and NTP server(s)
- At least one DHCP scope for the "isolation" VLAN (if an isolation network is used)

Notes:

- The FortiNAC Service Network Interface on `port2` serves DHCP, DNS and the Captive Portal to the "isolation" VLANs.
- Changes made in the Config Wizard are stored in a temporary file and are only applied once saved, so the data displayed may not represent the current configuration of the appliance.

For the full step-by-step procedure, see the [FortiNAC-F 7.6 Configuration Wizard guide](https://docs.fortinet.com/document/fortinac-f/7.6.0/configuration-wizard/209349/overview).

## Support
Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/40net-cloud/fortinet-azure-solutions/issues) tab of this GitHub project.

## License
[License](/../../blob/main/LICENSE) © Fortinet Technologies. All rights reserved.
