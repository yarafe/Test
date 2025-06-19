# Required variables for deployment of the FortiGate in Azure Virtual WAN

prefix = "ya-terraform-a-a"
location = "eastus"
username = ""
password = ""
subscription_id = ""

#fgt_image_sku ="" 
#fgt_version =""
#fgt_count = "2"


fgt_ssh_public_key_file = ""
fgt_byol_fortiflex_license_tokens = {
  "node-0" = ""
  "node-1" = ""
}
fgt_byol_license_files = {

}

