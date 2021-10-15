#/bin/sh

mkdir -p /etc/tinc/tetris && cd /etc/tinc/tetris

cat <<EOF >tinc.conf
name = router
AddressFamily = ipv4
EOF

cat <<EOF >tinc-up
export NETADDR=\`uci get network.lan.ipaddr\`
ip address add \$NETADDR/16 dev \$INTERFACE
EOF

cat <<EOF >tinc-down
ip link set dev \$INTERFACE down
EOF

chmod u+x tinc-up tinc-down

mkdir hosts
tincd -n tetris -K #генерируем пару ключей tinc

cat <<EOF>>hosts/router
Address = your-ddns-name (or static "white" IP)
Subnet = 192.168.1.0/24
EOF

uci batch <<EOF 
set tinc.tetris=tinc-net
set tinc.tetris.enabled='1'
set tinc.tetris.logfile='/tmp/log/tinc.log'
set tinc.router=tinc-host
set tinc.router.enabled='1'
set tinc.router.net='tetris'
EOF
uci commit
