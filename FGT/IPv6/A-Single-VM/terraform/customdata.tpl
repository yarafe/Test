Content-Type: multipart/mixed; boundary="===============0086047718136476635=="
MIME-Version: 1.0

--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="config"

config system sdn-connector
	edit AzureSDN
		set type azure
	end
end
config sys global
    set hostname "${fgt_vm_name}"
    set gui-theme mariner
end
config vpn ssl settings
    set port 7443
end
config router static
    edit 1
        set gateway ${fgt_external_gw_ipv4}
        set device port1
    next
    edit 2
        set dst ${vnet_network_ipv4}
        set gateway ${fgt_internal_gw_ipv4}
        set device port2
    next
end
config router static6
    edit 1
        set gateway ${fgt_external_gw_ipv6}
        set device port1
    next
    edit 2
        set dst ${vnet_network_ipv6}
        set gateway ${fgt_internal_gw_ipv6}
        set device port2
    next
end
config system probe-response
    set http-probe-value OK
    set mode http-probe
end
config system interface
    edit port1
        set mode static
        set ip ${fgt_external_ipv4addr1}/${fgt_external_mask_ipv4}
        set description external
        set allowaccess probe-response ping https ssh ftm
		set secondary-IP enable
		config ipv6
            set ip6-address ${fgt_external_ipv6addr1}/${fgt_external_mask_ipv6}
            set ip6-allowaccess ping https ssh
            config ip6-extra-addr
                edit ${fgt_external_ipv6addr2}/${fgt_external_mask_ipv6}
                next
            end
        end
        config secondaryip
            edit 1
                set ip ${fgt_external_ipv4addr2}/${fgt_external_mask_ipv4}
                set allowaccess ping https ssh
            next
        end
    next
    edit port2
        set mode static
        set ip ${fgt_internal_ipv4addr}/${fgt_internal_mask_ipv4}
        set description internal
        set allowaccess probe-response ping https ssh ftm
		config ipv6
            set ip6-address ${fgt_internal_ipv6addr}/${fgt_internal_mask_ipv6}
            set ip6-allowaccess ping https ssh
        end
    next
end
%{ if fgt_ssh_public_key != "" }
config system admin
    edit "${fgt_username}"
        set ssh-public-key1 "${trimspace(file(fgt_ssh_public_key))}"
    next
end
%{ endif }
#
# Example config to provision an API user which can be used with the FortiGate Terraform Provider
# The API key is either an encrypted version. An unencrypted key can provided (exact 30 char long)
#config system api-user
#    edit restapi
#         set api-key Abcdefghijklmnopqrtsuvwxyz1234
#         set accprofile "super_admin"
#         config trusthost
#             edit 1
#                 set ipv4-trusthost w.x.y.z a.b.c.d
#             next
#        end
#    next
#end
#
%{ if fgt_license_fortiflex != "" }
--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="license"

LICENSE-TOKEN:${fgt_license_fortiflex}

%{ endif } %{ if fgt_license_file != "" }
--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="${fgt_license_file}"

${file(fgt_license_file)}

%{ endif }
--===============0086047718136476635==--
