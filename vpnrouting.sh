#!/bin/sh
# shellcheck disable=SC2086
# -- Disabled quote for processing array variable PARAM on line 274
# shellcheck disable=SC2154
# -- SC2154: dev is referenced but not assigned. (stay true to firmware for these warnings!)
# shellcheck disable=SC2018
# shellcheck disable=SC2019
# shellcheck disable=SC2021
# -- SC2021: Don't use [] around classes in tr, it replaces literal square brackets.

PARAM=$*
if [ "$PARAM" = "" ]; then
  # Add paramaters equivalent to those passed for up command
  PARAM="$dev $tun_mtu $link_mtu $ifconfig_local $ifconfig_remote"
fi

my_logger() {
  if [ "$VPN_LOGGING" -gt "3" ]; then
    /usr/bin/logger -t "openvpn-routing" "$1"
  fi
}

Chk_IPSET_List_Ready() {

  # ARGS [wait attempts] [specific_entware_utility]
  IPSET_NAME=$1
  READY=1 # Assume IPSET list is NOT available
  MAX_TRIES=60

  # Wait up to (default) 30 seconds to see if IPSET is available.....
  TRIES=0

  while [ "$TRIES" -lt "$MAX_TRIES" ]; do
    if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" = "$IPSET_NAME" ]; then
      READY=0 # Specific IPSET name found
      break
    else
      sleep 1
      logger -st "($(basename "$0"))" $$ "IPSET list $IPSET_NAME does not exist- wait time" $((MAX_TRIES - TRIES - 1))" secs left"
      TRIES=$((TRIES + 1))
    fi
  done

  return $READY
}

create_client_list() {
  OLDIFS=$IFS
  IFS="<"

  for ENTRY in $VPN_IP_LIST; do
    if [ "$ENTRY" = "" ]; then
      continue
    fi
    TARGET_ROUTE=$(echo "$ENTRY" | cut -d ">" -f 4)
    ################################ Bypass DummyVPN Entry
    DESC=$(echo "$ENTRY" | cut -d ">" -f 1)
    if [ "$(echo "$DESC" | cut -c1-8)" = "DummyVPN" ]; then
      continue
    fi
    ################################ End of hack
    if [ "$TARGET_ROUTE" = "WAN" ]; then
      TARGET_LOOKUP="main"
      WAN_PRIO=$((WAN_PRIO + 1))
      RULE_PRIO=$WAN_PRIO
      TARGET_NAME="WAN"
    else
      TARGET_LOOKUP=$VPN_TBL
      VPN_PRIO=$((VPN_PRIO + 1))
      RULE_PRIO=$VPN_PRIO
      TARGET_NAME="VPN client "$VPN_UNIT
    fi
    VPN_IP=$(echo "$ENTRY" | cut -d ">" -f 2)
    if [ "$VPN_IP" != "0.0.0.0" ] && [ "$VPN_IP" != "" ]; then
      SRCC="from"
      SRCA="$VPN_IP"
    else
      SRCC=""
      SRCA=""
    fi
    DST_IP=$(echo "$ENTRY" | cut -d ">" -f 3)
    if [ "$DST_IP" != "0.0.0.0" ] && [ "$DST_IP" != "" ]; then
      DSTC="to"
      DSTA="$DST_IP"
    else
      DSTC=""
      DSTA=""
    fi
    if [ "$SRCC" != "" ] || [ "$DSTC" != "" ]; then
      #################################################################
      ## prevent creating ip rule for ipset lists here
      ## Example Value of ENTRY is: CBS>192.168.4.1>0.0.0.0>DD
      #################################################################
      if [ "$TARGET_ROUTE" = "VPN" ] || [ "$TARGET_ROUTE" = "WAN" ]; then
        ####################################################################
        ip rule add $SRCC $SRCA $DSTC $DSTA table "$TARGET_LOOKUP" priority $RULE_PRIO
        logger -st "($(basename "$0"))" $$ "ip rule add $SRCC $SRCA $DSTC $DSTA table $TARGET_LOOKUP priority $RULE_PRIO"
        my_logger "Adding route for $VPN_IP to $DST_IP through $TARGET_NAME"

      fi
      ############################################
    fi

    ################################## Martineau Hack process IPSET Lists
    if echo "$TARGET_ROUTE" | grep -oE "SRC|DST|^D|^S"; then
      my_logger "THE VALUE OF TARGET ROUTE: $TARGET_ROUTE"
      # Allow for 2-dimension and 3-dimension IPSETs.....
      case "$TARGET_ROUTE" in # TBA review static 'case' with a regexp? ;-)
      SRC | DST) DIM=$(echo "$TARGET_ROUTE" | tr '[A-Z]' '[a-z]') ;;
      *) case "$TARGET_ROUTE" in
        DD) DIM="dst,dst" ;;
        SS) DIM="src,src" ;;
        DS) DIM="dst,src" ;;
        SD) DIM="src,dst" ;;
          #DDS) DIM="dst,dst,src" ;; Xentrk only 2 dim allowed to support IFACE
          #SSS) DIM="src,src,src" ;;
          #SSD) DIM="src,src,dst" ;;
          #DDD) DIM="dst,dst,dst" ;;
        esac ;;
      esac

      ############################################### End of Hack
      ######################### Xentrk Hack to validate SRC IP  Address for IPSET List
      # If the Source IP is a real LAN IP then include it in the IPSET fwmark rule

      LAN_IP=$(nvram get lan_ipaddr)
      DEST_IP="$VPN_IP"
      SRC="-s 0.0.0.0/0"

      if [ "$VPN_IP" != "0.0.0.0" ] && [ "$VPN_IP" != "" ]; then
        lanip_oct1=$(echo "$LAN_IP" | cut -d "." -f1)
        lanip_oct2=$(echo "$LAN_IP" | cut -d "." -f2)
        lanip_oct3=$(echo "$LAN_IP" | cut -d "." -f3)

        # Set SRC parm for iptables command if SRC ip address is a valid LAN IP

        if echo "$DEST_IP" | grep -Eo '(([0-9]{1,3})\.){3}([0-9]{1,3}){1}' | grep -vE '25[6-9]|2[6-9][0-9]|[3-9][0-9][0-9]'; then
          srcip_oct1=$(echo "$DEST_IP" | cut -d "." -f1)
          srcip_oct2=$(echo "$DEST_IP" | cut -d "." -f2)
          srcip_oct3=$(echo "$DEST_IP" | cut -d "." -f3)
          srcip_oct4=$(echo "$DEST_IP" | cut -d "." -f4)

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
      fi
      Chk_IPSET_List_Ready "$IPSET_NAME"

      TARGET_ROUTE=$(echo "$ENTRY" | cut -d ">" -f 5)
      my_logger "THE VALUE OF TARGET ROUTE 2b: $TARGET_ROUTE"
      [ "$TARGET_ROUTE" = "WAN" ] && FWMARK=0x8000/0x8000 && PRIO=9990

      IPSET_NAME="$DESC"

      if [ "$TARGET_ROUTE" = "VPN" ]; then
        case "$VPN_UNIT" in
        1)
          FWMARK=0x1000/0x1000
          PRIO=9995
          ;;
        2)
          FWMARK=0x2000/0x2000
          PRIO=9994
          ;;
        3)
          FWMARK=0x4000/0x4000
          PRIO=9993
          ;;
        4)
          FWMARK=0x7000/0x7000
          PRIO=9992
          ;;
        5)
          FWMARK=0x3000/0x3000
          PRIO=9991
          ;;
        esac
      fi

      if [ "$READY" -eq 0 ]; then
        #logger -st "($(basename "$0"))" $$ "Debugger VARS-> SRC:$SRC IPSET_NAME:$IPSET_NAME DIM:$DIM FWMARK:$FWMARK"
        iptables -t mangle -D PREROUTING "$SRC" -i br0 -m set --match-set "$IPSET_NAME" "$DIM" -j MARK --set-mark "$FWMARK"
        iptables -t mangle -A PREROUTING "$SRC" -i br0 -m set --match-set "$IPSET_NAME" "$DIM" -j MARK --set-mark "$FWMARK" && logger -st "($(basename "$0"))" $$ "Routing rules created for IPSET list $IPSET_NAME"
      else
        logger -st "($(basename "$0"))" $$ "IPSET save/restore file for IPSET list $IPSET_NAME not available. Unable to create routing rule."
      fi

    fi
    ######################################################################## End of IPSET Mods

  done
  IFS=$OLDIFS
  ########################################################################################## Modified Martineau Hack 1 of 5
  # Xentrk: modified prior and updated to use fwmark/bitmask format
  logger -st "($(basename "$0"))" $$ "x3mRouting Checking Custom fwmark/bitmask"

  if [ "$(ip rule | grep -c "from all fwmark 0x8000/0x8000 lookup main")" -eq "0" ]; then
    ip rule add from 0/0 fwmark 0x8000/0x8000 table 254 prio 9990
    logger -st "($(basename "$0"))" $$ "x3mRouting Adding WAN0 RPDB fwmark rule 0x8000/0x8000 prio 9990"
  fi

  ############################# Create ip rule fwmark/bitmask for OpenVPN Client Table
  case "${VPN_UNIT}" in
  1)
    FWMARK=0x1000/0x1000
    PRIO=9995
    ;;
  2)
    FWMARK=0x2000/0x2000
    PRIO=9994
    ;;
  3)
    FWMARK=0x4000/0x4000
    PRIO=9993
    ;;
  4)
    FWMARK=0x7000/0x7000
    PRIO=9992
    ;;
  5)
    FWMARK=0x3000/0x3000
    PRIO=9991
    ;;
  esac

  if [ "$(ip rule | grep -c "from all fwmark $FWMARK")" -eq "0" ]; then
    ip rule add from 0/0 fwmark "$FWMARK" table "11${VPN_UNIT}" prio "$PRIO"
    logger -st "($(basename "$0"))" $$ "x3mRouting Adding OVPNC${VPN_UNIT} RPDB fwmark rule $FWMARK prio $PRIO"
  fi
  ################################################################################################################
}

purge_client_list() {
  IP_LIST=$(ip rule show | cut -d ":" -f 1)
  for PRIO in $IP_LIST; do
    if [ "$PRIO" -ge "$START_PRIO" ] && [ "$PRIO" -le "$END_PRIO" ]; then
      ########################################################################################## Martineau Hack 2 of 5
      if [ "$PRIO" -eq "9990" ]; then
        logger -t "($(basename "$0"))" $$ "Skipping deletion of rule $PRIO unoffically reserved for WAN fwmark 0x8000/0x8000"
      else
        #################################################################################################################
        ip rule del prio "$PRIO"
        logger -t "($(basename "$0"))" $$ "Removing rule $PRIO from routing policy"
      fi
    fi
  done

  ####################### Xentrk Hack remove iptable rules for IPSET lists
  case "$VPN_UNIT" in
  1) FWMARK=0x1000 ;; # table 111
  2) FWMARK=0x2000 ;; # table 112
  3) FWMARK=0x4000 ;; # table 113
  4) FWMARK=0x7000 ;; # table 114
  5) FWMARK=0x3000 ;; # table 115
  esac

  # delete PREROUTING rules for VPN Client Routing
  iptables -nvL PREROUTING -t mangle --line | grep "match-set" | grep "$FWMARK" | awk '{print $1, $12}' | sort -nr | while read -r CHAIN_NUM IPSET_NAME; do
    iptables -t mangle -D PREROUTING "$CHAIN_NUM" && logger -t "($(basename "$0"))" $$ "Deleting PREROUTING Chain $CHAIN_NUM for IPSET List $IPSET_NAME"
  done

  # delete PREROUTING rules for VPN Client Bypass Routing
  iptables -nvL PREROUTING -t mangle --line | grep "match-set" | grep "0x8000" | awk '{print $1, $12}' | sort -nr | while read -r CHAIN_NUM IPSET_NAME; do
    if [ "$(nvram show | grep vpn_client_clientlist | grep -c "$IPSET_NAME")" -eq 1 ] && [ "$(echo "$VPN_IP_LIST" | grep -c "$IPSET_NAME")" -eq 0 ]; then
      iptables -t mangle -D PREROUTING "$CHAIN_NUM" && logger -t "($(basename "$0"))" $$ "Deleting PREROUTING Chain $CHAIN_NUM for IPSET List $IPSET_NAME"
    fi
  done

  ###################### Xentrk Hack remove fwmark/bitmask for OpenVPN Client
  ip rule del fwmark "$FWMARK/$FWMARK" 2>/dev/null
  ############################################# Xentrk Hack

}

run_custom_script() {
  if [ -f /jffs/scripts/openvpn-event ]; then
    /usr/bin/logger -t "custom_script" "Running /jffs/scripts/openvpn-event (args: $PARAM)"
    /bin/sh /jffs/scripts/openvpn-event $PARAM
  fi
}

init_table() {
  my_logger "Creating VPN routing table (mode $VPN_REDIR)"
  ip route flush table "$VPN_TBL"

  # Fill it with copy of existing main table
  if [ "$VPN_REDIR" -eq 3 ]; then
    LANIFNAME=$(nvram get lan_ifname)
    ip route show table main dev "$LANIFNAME" | while read -r ROUTE; do
      ip route add table "$VPN_TBL" $ROUTE dev "$LANIFNAME"
    done
    ip route show table main dev "$dev" | while read -r ROUTE; do
      ip route add table "$VPN_TBL" $ROUTE dev "$dev"
    done
  elif [ "$VPN_REDIR" -eq 2 ]; then
    ip route show table main | while read -r ROUTE; do
      ip route add table "$VPN_TBL" $ROUTE
    done
  fi
}

Set_VPN_NVRAM_Vars() {

  VPN_UNIT=$(echo "$dev" | awk '{ string=substr($0, 5, 5); print string; }')
  VPN_IP_LIST="$(nvram get vpn_client"$VPN_UNIT"_clientlist)"
  for n in 1 2 3 4 5; do
    VPN_IP_LIST="${VPN_IP_LIST}$(nvram get vpn_client"$VPN_UNIT"_clientlist$n)"
  done
  #### Xentrk: update vpnrouting.sh to use /jffs/addons/x3mRouting/ovpncX.nvram file
  if [ -s "/jffs/addons/x3mRouting/ovpnc${VPN_UNIT}.nvram" ]; then
    VPN_IP_LIST="${VPN_IP_LIST}$(cat "/jffs/addons/x3mRouting/ovpnc${VPN_UNIT}.nvram")"
    logger -st "($(basename "$0"))" $$ "x3mRouting adding /jffs/addons/x3mRouting/ovpnc${VPN_UNIT}.nvram to VPN_IP_LIST"
  fi
  #### end of custom code
  VPN_REDIR=$(nvram get vpn_client"$VPN_UNIT"_rgw)
  VPN_FORCE=$(nvram get vpn_client"$VPN_UNIT"_enforce)
  VPN_LOGGING=$(nvram get vpn_client"$VPN_UNIT"_verb)
  VPN_TBL="ovpnc${VPN_UNIT}"
  START_PRIO=$((10000 + (200 * (VPN_UNIT - 1))))
  END_PRIO=$((START_PRIO + 199))
  WAN_PRIO=$START_PRIO
  VPN_PRIO=$((START_PRIO + 100))

}

# Begin
case "$dev" in
tun11 | tun12 | tun13 | tun14 | tun15) Set_VPN_NVRAM_Vars ;;
*) run_custom_script && exit 0 ;;
esac

# webui reports that vpn_force changed while vpn client was down
if [ "$script_type" = "rmupdate" ]; then
  #logger "..script_type=> rmupdate"
  my_logger "Refreshing policy rules for client $VPN_UNIT"
  purge_client_list

  if [ "$VPN_FORCE" -eq 1 ] && [ "$VPN_REDIR" -ge 2 ]; then
    init_table
    my_logger "Tunnel down - VPN client access blocked"
    ip route del default table "$VPN_TBL"
    ip route add prohibit default table "$VPN_TBL"
    create_client_list
  else
    my_logger "Allow WAN access to all VPN clients"
    ip route flush table "$VPN_TBL"
  fi
  ip route flush cache
  exit 0
fi

if [ "$script_type" = "route-up" ] && [ "$VPN_REDIR" -lt 2 ]; then
  my_logger "Skipping, client $VPN_UNIT not in routing policy mode"
  run_custom_script
  exit 0
fi

/usr/bin/logger -t "openvpn-routing" "Configuring policy rules for client $VPN_UNIT"

if [ "$script_type" = "route-pre-down" ]; then
  purge_client_list

  if [ "$VPN_FORCE" -eq 1 ] && [ "$VPN_REDIR" -ge 2 ]; then
    /usr/bin/logger -t "openvpn-routing" "Tunnel down - VPN client access blocked"
    ip route change prohibit default table"$VPN_TBL"
    create_client_list
  else
    ip route flush table "$VPN_TBL"
    my_logger "Flushing client routing table"
  fi
fi # End route down

if [ "$script_type" = "route-up" ]; then
  init_table

  # Delete existing VPN routes that were pushed by server on table main
  NET_LIST=$(ip route show | awk '$2=="via" && $3==ENVIRON["route_vpn_gateway"] && $4=="dev" && $5==ENVIRON["dev"] {print $1}')
  for NET in $NET_LIST; do
    ip route del "$NET" dev "$dev"
    my_logger "Removing route for $NET to $dev from main routing table"
  done

  # Update policy rules
  purge_client_list
  create_client_list

  # Setup table default route
  if [ "$VPN_IP_LIST" != "" ]; then
    if [ "$VPN_FORCE" -eq 1 ]; then
      /usr/bin/logger -t "openvpn-routing" "Tunnel re-established, restoring WAN access to clients"
    fi
    if [ "$route_net_gateway" != "" ]; then
      ip route del default table "$VPN_TBL"
      ip route add default via "$route_vpn_gateway" table "$VPN_TBL"
    else
      /usr/bin/logger -t "openvpn-routing" "WARNING: no VPN gateway provided, routing might not work properly!"
    fi
  fi

  if [ "$route_net_gateway" != "" ]; then
    ip route del default
    ip route add default via "$route_net_gateway"
  fi
fi # End route-up

ip route flush cache
my_logger "Completed routing policy configuration for client $VPN_UNIT"
run_custom_script

exit 0
