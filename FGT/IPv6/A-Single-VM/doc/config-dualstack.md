
#Azure Portal Configuration

<p align="center">
  <img width="800px" src="../images/udr.PNG" alt="UDR">
</p>

<p align="center">
  <img width="800px" src="../images/fgt-nic1-config.PNG" alt="fgt-nic1-config">
</p>

<p align="center">
  <img width="800px" src="../images/fgt-nic1-config.PNG" alt="fgt-nic2-config">
</p>

#Fortigate Configuration

## Static Routes and interfaces Configuration

<pre><code>
config system sdn-connector
  edit AzureSDN
    set type azure
  next
end
config router static
  edit 1
    set gateway <b>172.16.136.1</b>
    set device port1
  next
  edit 2
    set dst <b>172.16.136.0/22</b>
    set device port2
    set gateway <b>172.16.136.65</b>
  next
end
config router static6
    edit 1
        set gateway <b>fe80::1234:5678:9abc</b>
        set device "port1"
    next
    edit 2
        set dst <b>ace:cab:deca::/48</b>
        set gateway <b>fe80::1234:5678:9abc</b>
        set device "port2"
    next
end
config system interface
  edit port1
    set mode static
    set ip <b>172.16.136.5/26</b>
    set description external
    set allowaccess ping ssh https
	config ipv6
            set ip6-address <b>ace:cab:deca::4/64</b>
            set ip6-allowaccess ping https ssh
    end
  next
  edit port2
    set mode static
    set ip <b>172.16.136.69/24</b>
    set description internal
    set allowaccess ping ssh https
	config ipv6
            set ip6-address <b>ace:cab:deca:10::4/64</b>
            set ip6-allowaccess ping https ssh
        end
  next
end
</code></pre>


## inbound and Outbound Configuration

<pre><code>
config firewall policy
    edit 1
        set name "win6-in"
        set srcintf "port1"
        set dstintf "port2"
        set action accept
        set srcaddr6 "all"
        set dstaddr6 "win6"
        set schedule "always"
        set service "ALL"
        set logtraffic all
    next
    edit 2
        set name "win6-out"
        set srcintf "port2"
        set dstintf "port1"
        set action accept
        set srcaddr6 "all"
        set dstaddr6 "all"
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set nat enable
    next
    edit 3
        set name "win4-in"
        set srcintf "port1"
        set dstintf "port2"
        set action accept
        set srcaddr "all"
        set dstaddr "win"
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set logtraffic-start enable
    next
    edit 4
        set name "win4-out"
        set srcintf "port2"
        set dstintf "port1"
        set action accept
        set srcaddr "all"
        set dstaddr "all"
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set nat enable
    next
end
	
config firewall vip6
    edit "win6"
        set extip <b>ace:cab:deca::4</b>
        set mappedip <b>ace:cab:deca:20::4</b>
        set portforward enable
        set extport 6666
        set mappedport 3389
    next
end

config firewall vip
    edit "win"
        set extip <b>172.16.136.4</b>
        set mappedip <b>"172.16.137.4"</b>
        set extintf "any"
        set portforward enable
        set extport 3333
        set mappedport 3389
    next
end
</code></pre>