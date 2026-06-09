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
    set adom-status enable
    set clone-name-option keep
    set create-revision enable
    set device-view-mode tree
    set disable-module fortiview-noc
    set import-ignore-addr-cmt enable
    set partial-install enable
    set partial-install-force enable
    set partial-install-rev enable
    set perform-improve-by-ha enable
    set policy-hit-count enable
    set policy-object-icon enable
    set search-all-adoms enable
end
config system admin setting
    set gui-theme spring
    set idle_timeout 480
    set sdwan-monitor-history enable
    set show-add-multiple enable
    set show-checkbox-in-table enable
    set show-device-import-export enable
    set show-hostname enable
    set show_automatic_script enable
    set show_schedule_script enable
    set show_tcl_script enable
end
config system ha
    set failover-mode vrrp
	set clusterid 10
    set hb-interval 5
    set hb-lost-threshold 10
        config peer
            edit 1
                set ip ${peer_ipaddr}
                set serial-number ${peer_serial_number}
            next
        end
    set priority ${ha_priority}
    set unicast enable
    set password ${ha_password}
    set vip ${ha_ipaddr}
    set vrrp-interface "port1"
end
config system certificate ca
    edit Amazon-RSA-2048-M01
        set ca "-----BEGIN CERTIFICATE-----
MIIEXjCCA0agAwIBAgITB3MSOAudZoijOx7Zv5zNpo4ODzANBgkqhkiG9w0BAQsF
ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6
b24gUm9vdCBDQSAxMB4XDTIyMDgyMzIyMjEyOFoXDTMwMDgyMzIyMjEyOFowPDEL
MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEcMBoGA1UEAxMTQW1hem9uIFJT
QSAyMDQ4IE0wMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOtxLKnL
H4gokjIwr4pXD3i3NyWVVYesZ1yX0yLI2qIUZ2t88Gfa4gMqs1YSXca1R/lnCKeT
epWSGA+0+fkQNpp/L4C2T7oTTsddUx7g3ZYzByDTlrwS5HRQQqEFE3O1T5tEJP4t
f+28IoXsNiEzl3UGzicYgtzj2cWCB41eJgEmJmcf2T8TzzK6a614ZPyq/w4CPAff
nAV4coz96nW3AyiE2uhuB4zQUIXvgVSycW7sbWLvj5TDXunEpNCRwC4kkZjK7rol
jtT2cbb7W2s4Bkg3R42G3PLqBvt2N32e/0JOTViCk8/iccJ4sXqrS1uUN4iB5Nmv
JK74csVl+0u0UecCAwEAAaOCAVowggFWMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYD
VR0PAQH/BAQDAgGGMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNV
HQ4EFgQUgbgOY4qJEhjl+js7UJWf5uWQE4UwHwYDVR0jBBgwFoAUhBjMhTTsvAyU
lC4IWZzHshBOCggwewYIKwYBBQUHAQEEbzBtMC8GCCsGAQUFBzABhiNodHRwOi8v
b2NzcC5yb290Y2ExLmFtYXpvbnRydXN0LmNvbTA6BggrBgEFBQcwAoYuaHR0cDov
L2NydC5yb290Y2ExLmFtYXpvbnRydXN0LmNvbS9yb290Y2ExLmNlcjA/BgNVHR8E
ODA2MDSgMqAwhi5odHRwOi8vY3JsLnJvb3RjYTEuYW1hem9udHJ1c3QuY29tL3Jv
b3RjYTEuY3JsMBMGA1UdIAQMMAowCAYGZ4EMAQIBMA0GCSqGSIb3DQEBCwUAA4IB
AQCtAN4CBSMuBjJitGuxlBbkEUDeK/pZwTXv4KqPK0G50fOHOQAd8j21p0cMBgbG
kfMHVwLU7b0XwZCav0h1ogdPMN1KakK1DT0VwA/+hFvGPJnMV1Kx2G4S1ZaSk0uU
5QfoiYIIano01J5k4T2HapKQmmOhS/iPtuo00wW+IMLeBuKMn3OLn005hcrOGTad
hcmeyfhQP7Z+iKHvyoQGi1C0ClymHETx/chhQGDyYSWqB/THwnN15AwLQo0E5V9E
SJlbe4mBlqeInUsNYugExNf+tOiybcrswBy8OFsd34XOW3rjSUtsuafd9AWySa3h
xRRrwszrzX/WWGm6wyB+f7C4
-----END CERTIFICATE-----"
    set comment "Created by Terraform"
next
end
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
