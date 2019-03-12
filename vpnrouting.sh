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

######################################################################
create_destination_routes () {
# Routing Rules for Destination IP Addresses in /jffs/configs/x3mRouting_destination_rules
  logger "At create_desintation_routes. Value of VPN_UNIT is: $VPN_UNIT"
    old_IFS="$IFS"
    IFS=" "

# Destination IP rules start with prio 9000 and increment by 1

WAN_COUNTER=9000
OVPNC1_COUNTER=9100
OVPNC2_COUNTER=9200
OVPNC3_COUNTER=9300
OVPNC4_COUNTER=9400
OVPNC5_COUNTER=9500

    while read -r IFACE DOMAIN
    do

#    	if [ $instance != 0 -a $(nvram get vpn_client$(echo $instance)_rgw) -ge 2  $(nvram get vpn_client$(echo $instance)_adns) == 3 ]

      if [ $(echo "$IFACE" | cut -c 1) != "#" ]; then
          if [ "$IFACE" -ge "0" ]; then
#             logger "parms are iface domain vpn_unit ===> $IFACE" "$DOMAIN" "$VPN_UNIT"
              if [ "$IFACE" -eq "$VPN_UNIT" ]; then
#                  logger "parms are iface and vpn_unit ===> $IFACE" "$VPN_UNIT"
                  lookup_domain "$IFACE" "$DOMAIN"
              fi
          fi
      fi
    done < /jffs/configs/x3mRouting_destination_rules
    IFS=$old_IFS
}

lookup_domain () {
    IFACE=$1
    DOMAIN=$2

# need to pipe output to a file to avoid losing track of the COUNTER variable
# using the method below will create a subshell. next time the function is called, it will not recall the last value of COUNTER
# e.g. drill $DOMAIN | grep -v SERVER | grep -E "([0-9]{1,3}[\\.]){3}[0-9]{1,3}" | while read IP

    drill -4 $DOMAIN | grep -v SERVER | grep -E "([0-9]{1,3}[\\.]){3}[0-9]{1,3}" | cut -f 5 > /tmp/lookup_domain.$$
    while read -r IP
    do
        case "$IFACE" in
            0) $(ip rule add to $IP table 254 prio $WAN_COUNTER); WAN_COUNTER=$((WAN_COUNTER + 1)) ;;
            1) $(ip rule add to $IP table 111 prio $OVPNC1_COUNTER); OVPNC1_COUNTER=$((OVPNC1_COUNTER + 1)) ;;
            2) $(ip rule add to $IP table 112 prio $OVPNC2_COUNTER); OVPNC2_COUNTER=$((OVPNC2_COUNTER + 1)) ;;
            3) $(ip rule add to $IP table 113 prio $OVPNC3_COUNTER); OVPNC3_COUNTER=$((OVPNC3_COUNTER + 1)) ;;
            4) $(ip rule add to $IP table 114 prio $OVPNC4_COUNTER); OVPNC4_COUNTER=$((OVPNC4_COUNTER + 1)) ;;
            5) $(ip rule add to $IP table 115 prio $OVPNC5_COUNTER); OVPNC5_COUNTER=$((OVPNC5_COUNTER + 1)) ;;
        esac
    done < /tmp/lookup_domain.$$
}
#####################################################################################################################

create_client_list(){
  logger "At create_client_list. Value of VPN_UNIT is: $VPN_UNIT"
############################################################################### Xentrk hack
#  comment out calling the function below for now!!!!!!!!!!
# create_destination_routes

	OLDIFS=$IFS
	IFS="<"

	for ENTRY in $VPN_IP_LIST
	do
   logger "Value of ENTRY is: $ENTRY"
		if [ "$ENTRY" = "" ]
		then
			continue
		fi
		TARGET_ROUTE=$(echo $ENTRY | cut -d ">" -f 4)
    logger "Value of TARGET_ROUTE is: $TARGET_ROUTE"
######################################################## Xentrk Hack
   	DESC=$(echo $ENTRY | cut -d ">" -f 1)
    logger "Value of DESC is: $DESC"
    if [ "$(echo "$DESC" | cut -c1-8)" = "DummyVPN" ]; then
        continue
    fi
###########################################################
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
   logger "Value of VPN_IP is: $VPN_IP"

		if [ "$VPN_IP" != "0.0.0.0" ]
		then
			SRCC="from"
			SRCA="$VPN_IP"
		else
			SRCC=""
			SRCA=""
		fi
		DST_IP=$(echo $ENTRY | cut -d ">" -f 3)
   logger "Value of DST_IP is: $DST_IP"
		if [ "$DST_IP" != "0.0.0.0" ]
		then
			DSTC="to"
			DSTA="$DST_IP"
		else
			DSTC=""
			DSTA=""
		fi
################### debug
    logger "Value of SRCC is $SRCC"
    logger "Value of DSTC is $DSTC"
############3
		if [ "$SRCC" != "" -o "$DSTC" != "" ]
		then
    logger "Do I get here?"
#################################################################
## prevent creating ip rule for ipset lists here
## Value of ENTRY is: CBS>192.168.4.1>0.0.0.0>DD
#################################################################
        if [ "$TARGET_ROUTE" = "VPN" ] ||  "$TARGET_ROUTE" = "WAN" ]; then
            logger "hit a IPSET list condition"
####################################################################
			      ip rule add $SRCC $SRCA $DSTC $DSTA table $TARGET_LOOKUP priority $RULE_PRIO
            logger "ip rule add $SRCC $SRCA $DSTC $DSTA table $TARGET_LOOKUP priority $RULE_PRIO"
			      my_logger "Adding route for $VPN_IP to $DST_IP through $TARGET_NAME"
        fi
		fi

   ########################################################################
if [ ! -z "$(echo $TARGET_ROUTE | grep -oE "SRC|DST|^D|^S")" ];then

 IPSET_NAME=$DESC

 # Allow for 2-dimension and 3-dimension IPSETs.....
 logger "The value of VAR is $TARGET_ROUTE"
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

 # If the Source IP is a real LAN IP then include it in the IPSET fwmark rule

# <snip>

 # Validate that $IPSET_NAME does physically exist etc.
    if [ "$(ipset list -n $IPSET_NAME 2>/dev/null)" != "$IPSET_NAME" ]; then
        logger "IPSET list name $IPSET_NAME does not exist. $IPSET_NAME routing not created."
    else
        iptables -t mangle -D PREROUTING -i br0 -m set --match-set $IPSET_NAME $DIM -j MARK --set-mark $FWMARK 2> /dev/null
        iptables -t mangle -A PREROUTING -i br0 -m set --match-set $IPSET_NAME $DIM -j MARK --set-mark $FWMARK 2> /dev/null
    fi

fi
#########################################################################################################################################

	done
	IFS=$OLDIFS
########################################################################################## Modified Martineau Hack 1 of 5
# Xentrk: modified prior and updated to use fwmark/bitmask format
logger -st "($(basename $0))" $$  "x3mRouting Checking Custom fwmark/bitmask"

 if [ "$(ip rule | grep -c "from all fwmark 0x8000/0x8000 lookup main")" -eq "0" ]; then
  ip rule add from 0/0 fwmark 0x8000/0x8000 table 254 prio 9990
  logger -st "($(basename $0))" $$  "x3mRouting Adding WAN0 RPDB fwmark rule 0x8000/0x8000 prio 9990"
 fi

 #10000,10100,10300,10500,10700 and 10900
# if [ $(ip rule | grep -c "from all fwmark 0x${VPN_UNIT}000") -eq 0 ]; then
#  ip rule add from 0/0 fwmark "0x${VPN_UNIT}000/0x${VPN_UNIT}000" table "11${VPN_UNIT}" prio "10${((VPN_UNIT*2-1))}00"
#  logger -st "($(basename $0))" $$  "x3mRouting Adding VPN${VPN_UNIT} RPDB fwmark rule 0x${VPN_UNIT}000/0x${VPN_UNIT}000 prio 10${((VPN_UNIT*2-1))}00"
# fi
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
logger "At purge_client_list function"
	IP_LIST=$(ip rule show | cut -d ":" -f 1)
	for PRIO in $IP_LIST
	do
 	    logger "prio value is ==> $PRIO"
 		  logger "start_prio value is ==> $START_PRIO"
    	logger "end_prio value is ==> $END_PRIO"
		if [ $PRIO -ge $START_PRIO -a $PRIO -le $END_PRIO ]
		then
       logger "passed check for PRIOR"
       logger "value of parms are: $PRIO $START_PRIO $END_PRIO"
########################################################################################## Martineau Hack 2 of 5
      if [ "$PRIO" -eq "9990" ]; then
        logger "Xentrk skipping deletion of rule $PRIO unoffically reserved for WAN fwmark 0x8000/0x8000"
#      elif [ "$PRIO" -le "9000" -a "$PRIO" -lt "9990" ]; then
#        logger "Xentrk skipping deletion of rule $PRIO to route website to WAN interface"
      else
#################################################################################################################
#==> WAN getting deleted here??
			ip rule del prio $PRIO
			logger "Removing rule $PRIO from routing policy"
		  fi
     fi
############### Xentrk Hack
	done

  case "$VPN_UNIT" in
            1)  FWMARK=0x1000 ;; # table 111
            2)  FWMARK=0x2000 ;; # table 112
            3)  FWMARK=0x4000 ;; # table 113
            4)  FWMARK=0x7000 ;; # table 114
            5)  FWMARK=0x3000 ;; # table 115
        esac

        IPSET_NAME=$DESC

     iptables -nvL PREROUTING -t mangle --line | grep "$FWMARK" | cut -f 1 -d " " |  sort -r | while read -r CHAIN_NUM
        do
                logger "Deleting PREROUTING CHAIN=> $CHAIN_NUM for IPSET List $IPSET_NAME"
                iptables -t mangle -D PREROUTING "$CHAIN_NUM"
        done

}

## Need to decide if want to keep this function

purge_x3mRouting_destination_IP_addresses () {
#    IP_LIST=$(ip rule | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | grep "ovpnc${VPN_UNIT}" | grep "from all to" | cut -d ":" -f 1)
#        for PRIO in $IP_LIST
#            do
#            	if [ $PRIO -ge "9000" -a $PRIO -le "9900" ]; then
#                  ip rule del prior $PRIO
#   	              logger "Removing rule $PRIO from routing policy"
#              fi
#            done

    IP_LIST=$(ip rule | grep "ovpnc${VPN_UNIT}" | grep "from all fwmark" | cut -d ":" -f 1)
        for PRIO in $IP_LIST
            do
#             if [ $PRIO 10000,10100,10300,10500,10700 and 10900
#            	for
#             if [ $PRIO -ge "9991" -a $PRIO -le "9995" ]; then
                  ip rule del prior $PRIO
   	              logger "Removing rule $PRIO from routing policy"
#              fi
            done
}
##################################################################################################


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
logger "..at Begin of custom /jffs/scripts/vpnrouting.sh"

if [ "$dev" == "tun11" ]
then
	VPN_IP_LIST=$(nvram get vpn_client1_clientlist)$(nvram get vpn_client1_clientlist1)$(nvram get vpn_client1_clientlist2)$(nvram get vpn_client1_clientlist3)$(nvram get vpn_client1_clientlist4)$(nvram get vpn_client1_clientlist5)
 	VPN_IP_LISTO=$(nvram get vpn_client1_clientlist)$(nvram get vpn_client1_clientlist1)$(nvram get vpn_client1_clientlist2)$(nvram get vpn_client1_clientlist3)$(nvram get vpn_client1_clientlist4)$(nvram get vpn_client1_clientlist5)
	VPN_REDIR=$(nvram get vpn_client1_rgw)
	VPN_FORCE=$(nvram get vpn_client1_enforce)
	VPN_UNIT=1
	VPN_LOGGING=$(nvram get vpn_client1_verb)
 ## Xentrk: update vpnrouting.sh to use /jffs/configs/ovpnc1.nvram
  if [ -s "/jffs/configs/ovpnc${VPN_UNIT}.nvram" ]; then
   VPN_IP_LIST=${VPN_IP_LIST}$(cat "/jffs/configs/ovpnc${VPN_UNIT}.nvram")
   logger -st "($(basename $0))" $$  "x3mRouting adding /jffs/configs/ovpnc${VPN_UNIT}.nvram to VPN_IP_LIST"
  fi
elif [ "$dev" == "tun12" ]
then
	VPN_IP_LIST=$(nvram get vpn_client2_clientlist)$(nvram get vpn_client2_clientlist1)$(nvram get vpn_client2_clientlist2)$(nvram get vpn_client2_clientlist3)$(nvram get vpn_client2_clientlist4)$(nvram get vpn_client2_clientlist5)
 	VPN_IP_LISTO=$(nvram get vpn_client2_clientlist)$(nvram get vpn_client2_clientlist1)$(nvram get vpn_client2_clientlist2)$(nvram get vpn_client2_clientlist3)$(nvram get vpn_client2_clientlist4)$(nvram get vpn_client2_clientlist5)
	VPN_REDIR=$(nvram get vpn_client2_rgw)
	VPN_FORCE=$(nvram get vpn_client2_enforce)
	VPN_UNIT=2
	VPN_LOGGING=$(nvram get vpn_client2_verb)
 ## Xentrk: update vpnrouting.sh to use /jffs/configs/ovpnc2.nvram
 # route OVPNC3 clients
  if [ -s "/jffs/configs/ovpnc${VPN_UNIT}.nvram" ]; then
    VPN_IP_LIST=${VPN_IP_LIST}$(cat "/jffs/configs/ovpnc${VPN_UNIT}.nvram")
    logger -st "($(basename $0))" $$  "x3mRouting adding /jffs/configs/ovpnc${VPN_UNIT}.nvram to VPN_IP_LIST"
  fi
elif [ "$dev" == "tun13" ]
then
	VPN_IP_LIST=$(nvram get vpn_client3_clientlist)$(nvram get vpn_client3_clientlist1)$(nvram get vpn_client3_clientlist2)$(nvram get vpn_client3_clientlist3)$(nvram get vpn_client3_clientlist4)$(nvram get vpn_client3_clientlist5)
 	VPN_IP_LISTO=$(nvram get vpn_client3_clientlist)$(nvram get vpn_client3_clientlist1)$(nvram get vpn_client3_clientlist2)$(nvram get vpn_client3_clientlist3)$(nvram get vpn_client3_clientlist4)$(nvram get vpn_client3_clientlist5)
	VPN_REDIR=$(nvram get vpn_client3_rgw)
	VPN_FORCE=$(nvram get vpn_client3_enforce)
	VPN_UNIT=3
	VPN_LOGGING=$(nvram get vpn_client3_verb)
 ## Xentrk: update vpnrouting.sh to use /jffs/configs/ovpnc3.nvram
  if [ -s "/jffs/configs/ovpnc${VPN_UNIT}.nvram" ]; then
   VPN_IP_LIST=${VPN_IP_LIST}$(cat "/jffs/configs/ovpnc${VPN_UNIT}.nvram")
   logger -st "($(basename $0))" $$  "x3mRouting adding /jffs/configs/ovpnc${VPN_UNIT}.nvram to VPN_IP_LIST"
  fi
elif [ "$dev" == "tun14" ]
then
	VPN_IP_LIST=$(nvram get vpn_client4_clientlist)$(nvram get vpn_client4_clientlist1)$(nvram get vpn_client4_clientlist2)$(nvram get vpn_client4_clientlist3)$(nvram get vpn_client4_clientlist4)$(nvram get vpn_client4_clientlist5)
 	VPN_IP_LISTO=$(nvram get vpn_client4_clientlist)$(nvram get vpn_client4_clientlist1)$(nvram get vpn_client4_clientlist2)$(nvram get vpn_client4_clientlist3)$(nvram get vpn_client4_clientlist4)$(nvram get vpn_client4_clientlist5)
	VPN_REDIR=$(nvram get vpn_client4_rgw)
	VPN_FORCE=$(nvram get vpn_client4_enforce)
	VPN_UNIT=4
	VPN_LOGGING=$(nvram get vpn_client4_verb)
 ## Xentrk: update vpnrouting.sh to use /jffs/configs/ovpnc4.nvram
  if [ -s "/jffs/configs/ovpnc${VPN_UNIT}.nvram" ]; then
   VPN_IP_LIST=${VPN_IP_LIST}$(cat "/jffs/configs/ovpnc${VPN_UNIT}.nvram")
   logger -st "($(basename $0))" $$  "x3mRouting adding /jffs/configs/ovpnc${VPN_UNIT}.nvram to VPN_IP_LIST"
  fi
elif [ "$dev" == "tun15" ]
then
	VPN_IP_LIST=$(nvram get vpn_client5_clientlist)$(nvram get vpn_client5_clientlist1)$(nvram get vpn_client5_clientlist2)$(nvram get vpn_client5_clientlist3)$(nvram get vpn_client5_clientlist4)$(nvram get vpn_client5_clientlist5)
 	VPN_IP_LISTO=$(nvram get vpn_client5_clientlist)$(nvram get vpn_client5_clientlist1)$(nvram get vpn_client5_clientlist2)$(nvram get vpn_client5_clientlist3)$(nvram get vpn_client5_clientlist4)$(nvram get vpn_client5_clientlist5)
	VPN_REDIR=$(nvram get vpn_client5_rgw)
	VPN_FORCE=$(nvram get vpn_client5_enforce)
	VPN_UNIT=5
	VPN_LOGGING=$(nvram get vpn_client5_verb)
 ## Xentrk: update vpnrouting.sh to use /jffs/configs/ovpnc5.nvram
  if [ -s "/jffs/configs/ovpnc${VPN_UNIT}.nvram" ]; then
   VPN_IP_LIST=${VPN_IP_LIST}$(cat "/jffs/configs/ovpnc${VPN_UNIT}.nvram")
   logger -st "($(basename $0))" $$  "x3mRouting adding /jffs/configs/ovpnc${VPN_UNIT}.nvram to VPN_IP_LIST"
  fi
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
  logger "Value of VPNFORCE is $VPNFORCE. Value of VPN_REDIR is $VPN_REDIR"
	if [ $VPN_FORCE == "1" -a $VPN_REDIR -ge "2" ]
	then
		init_table
		my_logger "Tunnel down - VPN client access blocked"
   #####3
   logger "I'm at location A"
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
#xentrk
logger "..script_type==> route-up"
	my_logger "Skipping, client $VPN_UNIT not in routing policy mode"
	run_custom_script
	exit 0
fi

/usr/bin/logger -t "openvpn-routing" "Configuring policy rules for client $VPN_UNIT"

if [ $script_type == "route-pre-down" ]
then
#xentrk
  logger "..script_type==> route-pre-down"
	purge_client_list
  logger "At route-pre-down logic==>value of VPN_FORCE is $VPN_FORCE. Value of VPN_REDIR is $VPN_REDIR"
  logger "Value of VPN_UNIT at route-pre-down is $VPN_UNIT"
	if [ $VPN_FORCE == "1" -a $VPN_REDIR -ge "2" ]
	then
		/usr/bin/logger -t "openvpn-routing" "Tunnel down - VPN client access blocked"
################################
   logger "I'm at location B"
		ip route change prohibit default table $VPN_TBL
		create_client_list
	else
		ip route flush table $VPN_TBL
   logger "At ip route flush table $VPN_TBL"
		my_logger "Flushing client routing table"
	fi
fi	# End route down



if [ $script_type == "route-up" ]
then
#xentrk
logger "..script_type==> route-up"

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
