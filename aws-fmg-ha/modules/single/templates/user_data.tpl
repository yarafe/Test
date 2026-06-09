Content-Type: multipart/mixed; boundary="===============0086047718136476635=="
MIME-Version: 1.0

--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="config"

config system global
    set hostname "${fmg_vm_name}"
    set management-port "${fmg_admin_port}"
end
%{ if fmg_ssh_public_key != "" }
config system admin user
    edit "${fmg_username}"
        set ssh-public-key1 "${trimspace(file(fmg_ssh_public_key))}"
    next
end
%{ endif }
%{ if fmg_license_fortiflex != "" }
exec vm-license ${fmg_license_fortiflex}
%{ endif }

%{ if fmg_license_file != "" }
--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="${fmg_license_file}"

${file(fmg_license_file)}

%{ endif }
--===============0086047718136476635==--
