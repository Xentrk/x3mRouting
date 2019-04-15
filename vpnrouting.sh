#!/bin/sh

PARAM=$*
if [ "$PARAM" == "" ]
then
	# Add paramaters equivalent to those passed for up command
	PARAM="$dev $tun_mtu $link_mtu $ifconfig_local $ifconfig_remote"
fi

my_logger(){
	if [ "$VPN_LOGGING" -gt "3" ]
	then
		/usr/bin/logger -t "openvpn-routing" "$1"
	fi
}


create_client_list(){
	OLDIFS=$IFS
	IFS="<"

	for ENTRY in $VPN_IP_LIST
	do
   	if [ "$ENTRY" = "" ]
		then
			continue
		fi
		TARGET_ROUTE=$(echo $ENTRY | cut -d ">" -f 4)
################################ Bypass DummyVPN Entry
   	DESC=$(echo $ENTRY | cut -d ">" -f 1)
    if [ "$(echo "$DESC" | cut -c1-8)" = "DummyVPN" ]; then
        continue
    fi		
################################ End of hack   
		if [ "$TARGET_ROUTE" = "WAN" ]
		then
			TARGET_LOOKUP="main"
			WAN_PRIO=$((WAN_PRIO+1))
			RULE_PRIO=$WAN_PRIO
			TARGET_NAME="WAN"
		else
			TARGET_LOOKUP=$VPN_TBL
			VPN_PRIO=$((VPN_PRIO+1))
			RULE_PRIO=$VPN_PRIO
			TARGET_NAME="VPN client "$VPN_UNIT
		fi
		VPN_IP=$(echo $ENTRY | cut -d ">" -f 2)
		if [ "$VPN_IP" != "0.0.0.0" ]
		then
			SRCC="from"
			SRCA="$VPN_IP"
		else
			SRCC=""
			SRCA=""
		fi
		DST_IP=$(echo $ENTRY | cut -d ">" -f 3)	
		if [ "$DST_IP" != "0.0.0.0" ]
		then
			DSTC="to"
			DSTA="$DST_IP"
		else
			DSTC=""
			DSTA=""
		fi
		if [ "$SRCC" != "" -o "$DSTC" != "" ]
		then
#################################################################
## prevent creating ip rule for ipset lists here
## Example Value of ENTRY is: CBS>192.168.4.1>0.0.0.0>DD
#################################################################
        if [ "$TARGET_ROUTE" = "VPN" ] ||  "$TARGET_ROUTE" = "WAN" ]; then
####################################################################
			      ip rule add $SRCC $SRCA $DSTC $DSTA table $TARGET_LOOKUP priority $RULE_PRIO
            logger -st "($(basename $0))" $$ "ip rule add $SRCC $SRCA $DSTC $DSTA table $TARGET_LOOKUP priority $RULE_PRIO"
			      my_logger "Adding route for $VPN_IP to $DST_IP through $TARGET_NAME"

        fi 
############################################        
		fi
   

################################## Martineau Hack process IPSET Lists
if [ ! -z "$(echo $TARGET_ROUTE | grep -oE "SRC|DST|^D|^S")" ]; then

 IPSET_NAME=$DESC

 # Allow for 2-dimension and 3-dimension IPSETs.....
 case "$TARGET_ROUTE" in         # TBA review static 'case' with a regexp? ;-)
    SRC|DST) DIM=$(echo $TARGET_ROUTE | tr 'A-Z' 'a-z');;
    *) case $TARGET_ROUTE in
           DD)  DIM="dst,dst" ;;
           SS)  DIM="src,src" ;;
           DS)  DIM="dst,src" ;;
           SD)  DIM="src,dst" ;;
           DDS) DIM="dst,dst,src" ;;
           SSS) DIM="src,src,src" ;;
           SSD) DIM="src,src,dst" ;;
           DDD) DIM="dst,dst,dst" ;;
       esac
 esac

############################################### End of Hack
######################### Xentrk Hack to validate SRC IP  Address for IPSET List
 # If the Source IP is a real LAN IP then include it in the IPSET fwmark rule

LAN_IP=$(nvram get lan_ipaddr)
DEST_IP="$VPN_IP"
SRC=""

lanip_oct1=$(echo $LAN_IP | cut -d "." -f1)
lanip_oct2=$(echo $LAN_IP | cut -d "." -f2)
lanip_oct3=$(echo $LAN_IP | cut -d "." -f3)
lanip_oct4=$(echo $LAN_IP | cut -d "." -f4)

# Set SRC parm for iptables command if SRC ip address is a valid LAN IP

if [ ! -z $(echo $DEST_IP | grep -Eo '(([0-9]{1,3})\.){3}([0-9]{1,3}){1}' | grep -vE '25[6-9]|2[6-9][0-9]|[3-9][0-9][0-9]') ]; then
    srcip_oct1=$(echo $DEST_IP | cut -d "." -f1)
    srcip_oct2=$(echo $DEST_IP | cut -d "." -f2)
    srcip_oct3=$(echo $DEST_IP | cut -d "." -f3)
    srcip_oct4=$(echo $DEST_IP | cut -d "." -f4)

    if [ "$srcip_oct1" -eq "$lanip_oct1" ]; then
        if [ "$srcip_oct2" -eq "$lanip_oct2" ]; then
            if [ "$srcip_oct3" -eq "$lanip_oct3" ]; then
                if [ "$srcip_oct4" -gt 1 ] && [ "$srcip_oct4" -le 254 ]; then
                    SRC="-s $DEST_IP"
                fi
            fi
        fi
    fi

fi

 ## Xentrk Hack to Validate that $IPSET_NAME does physically exist etc.
    if [ "$(ipset list -n $IPSET_NAME 2>/dev/null)" != "$IPSET_NAME" ]; then
        logger -st "($(basename $0))" $$ "IPSET list name $IPSET_NAME does not exist. $IPSET_NAME routing iptable rule not created."
    else
        iptables -t mangle -D PREROUTING $SRC -i br0 -m set --match-set $IPSET_NAME $DIM -j MARK --set-mark $FWMARK 2> /dev/null
        iptables -t mangle -A PREROUTING $SRC -i br0 -m set --match-set $IPSET_NAME $DIM -j MARK --set-mark $FWMARK 2> /dev/null
    fi
 
fi
######################################################################## End of IPSET Mods

	done
	IFS=$OLDIFS
########################################################################################## Modified Martineau Hack 1 of 5
# Xentrk: modified prior and updated to use fwmark/bitmask format
logger -st "($(basename $0))" $$ "x3mRouting Checking Custom fwmark/bitmask"

 if [ "$(ip rule | grep -c "from all fwmark 0x8000/0x8000 lookup main")" -eq "0" ]; then
  ip rule add from 0/0 fwmark 0x8000/0x8000 table 254 prio 9990
  logger -st "($(basename $0))" $$  "x3mRouting Adding WAN0 RPDB fwmark rule 0x8000/0x8000 prio 9990"
 fi

############################# Create ip rule fwmark/bitmask for OpenVPN Client Table 
  case "${VPN_UNIT}" in
            1)  FWMARK=0x1000/0x1000; PRIO=9995 ;;
            2)  FWMARK=0x2000/0x2000; PRIO=9994 ;;
            3)  FWMARK=0x4000/0x4000; PRIO=9993 ;;
            4)  FWMARK=0x7000/0x7000; PRIO=9992 ;;
            5)  FWMARK=0x3000/0x3000; PRIO=9991 ;;
        esac 
 
 if [ "$(ip rule | grep -c "from all fwmark $FWMARK")" -eq "0" ]; then
  ip rule add from 0/0 fwmark "$FWMARK" table "11${VPN_UNIT}" prio "$PRIO"
  logger -st "($(basename $0))" $$  "x3mRouting Adding OVPNC${VPN_UNIT} RPDB fwmark rule $FWMARK prio $PRIO"
 fi
################################################################################################################
}

purge_client_list(){
	IP_LIST=$(ip rule show | cut -d ":" -f 1)
	for PRIO in $IP_LIST
	do
		if [ $PRIO -ge $START_PRIO -a $PRIO -le $END_PRIO ]
		then
########################################################################################## Martineau Hack 2 of 5
      if [ "$PRIO" -eq "9990" ]; then
        logger -t "($(basename "$0"))" $$ "Skipping deletion of rule $PRIO unoffically reserved for WAN fwmark 0x8000/0x8000"
      else
#################################################################################################################
			  ip rule del prio $PRIO
			  logger -t "($(basename "$0"))" $$ "Removing rule $PRIO from routing policy"
		  fi
     fi  
	done

####################### Xentrk Hack remove iptable rules for IPSET lists 
  case "$VPN_UNIT" in
            1)  FWMARK=0x1000 ;; # table 111
            2)  FWMARK=0x2000 ;; # table 112
            3)  FWMARK=0x4000 ;; # table 113
            4)  FWMARK=0x7000 ;; # table 114
            5)  FWMARK=0x3000 ;; # table 115
        esac

   iptables -nvL PREROUTING -t mangle --line | grep "match-set" | grep "$FWMARK" | awk '{print $1}' | sort -r | while read -r CHAIN_NUM 
      do
          IPSET_NAME=$(iptables -nvL PREROUTING -t mangle --line | grep "match-set" | awk -v numb="$CHAIN_NUM" '$1 == numb {print $12}')
          logger -t "($(basename "$0"))" $$ "Deleting PREROUTING CHAIN $CHAIN_NUM for IPSET List $IPSET_NAME"
          iptables -t mangle -D PREROUTING "$CHAIN_NUM"
      done 

###################### Xentrk Hack remove fwmark/bitmask for OpenVPN Client 
  ip rule del fwmark "$FWMARK/$FWMARK" 2> /dev/null
############################################# Xentrk Hack 
}

run_custom_script(){
	if [ -f /jffs/scripts/openvpn-event ]
	then
		/usr/bin/logger -t "custom_script" "Running /jffs/scripts/openvpn-event (args: $PARAM)"
		/bin/sh /jffs/scripts/openvpn-event $PARAM
	fi
}

init_table(){
	my_logger "Creating VPN routing table (mode $VPN_REDIR)"
	ip route flush table $VPN_TBL

# Fill it with copy of existing main table
	if [ "$VPN_REDIR" == "3" ]
	then
		LANIFNAME=$(nvram get lan_ifname)
		ip route show table main dev $LANIFNAME | while read ROUTE
		do
			ip route add table $VPN_TBL $ROUTE dev $LANIFNAME
		done
		ip route show table main dev $dev | while read ROUTE
		do
			ip route add table $VPN_TBL $ROUTE dev $dev
		done
	elif [ "$VPN_REDIR" == "2" ]
	then
		ip route show table main | while read ROUTE
		do
			ip route add table $VPN_TBL $ROUTE
		done
	fi
}

# Begin
if [ "$dev" == "tun11" ]
then
	VPN_IP_LIST=$(nvram get vpn_client1_clientlist)$(nvram get vpn_client1_clientlist1)$(nvram get vpn_client1_clientlist2)$(nvram get vpn_client1_clientlist3)$(nvram get vpn_client1_clientlist4)$(nvram get vpn_client1_clientlist5)
	VPN_REDIR=$(nvram get vpn_client1_rgw)
	VPN_FORCE=$(nvram get vpn_client1_enforce)
	VPN_UNIT=1
	VPN_LOGGING=$(nvram get vpn_client1_verb)
 #### Xentrk: update vpnrouting.sh to use /jffs/configs/ovpnc1.nvram 
  if [ -s "/jffs/configs/ovpnc${VPN_UNIT}.nvram" ]; then
   VPN_IP_LIST=${VPN_IP_LIST}$(cat "/jffs/configs/ovpnc${VPN_UNIT}.nvram")
   logger -st "($(basename $0))" $$  "x3mRouting /jffs/configs/ovpnc${VPN_UNIT}.nvram to VPN_IP_LIST"
  fi
 #######################################################################
elif [ "$dev" == "tun12" ]
then
	VPN_IP_LIST=$(nvram get vpn_client2_clientlist)$(nvram get vpn_client2_clientlist1)$(nvram get vpn_client2_clientlist2)$(nvram get vpn_client2_clientlist3)$(nvram get vpn_client2_clientlist4)$(nvram get vpn_client2_clientlist5)
	VPN_REDIR=$(nvram get vpn_client2_rgw)
	VPN_FORCE=$(nvram get vpn_client2_enforce)
	VPN_UNIT=2
	VPN_LOGGING=$(nvram get vpn_client2_verb)
 #### Xentrk: update vpnrouting.sh to use /jffs/configs/ovpnc2.nvram 
 # route OVPNC3 clients
  if [ -s "/jffs/configs/ovpnc${VPN_UNIT}.nvram" ]; then
    VPN_IP_LIST=${VPN_IP_LIST}$(cat "/jffs/configs/ovpnc${VPN_UNIT}.nvram")
    logger -st "($(basename $0))" $$  "x3mRouting adding /jffs/configs/ovpnc${VPN_UNIT}.nvram to VPN_IP_LIST"
  fi
 ######################################################################## 
elif [ "$dev" == "tun13" ]
then
	VPN_IP_LIST=$(nvram get vpn_client3_clientlist)$(nvram get vpn_client3_clientlist1)$(nvram get vpn_client3_clientlist2)$(nvram get vpn_client3_clientlist3)$(nvram get vpn_client3_clientlist4)$(nvram get vpn_client3_clientlist5)
	VPN_REDIR=$(nvram get vpn_client3_rgw)
	VPN_FORCE=$(nvram get vpn_client3_enforce)
	VPN_UNIT=3
	VPN_LOGGING=$(nvram get vpn_client3_verb)
 #### Xentrk: update vpnrouting.sh to use /jffs/configs/ovpnc3.nvram
  if [ -s "/jffs/configs/ovpnc${VPN_UNIT}.nvram" ]; then
   VPN_IP_LIST=${VPN_IP_LIST}$(cat "/jffs/configs/ovpnc${VPN_UNIT}.nvram")
   logger -st "($(basename $0))" $$  "x3mRouting adding /jffs/configs/ovpnc${VPN_UNIT}.nvram to VPN_IP_LIST"
  fi
 ########################################################################
elif [ "$dev" == "tun14" ]
then
	VPN_IP_LIST=$(nvram get vpn_client4_clientlist)$(nvram get vpn_client4_clientlist1)$(nvram get vpn_client4_clientlist2)$(nvram get vpn_client4_clientlist3)$(nvram get vpn_client4_clientlist4)$(nvram get vpn_client4_clientlist5)
	VPN_REDIR=$(nvram get vpn_client4_rgw)
	VPN_FORCE=$(nvram get vpn_client4_enforce)
	VPN_UNIT=4
	VPN_LOGGING=$(nvram get vpn_client4_verb)
 #### Xentrk: update vpnrouting.sh to use /jffs/configs/ovpnc4.nvram 
  if [ -s "/jffs/configs/ovpnc${VPN_UNIT}.nvram" ]; then
   VPN_IP_LIST=${VPN_IP_LIST}$(cat "/jffs/configs/ovpnc${VPN_UNIT}.nvram")
   logger -st "($(basename $0))" $$  "x3mRouting adding /jffs/configs/ovpnc${VPN_UNIT}.nvram to VPN_IP_LIST"
  fi
 ######################################################################## 
elif [ "$dev" == "tun15" ]
then
	VPN_IP_LIST=$(nvram get vpn_client5_clientlist)$(nvram get vpn_client5_clientlist1)$(nvram get vpn_client5_clientlist2)$(nvram get vpn_client5_clientlist3)$(nvram get vpn_client5_clientlist4)$(nvram get vpn_client5_clientlist5)
	VPN_REDIR=$(nvram get vpn_client5_rgw)
	VPN_FORCE=$(nvram get vpn_client5_enforce)
	VPN_UNIT=5
	VPN_LOGGING=$(nvram get vpn_client5_verb)
 #### Xentrk: update vpnrouting.sh to use /jffs/configs/ovpnc5.nvram 
  if [ -s "/jffs/configs/ovpnc${VPN_UNIT}.nvram" ]; then
   VPN_IP_LIST=${VPN_IP_LIST}$(cat "/jffs/configs/ovpnc${VPN_UNIT}.nvram")
   logger -st "($(basename $0))" $$  "x3mRouting adding /jffs/configs/ovpnc${VPN_UNIT}.nvram to VPN_IP_LIST"
  fi
 ########################################################################
else
	run_custom_script
	exit 0
fi

VPN_TBL="ovpnc"$VPN_UNIT
START_PRIO=$((10000+(200*($VPN_UNIT-1))))
END_PRIO=$(($START_PRIO+199))
WAN_PRIO=$START_PRIO
VPN_PRIO=$(($START_PRIO+100))

export VPN_GW VPN_IP VPN_TBL VPN_FORCE


# webui reports that vpn_force changed while vpn client was down
if [ $script_type = "rmupdate" ]
then
logger "..script_type==> rmupdate"
	my_logger "Refreshing policy rules for client $VPN_UNIT"
	purge_client_list

	if [ $VPN_FORCE == "1" -a $VPN_REDIR -ge "2" ]
	then
		init_table
		my_logger "Tunnel down - VPN client access blocked"
 		ip route del default table $VPN_TBL
		ip route add prohibit default table $VPN_TBL
		create_client_list
	else
		my_logger "Allow WAN access to all VPN clients"
		ip route flush table $VPN_TBL
	fi
	ip route flush cache
	exit 0
fi

if [ $script_type == "route-up" -a $VPN_REDIR -lt "2" ]
then
	my_logger "Skipping, client $VPN_UNIT not in routing policy mode"
	run_custom_script
	exit 0
fi

/usr/bin/logger -t "openvpn-routing" "Configuring policy rules for client $VPN_UNIT"

if [ $script_type == "route-pre-down" ]
then
	purge_client_list
 
 	if [ $VPN_FORCE == "1" -a $VPN_REDIR -ge "2" ]
	then
		/usr/bin/logger -t "openvpn-routing" "Tunnel down - VPN client access blocked"
		ip route change prohibit default table $VPN_TBL
		create_client_list
	else
		ip route flush table $VPN_TBL
 		my_logger "Flushing client routing table"
	fi
fi	# End route down



if [ $script_type == "route-up" ]
then
	init_table

# Delete existing VPN routes that were pushed by server on table main
	NET_LIST=$(ip route show|awk '$2=="via" && $3==ENVIRON["route_vpn_gateway"] && $4=="dev" && $5==ENVIRON["dev"] {print $1}')
	for NET in $NET_LIST
	do
		ip route del $NET dev $dev
		my_logger "Removing route for $NET to $dev from main routing table"
	done

# Update policy rules
        purge_client_list
        create_client_list

# Setup table default route
	if [ "$VPN_IP_LIST" != "" ]
	then
		if [ "$VPN_FORCE" == "1" ]
		then
			/usr/bin/logger -t "openvpn-routing" "Tunnel re-established, restoring WAN access to clients"
		fi
		if [ "$route_net_gateway" != "" ]
		then
			ip route del default table $VPN_TBL
			ip route add default via $route_vpn_gateway table $VPN_TBL
		else
			/usr/bin/logger -t "openvpn-routing" "WARNING: no VPN gateway provided, routing might not work properly!"
		fi
	fi

	if [ "$route_net_gateway" != "" ]
	then
		ip route del default
		ip route add default via $route_net_gateway
	fi
fi	# End route-up

ip route flush cache
my_logger "Completed routing policy configuration for client $VPN_UNIT"
run_custom_script

exit 0
