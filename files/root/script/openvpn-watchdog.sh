#!/bin/sh

DATE=`date +%Y-%m-%d-%H:%M:%S`

#check and add rules of mangle     
echo $DATE: Start to check iptables rules
echo $DATE: Start to check iptables rules > /root/script/openvpn_watchdog.log
iptables -t mangle -C PREROUTING -m set ! --match-set chnroute dst -j MARK --set-mark 1
if [ $? = 0 ]; then
        echo "$DATE: The PREROUTING rules alread exist"
        echo "$DATE: The PREROUTING rules alread exist" >>/root/script/openvpn_watchdog.log
        iptables -t mangle -C OUTPUT -m set ! --match-set chnroute dst -j MARK --set-mark 1
        if [ $? = 0 ]; then
                echo "$DATE: The OUTPUT rules alread exist"
                echo "$DATE: The OUTPUT rules alread exist" >>/root/script/openvpn_watchdog.log
        else
                iptables -t mangle -I OUTPUT -m set ! --match-set chnroute dst -j MARK --set-mark 1
                echo "$DATE: Add OUTPUT  rules"
                echo "$DATE: Add OUTPUT  rules" >>/root/script/openvpn_watchdog.log
        fi
else
        iptables -t mangle -I PREROUTING -m set ! --match-set chnroute dst -j MARK --set-mark 1
        echo "$DATE: Add PREROUTING rules"
        echo "$DATE: Add PREROUTING rules" >>/root/script/openvpn_watchdog.log

        iptables -t mangle -C OUTPUT -m set ! --match-set chnroute dst -j MARK --set-mark 1
        if [ $? = 0 ]; then
                echo "$DATE: The OUTPUT rules alread exist"
                echo "$DATE: The OUTPUT rules alread exist" >>/root/script/openvpn_watchdog.log
        else
                iptables -t mangle -I OUTPUT -m set ! --match-set chnroute dst -j MARK --set-mark 1
                echo "$DATE: Add OUTPUT  rules"
                echo "$DATE: Add OUTPUT  rules" >>/root/script/openvpn_watchdog.log
        fi
fi

function exist_tun0(){
       ip addr show tun0 > /dev/null 2>&1
       return $?
}

if ! exist_tun0;then
    echo $DATE: tun0 not exist,restart openvpn >>/root/script/openvpn_watchdog.log
    /etc/init.d/openvpn restart
    exit 0
else             
    #check gateway of vpn
    tries=0
    gw=$(ip addr show tun0 | grep 'inet ' | cut -d' ' -f6 | cut -d'.' -f1-3).1
    echo  $DATE: Start to check gateway of vpn-tun0
    echo  $DATE: Start to check gateway of vpn-tun0 >>/root/script/openvpn_watchdog.log
    while [[ $tries -lt 5 ]]
    do
        if /bin/ping -c 1 $gw >/dev/null
        then
                echo $DATE: Gateway is OK
                echo $DATE: Exit
                echo $DATE: Gateway is OK >> /root/script/openvpn_watchdog.log
                exit 0
        fi
        tries=$((tries+1))
        sleep 10
        echo $DATE: tries: $tries
        echo $DATE: tries: $tries >> /root/script/openvpn_watchdog.log
    done

    echo $DATE: openvpn restart
    echo $DATE: openvpn restart >> /root/script/openvpn_watchdog.log
    /etc/init.d/openvpn restart

    #echo $DATE reboot >> /root/script/openvpn_watchdog.log
    #reboot
fi
