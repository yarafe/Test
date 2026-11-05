subscription_id = "YOUR-AZURE-SUBSCRIPTION-ID"

# Must equal the number of entries in windows_vms.
vm_count = 3

windows_vms = {
  server1 = {
    resource_group_name = "rg-production"
    vm_name             = "windows-vm-01"
  }
  server2 = {
    resource_group_name = "rg-production"
    vm_name             = "windows-vm-02"
  }
  server3 = {
    resource_group_name = "rg-test"
    vm_name             = "windows-vm-03"
  }
}

# Windows agent token (not an API key). Keep this file private.
lacework_token = "YOUR-WINDOWS-AGENT-TOKEN"

# Replace with the agent server URL shown in your FortiCNAPP installation instructions.
lacework_endpoint = "agent.lacework.net"

# Official Windows agent v1.8.0 release URLs.
lacework_msi_url   = "https://updates.lacework.net/win-1.8.0.4050-2025-03-05-release-1.8.0-52072764931a60afdcd5c92507e6e973462b1f9a/LWDataCollector.msi"
lacework_ps_script = "https://updates.lacework.net/win-1.8.0.4050-2025-03-05-release-1.8.0-52072764931a60afdcd5c92507e6e973462b1f9a/Install-LWDataCollector.ps1"

# Optional Microsoft Defender exclusion.
lacework_defender = false

# Increase to 2, 3, etc. to rerun verification on retained VMs.
verification_revision = 1
