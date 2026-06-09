-------------------------------------------------
FortiManager Deployment Summary
-------------------------------------------------

Region: ${region}
Username: admin

FortiManager 1
Instance id: ${fmg1_instance_id}
Public IP: ${fmg1_public_ip_address}
Private IP: ${fmg1_private_ip_address}

FortiManager 2
Instance id: ${fmg2_instance_id}
Public IP: ${fmg2_public_ip_address}
Private IP: ${fmg2_private_ip_address}

To access FortiManager:
GUI: https://${fmg1_public_ip_address}
GUI: https://${fmg2_public_ip_address}

SSH: ssh -i <key-pair>.pem admin@${fmg1_public_ip_address}
SSH: ssh -i <key-pair>.pem admin@${fmg2_public_ip_address}

IMPORTANT:
- Change the admin password after initial login
- Configure your firewall rules appropriately
- Keep your license and software up to date
