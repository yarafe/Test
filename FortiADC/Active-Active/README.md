# FortiADC - Active/Active-VRRP

## Introduction

FortiADC is part of Fortinet's family of Application Delivery Controllers (ADC), designed to enhance the performance, availability, and security of enterprise applications.
It acts like an advanced load balancer, directing traffic to the most suitable backend servers using health checks and load-balancing algorithms.

## Design

FortiADC Active/Active-VRRP environment consists of:

- 2 standalone FortiADC virtual machine with 2 NICs: external and internal.
- 1 VNETs containing 2 subnets: external and internal.
- 2 Standard public IPs attached to port1 interface for management in each VM.
- Network security group (NSG) which allows inbound HTTP, SSH, unicast HA heartbeat and HA configuration synchronization traffic.

![FortiADC-VRRP-A-A azure design](images/fad-vrrp-a-a.png)

## Deployment

### Azure Portal

Azure Portal Wizard:
[![Azure Portal Wizard](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiWeb%2FActive-Active%2FmainTemplate.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiWeb%2FActive-Active%2FcreateUiDefinition.json)

Custom Deployment:
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiWeb%2FActive-Active%2FmainTemplate.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions$2Fmain%2FFortiWeb%2FActive-Active%2FmainTemplate.json)

## Configuration

**Configure HA on FortiADC1**

<code><pre>
config system ha
set mode active-active-vrrp
set hbdev port2
set datadev port2
set group-id 31
set local-node-id 1
set group-name azure_group
set config-priority 200
set override enable
set l7-persistence-pickup enable
set l4-persistence-pickup enable
set l4-session-pickup enable
set hb-type unicast
set local-address 172.16.136.69
set peer-address 172.16.136.70
end
</code></pre>

**Configure HA on FortiADC2**

<code><pre>
config system ha
set mode active-active-vrrp
set hbdev port2
set datadev port2
set group-id 31
set group-name azure_group
set override enable
set l7-persistence-pickup enable
set l4-persistence-pickup enable
set l4-session-pickup enable
set hb-type unicast
set local-address 172.16.136.70
set peer-address 172.16.136.69
end
</code></pre>

## Support

Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/40net-cloud/fortinet-azure-solutions/issues) tab of this GitHub project.

## License

[License](/../../blob/main/LICENSE) © Fortinet Technologies. All rights reserved.
