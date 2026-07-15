# FortiNAC

:wave: - [Introduction](#introduction) - [Design](#design) - [Deployment](#deployment) - [Post-deployment configuration](#post-deployment-configuration) :wave:

## Introduction

FortiNAC is a zero-trust access solution that oversees and protects all digital assets connected to the enterprise network, covering devices ranging from IT, IoT, OT/ICS, to IoMT. It provides visibility, control, and automated response for everything that connects to the network.

FortiNAC operates out-of-band: it manages network devices (switches, wireless controllers, firewalls) over SNMP, SSH, and RADIUS rather than sitting inline in the data path. This makes Microsoft Azure a natural place to host it. The main use case for FortiNAC in Azure is a **centrally hosted NAC deployment**: the FortiNAC VM runs in Azure and manages on-premises network infrastructure — across one or multiple sites — over a VPN or ExpressRoute connection, without requiring an appliance in every location. Endpoints authenticate and get profiled through the local switches and access points, while policy decisions and enforcement are driven from the FortiNAC instance in Azure.

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

> [!WARNING]
> No credentials are set during deployment. The FortiNAC appliance boots with **factory default credentials**: CLI via serial console `admin` with an empty password, and Admin UI (HTTPS port 8443) `root` / `YAMS`. Change both immediately after the first login — see [Post-deployment configuration](#post-deployment-configuration).

> [!NOTE]
> Licensing is done after deployment by registering the appliance UUID and MAC address on [support.fortinet.com](https://support.fortinet.com) and downloading the license keys. See [Generate and download keys](https://docs.fortinet.com/document/fortinac-f/7.6.0/azure-deployment-guide/14971/generate-and-download-keys).

### Azure Portal

Azure Portal Wizard:
[![Azure Portal Wizard](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fyarafe%2FTest%2Fmain%2FFortiNAC%2Fsingle%2FmainTemplate.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fyarafe%2FTest%2Fmain%2FFortiNAC%2Fsingle%2FcreateUiDefinition.json)

Custom deployment:
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fyarafe%2FTest%2Fmain%2FFortiNAC%2Fsingle%2FmainTemplate.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fyarafe%2FTest%2Fmain%2FFortiNAC%2Fsingle%2FmainTemplate.json)

## Post-deployment configuration

### First access and licensing

1. **Login via the serial console** with the default credentials: user `admin` and an empty password. You will be prompted to set a new password.

2. **Collect the UUID and MAC address** required for licensing:

   ```
   get hardware status
   ```

   Note the `UUID` and `MAC` values from the output.

3. **Register the product** on [support.fortinet.com](https://support.fortinet.com) using the UUID and MAC address, then generate and download the license keys. See [Generate and download keys](https://docs.fortinet.com/document/fortinac-f/7.6.0/azure-deployment-guide/14971/generate-and-download-keys) in the Azure Deployment Guide.

4. **Verify the management interface configuration** on `port1`. The interface uses DHCP and must allow HTTPS Admin UI and SSH access:

   ```
   config system interface
     edit port1
       set mode dhcp
       set allowaccess https-adminui ssh
     next
   end
   ```

   The Admin UI is served on **HTTPS port 8443** — make sure TCP 8443 is allowed in the Network Security Group to reach the GUI.

5. **Login to the Admin UI** at `https://<port1-ip>:8443` using the default FortiNAC Admin UI credentials: user `root`, password `YAMS`. Change this password immediately after the first login.

### Config Wizard

After the first login, the initial appliance configuration is completed using the FortiNAC **Config Wizard**, used in conjunction with the [FortiNAC-F Deployment Guide](https://docs.fortinet.com/document/fortinac-f/7.6.0/fortinac-deployment-guide/452316/overview). For virtual appliances, the appliance is reached over `port1`.

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
