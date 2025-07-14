# NAT Gateway Migration to FortiGate VM

## Introduction

This documentation provides a structured approach to **migrating outbound internet traffic** in Azure from the native **NAT Gateway** to a **FortiGate Next-Generation Firewall (FGT-VM)**.

Azure NAT Gateway is a managed solution that provides outbound internet access for resources in private subnets. However, in many enterprise and security-conscious environments, its functionality may not fully meet advanced networking and security requirements.

If your organization needs deep security, visibility, and control over outbound traffic, a FortiGate VM (FGT-VM) is the natural upgrade path. FortiGate acts not just as a NAT device but as a next-generation firewall (NGFW) capable of enforcing comprehensive security policies, logging, and traffic inspection.


## Migration Use Cases

- Traffic inspection, inbound and outbound connctivity, session controll and visibility 
- Azure NAT Gateway operates at the subnet level and automatically assigns a public IP for outbound traffic from virtual machines. You cannot configure the specific public IP or source port used per VM. In contrast, FortiGate provides full control over source IP, ports, and NAT behavior through customizable policies. 
- Some customers prefer deterministic routing through their own ISPs or wish to avoid using Microsoft’s backbone network for specific data paths, often to optimize routing and reduce latency. However, NAT Gateway does not support Public IP addresses with a routing preference set to "Internet." This requirement can be achieved using a FortiGate (FGT) VM.
- Azure NAT Gateway supports a maximum of 16 public IP addresses [link](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-nat-gateway-limits). If your deployment requires more, consider using a FortiGate (FGT) VM, which can handle up to 256 public IPs through multiple NICs and advanced NAT configurations [link1](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-resource-manager-virtual-networking-limits) [link2](https://community.fortinet.com/t5/FortiGate/Technical-Tip-FortiGate-can-create-max-32-secondary-IP-address/ta-p/230121).
- Session visibility 
- NAT Gateway doesn't support IPv6 
- some other limitations


## FortiGate Key Features and NAT Gateway Limitations

Azure NAT Gateway offers simple outbound access with limited control. FortiGate enhances this with:

- Advanced security (IPS, antivirus, URL filtering)
- Full session visibility and logging
- Inbound & outbound NAT support
- Custom connection timeouts and granular policy control
- Compliance with enterprise security standards (PCI, HIPAA, etc.)


| Feature               | NAT Gateway    | FortiGate VM         |
| --------------------- | -------------- | -------------------- |
| Outbound Access       | ✅ Yes          | ✅ Yes                |
| Inbound NAT           | ❌ No           | ✅ Yes                |
| Security Inspection   | ❌ None         | ✅ NGFW               |
| Availability Zones    | ✅ Yes          | ✅ Yes (only with HA deployment)          |
| Session Visibility    | Basic NSG logs | Full session logging |
| Configurable Public IP and Source Port | Dynamic       | Fully customizable   |
| Configurable Timeouts | TCP and UDP timeout fixed      | Fully customizable   |
| Public IP routing preference             | Only Microsoft Network   | Both Microsoft Network and Internet |
| Public IP addresses   | 16               | up to 256              |
| IP Fragmentation       | ❌ No          | ✅ Yes                |
| ICMP      | ❌ No         | ✅ Yes (HA-SDN or Single FGT VM deployment)               |
| Public IPs with DDoS protection      | ❌ No         | ✅ Yes              |
| IPV6 Support          | ❌ NO          | ✅ Yes (HA-SDN or Single FGT VM deployment)                |
| Security Compliance   | Limited | ✅ Yes|

## Migration Steps



## Support

Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/40net-cloud/terraform-azure-fortigate/issues) tab of this GitHub project.

## License

[License](/../../blob/main/LICENSE) © Fortinet Technologies. All rights reserved.
