#!/bin/sh

#Создать неуправляемый интерфейс для tinc (я его обозвал «tetris»)
#add nonmanaged interface ("tetris")
uci add network tetris
uci set network.tetris=interface
uci set network.tetris.proto='none'
uci set network.tetris.ifname='tetris'
uci set network.tetris.delegate='0'
uci commit network

#Настроить маршрутизацию, зону («vpn») и правила прохождения траффика локальная сеть (lan) — сеть vpn
#add routing for net 192.168.0.0/16 via new interface
uci add network route
uci set network.@route[-1].interface='tetris'
uci set network.@route[-1].target='192.168.0.0'
uci set network.@route[-1].netmask='255.255.0.0'
uci commit network

#add new firewall zone ("vpn") and rules for traffic lan<=>vpn
uci add firewall zone
uci set firewall.@zone[-1].name='vpn'
uci set firewall.@zone[-1].network='tetris'
uci set firewall.@zone[-1].family='ipv4'
uci set firewall.@zone[-1].input='ACCEPT'
uci set firewall.@zone[-1].output='ACCEPT'
uci commit firewall

uci add firewall forwarding
uci set firewall.@forwarding[-1].dest='vpn'
uci set firewall.@forwarding[-1].src='lan'
uci add firewall forwarding
uci set firewall.@forwarding[-1].dest='lan'
uci set firewall.@forwarding[-1].src='vpn'
uci commit firewall

#Разрешить входящий интернет-траффик на порт 655
#add firewall rule for incoming traffic on port 655 (default tinc listening port)
uci add firewall rule
uci set firewall.@rule[-1].target='ACCEPT'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].proto='tcp udp'
uci set firewall.@rule[-1].dest_port='655'
uci set firewall.@rule[-1].name='Allow-Tinc-WAN'
uci set firewall.@rule[-1].family='ipv4'
uci commit firewall

#Установить пакет tinc
#install tinc package
opkg update
opkg install tinc
/etc/init.d/tinc enable
