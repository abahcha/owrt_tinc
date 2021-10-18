# Tinc. Настраиваем VPN-канал между рутером (OpenWRT) и смартфоном (Android, root).

Представляю небольшой туториал (~~копипасту с авторскими правками~~) по созданию защищённого туннеля между домашним рутером и смартфоном с целью доступа к ресурсам домашей же сети. *Примечание: да, я знаю о существовании wireguard.*

C установленным у меня на момент написания хаутушки релизом OpenWRT *19.07* поставляется «stable» версия tinc *1.0*, поэтому никаких «invite URL» для упрощения подключения смартфона не предусмотрено. Все настройки на смарте — только ~~лапками~~ ручками. 

Исходные данные: используется только ipv4, домашняя сеть 192.168.1.0/24 (*router* LAN IP - *192.168.1.1*), сети подключаемых устройств — 192.168.n(>1).0/24 (конфигурируются при запуске «клиента» tinc на смартфоне). Внешний IP рутера — «белый» статический либо используем какой-либо сервис **ddns** для разрешения имени рутера в текущий внешний IP. 

## Настройки рутера:

0. Клонируем репо на локальный комп:

	`git clone https://github.com/abahcha/owrt_tinc.git && cd owrt_tinc`

0. Устанавливаем tinc на рутере и конфигурируем сеть:

	Редактируем файл **tinc_install_owrt.sh** в соответствии с настройками локальной сети (если локальная сеть 192.168.x.y/24, то можно ничего не менять). 

	Запускаем на рутере скрипт: 

	`ssh root@router '/bin/sh -s' < tinc_install_owrt.sh`

0. Настраиваем tinc:

	Редактируем файл **tinc_config_owrt.sh**. Обязательно подставить действительное значение в строке "*Address =* your-ddns-name (or static "white" IP)" и отредактировать значение "*Subnet =* " (должно совпадать с адресом подсети **lan** рутера *192.168.x.y/24*) в файле **hosts/router**! Инстанс сервера **tinc** фигурирует как "*tetris*", а запись хоста для рутера - "*router*", но можно и поменять.
	
	Запускаем скрипт на рутере: 

	`ssh root@router '/bin/sh -s' < tinc_config_owrt.sh`

**Hint:** если стоит задача объединить две домашние сети в единую, по vpn каналу со вторым рутером, то делаем так: настраиваем второй рутер по пунктам 2-3 (заменить *router* на *router2*, добавить обязательно в **tinc.conf** параметр *ConnectTo = router*), обмениваемся между рутерами недостающими файлами в **hosts/**: *router*<->*router2* и запускаем сервисы **tinc** на рутерах (`/etc/init.d/tinc start` либо из **luci**). Всё должно работать. 

## Настройка смартфона:

- Генерируем конфиг для смартфона на ПК. Так проще. Потребуется установленный **openssl**. Запись хоста для смартфона - *mob1*, подсеть - *192.168.2.0/24*.

	```
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
	```
	Или просто запускаем `tinc_config_mob.sh`.

- Обменяемся файлами хостов с рутером (**WinSCP** для **W**):

	```
	scp /tmp/mob1/hosts/mob1 root@router:/etc/tinc/tetris/hosts/

	scp root@router:/etc/tinc/tetris/hosts/router /tmp/mob1/hosts/ 
	```

- Устанавливаем из F-Droid приложение Tinc (порт Tinc VPN), нужен root. Потребуется adb. Подключаем смартфон к ПК по USB (необходимо разрешить отладку по USB):

	```
	(sudo) adb devices -l

	adb root #в настройках должен быть разрешён режим суперпользователя для adb

	adb shell mkdir -p /etc/tinc/mob1

	adb push /tmp/mob1/* /etc/tinc/mob1/

	adb shell chmod -R og-rwx /etc/tinc/mob1/*

	adb shell chmod u+x /etc/tinc/mob1/tinc-up /etc/tinc/mob1/tinc-down /etc/tinc/mob1/hosts/router-up /etc/tinc/mob1/hosts/router-down
	
	```

- Далее потребуется запустить приложение Tinc: 

	В настройках отметить «Execute as Super User» и задать «Configuration path» как /etc/tinc/mob1.
	Нажать кнопку приложения START. Должно работать.


**Послесловие**: в поставку релиза OpenWRT *21.02* уже завезли tinc *1.1*, надо будет посмотреть, сможет ли сконфигуроваться приложение TincApp (Paсien, рут не нужен) при помощи «invite URL». Это будет в ветке *21.02* текущего проекта.


## Использованные источники:
https://openwrt.org/docs/guide-user/services/vpn/tinc

https://www.tinc-vpn.org/documentation/