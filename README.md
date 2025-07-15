# NAT Gateway Migration to FortiGate VM

## Introduction

This documentation provides a structured approach to **migrating outbound internet traffic** in Azure from the native **NAT Gateway** to a **FortiGate Next-Generation Firewall (FGT-VM)**.

Azure NAT Gateway is a managed solution that provides outbound internet access for resources in private subnets. However, in many enterprise and security-conscious environments, its functionality may not fully meet advanced networking and security requirements.

If your organization needs deep security, visibility, and control over outbound traffic, a FortiGate VM (FGT-VM) is the natural upgrade path. FortiGate acts not just as a NAT device but as a next-generation firewall (NGFW) capable of enforcing comprehensive security policies, logging, and traffic inspection.

## Migration Use Cases

- **Enhancing Security and Compliance**
For organizations with regulatory or audit requirements, Azure NAT Gateway may not provide the level of visibility and control needed for outbound traffic. Transitioning to a FortiGate VM enables advanced security features—such as deep packet inspection, policy-based NAT, and comprehensive logging—helping meet compliance standards while maintaining secure and controlled internet access.

- **Granular Control and Expanded Public IP Requirements**
As application environments grow, organizations may require more than the 16 public IPs supported by Azure NAT Gateway, along with precise control over how those IPs are used. Migrating to a FortiGate VM allows for significantly more public IP addresses and provides granular control through policy-based NAT, enabling specific outbound traffic to use designated IPs. This ensures better traffic segregation, simplifies whitelisting with external partners, and supports complex multi-tenant or multi-environment architectures.

-  **Custom Routing Preference**
Some customers require deterministic routing via their own ISPs to optimize latency or avoid Microsoft’s backbone. Since Azure NAT Gateway doesn't support public IPs with an "Internet" routing preference, a FortiGate VM provides the flexibility to meet this need with full control over outbound routing paths.

- **IPv6 Outbound Connectivity**
Organizations adopting IPv6 for scalability or regulatory compliance require native IPv6 support for outbound traffic. Azure NAT Gateway currently supports only IPv4, limiting dual-stack deployments. By deploying a FortiGate (FGT) VM, customers can enable and manage outbound IPv6 connectivity, apply security policies, and maintain full visibility for both IPv4 and IPv6 traffic.

- **ICMP and IP Fragmentation Support**
Certain applications and diagnostic tools rely on ICMP (e.g., ping, traceroute) and support for fragmented IP packets. Azure NAT Gateway does not support ICMP or IP fragmentation, which can impact troubleshooting and specific workloads. FortiGate (FGT) VM fully supports ICMP and fragmented packets, making it a suitable alternative for environments requiring advanced network diagnostics or protocols that depend on IP fragmentation.

## FortiGate Key Features and NAT Gateway Limitations

Azure NAT Gateway offers simple outbound access with limited control. FortiGate enhances this with:

- Advanced security (IPS, antivirus, URL filtering)
- Full session visibility and logging
- Inbound & outbound NAT support
- Custom connection timeouts and granular policy control
- Compliance with enterprise security standards.


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

- Select the appropriate FortiGate deployment scenario based on your requirements from this [link](https://github.com/fortinet/azure-templates/tree/main/FortiGate):

[Single-VM](https://github.com/40net-cloud/fortinet-azure-solutions/tree/main/FortiGate/A-Single-VM)

[Active-Passive-SDN](https://github.com/40net-cloud/fortinet-azure-solutions/tree/main/FortiGate/Active-Passive-SDN)

[Active-Passive-ELB-ILB](https://github.com/40net-cloud/fortinet-azure-solutions/tree/main/FortiGate/Active-Passive-ELB-ILB)

[Active-Active-ELB-ILB](https://github.com/40net-cloud/fortinet-azure-solutions/tree/main/FortiGate/Active-Active-ELB-ILB)

- Diassociate subnets atttached to Azure NAT Gateway.

- Associate your subnets to the routing table which points all traffic to FGT internal interface (Active-Passive-SDN - Single-VM) or to internal load balancer IP (Active-Passive-ELB-ILB or Active-Active-ELB-ILB Deployment).

- Configure outbound connectivity.

[Single-VM](https://github.com/40net-cloud/fortinet-azure-solutions/tree/main/FortiGate/A-Single-VM#outbound-connections)

[Active-Passive-ELB-ILB](https://github.com/40net-cloud/fortinet-azure-solutions/tree/main/FortiGate/Active-Passive-ELB-ILB#outbound-connections)


- Delete azure NAT Gateway.

## Resources

- [Nat Gateway](https://learn.microsoft.com/en-us/azure/nat-gateway/nat-gateway-resource)
- [Nat Gateway Limitations](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-nat-gateway-limits)
- [Public IP addresses per network interface FGT VM](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-resource-manager-virtual-networking-limits)
- [FGT Support 256 Secondary IP Addresses](https://community.fortinet.com/t5/FortiGate/Technical-Tip-FortiGate-can-create-max-32-secondary-IP-address/ta-p/230121).

## Support

Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/40net-cloud/terraform-azure-fortigate/issues) tab of this GitHub project.

## License

[License](/../../blob/main/LICENSE) © Fortinet Technologies. All rights reserved.
