subscription_id = "00000000-0000-0000-0000-000000000000"

# true = install, false = uninstall
install_agent = true

vms = [
  { name = "win-vm-01", resource_group_name = "rg-app-prod" },
  { name = "win-vm-02", resource_group_name = "rg-app-prod" },
  { name = "win-vm-03", resource_group_name = "rg-app-dev" },
]

# FortiCNAPP Windows agent releases page -> pick a release -> copy both URLs
install_script_url = "https://updates.lacework.net/windows/<Release-Version>/Install-LWDataCollector.ps1"
agent_msi_url      = "https://updates.lacework.net/windows/<Release-Version>/LWDataCollector.msi"

# US       https://api.lacework.net
# US-02    https://aprodus2.agent.lacework.net
# EU       https://api.fra.lacework.net
# ANZ      https://auprodn1.agent.lacework.net
agent_server_url = "https://api.fra.lacework.net"

# Keep the token out of this file:
#   export TF_VAR_agent_access_token="<token>"        (bash)
#   $env:TF_VAR_agent_access_token = "<token>"        (PowerShell)

exclude_from_defender = true

tags = {
  owner   = "security"
  purpose = "forticnapp-agent"
}
