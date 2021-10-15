#/usr/bin/bash

mkdir -p /tmp/mob1/hosts && cd /tmp/mob1 

openssl genrsa -out rsa_key.priv 2048
openssl rsa -in rsa_key.priv -pubout -RSAPublicKey_out -out hosts/mob1

cat<<EOF>>hosts/mob1
Subnet = 192.168.2.0/24
EOF

cat<<EOF>tinc.conf
name = mob1
ConnectTo = router
AddressFamily = ipv4
EOF

cat<<EOF>tinc-up
ifconfig $INTERFACE 192.168.2.1 netmask 255.255.0.0
EOF

touch tinc-down

cat<<EOF>hosts/router-up
VPN_GATEWAY=192.168.1.254
ip rule add prio 100 from all lookup 100
ip route add table 100 $VPN_GATEWAY dev $INTERFACE 
ip route add table 100 192.168.0.0/16 via $VPN_GATEWAY dev $INTERFACE
EOF

cat<<EOF>hosts/router-down
VPN_GATEWAY=192.168.1.254
ip rule del from all lookup 100
ip route del table 100 $VPN_GATEWAY dev $INTERFACE 
ip route del table 100 192.168.0.0/16 via $VPN_GATEWAY dev $INTERFACE 
EOF
