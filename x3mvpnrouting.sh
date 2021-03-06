#!/bin/sh
###########################################################################################################
# Script: x3mvpnrouting.sh
# VERSION=1.2.0
# Author: Xentrk
# Date: 22-October-2020
############################################################################################################
# shellcheck disable=SC2086
# -- Disabled quote for processing array variable PARAM on line 274
# shellcheck disable=SC2021
# -- SC2021: Don't use [] around classes in tr, it replaces literal square brackets.

#PARAM=$*
# Add paramaters equivalent to those passed for up command
#[ -z "$PARAM" ] && PARAM="$dev $tun_mtu $link_mtu $ifconfig_local $ifconfig_remote"

my_logger() {
  if [ "$VPN_LOGGING" -gt "2" ]; then
    /usr/bin/logger -st "($(basename "$0"))" "$1"
  fi
}

Chk_IPSET_List_Ready() {

  # ARGS [wait attempts] [specific_entware_utility]
  IPSET_NAME=$1
  READY=1 # Assume IPSET list is NOT available
  MAX_TRIES=120

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

  ########################################################################################## Modified Martineau Hack 1 of 5
  # Xentrk: modified prior and updated to use fwmark/bitmask format
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

  ################################################################################################################

  OLDIFS=$IFS
  IFS="<"

  for ENTRY in $VPN_IP_LIST; do
    [ -z "$ENTRY" ] && continue
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
    if [ "$VPN_IP" != "0.0.0.0" ] && [ -n "$VPN_IP" ]; then
      SRCC="from"
      SRCA="$VPN_IP"
    else
      SRCC=""
      SRCA=""
    fi
    DST_IP=$(echo "$ENTRY" | cut -d ">" -f 3)
    if [ "$DST_IP" != "0.0.0.0" ] && [ -n "$DST_IP" ]; then
      DSTC="to"
      DSTA="$DST_IP"
    else
      DSTC=""
      DSTA=""
    fi
    if [ -n "$SRCC" ] || [ -n "$DSTC" ]; then
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
      IPSET_NAME="$DESC"
      Chk_IPSET_List_Ready "$IPSET_NAME"

      TARGET_ROUTE=$(echo "$ENTRY" | cut -d ">" -f 5)

      if [ "$TARGET_ROUTE" = "WAN" ]; then
        FWMARK=0x8000/0x8000
        PRIO=9990
        if [ "$(ip rule | grep -cm 1 "$FWMARK")" -eq 0 ]; then
          ip rule add from 0/0 fwmark 0x8000/0x8000 table 254 prio "$PRIO" && logger -st "($(basename "$0"))" $$ "x3mRouting Adding WAN0 RPDB fwmark rule 0x8000/0x8000 prio 9990"
          ip route flush cache
        fi
      fi

      if [ "$(ip rule | grep -cm 1 "$FWMARK")" -eq 0 ]; then
        ip rule add from 0/0 fwmark "$FWMARK" table "11${VPN_UNIT}" prio "$PRIO" && logger -st "($(basename "$0"))" $$ "x3mRouting Adding OVPNC${VPN_UNIT} RPDB fwmark rule $FWMARK prio $PRIO"
        ip route flush cache
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

  # Restore FWMARKS used by IPSET lists that got removed when VPN was in down state
  # WAN
  if [ "$(ip rule | grep -cm 1 "0x8000/0x8000")" -eq 0 ]; then
      ip rule add from 0/0 fwmark "0x8000/0x8000" table 254 prio 9990 && logger -st "($(basename "$0"))" $$ "Created fwmark 0x8000/0x8000"
      ip route flush cache
  fi
  # VPN Client
  if [ "$(ip rule | grep -cm 1 "$FWMARK")" -eq 0 ]; then
    ip rule add from 0/0 fwmark "$FWMARK" table ovpnc"${VPN_UNIT}" prio "$PRIO" && logger -st "($(basename "$0"))" $$ "Created fwmark $FWMARK"
    ip route flush cache
  fi

}

purge_client_list() {
  IP_LIST=$(ip rule show | cut -d ":" -f 1)
  for PRIO in $IP_LIST; do
    if [ "$PRIO" -ge "$START_PRIO" ] && [ "$PRIO" -le "$END_PRIO" ]; then
      ########################################################################################## Martineau Hack 2 of 5
      if [ "$PRIO" -eq "9990" ]; then
        logger -st "($(basename "$0"))" $$ "Skipping deletion of rule $PRIO unoffically reserved for WAN fwmark 0x8000/0x8000"
      else
        #################################################################################################################
        ip rule del prio "$PRIO"
        logger -st "($(basename "$0"))" $$ "Removing rule $PRIO from routing policy"
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
    iptables -t mangle -D PREROUTING "$CHAIN_NUM" && logger -st "($(basename "$0"))" $$ "Deleting PREROUTING Chain $CHAIN_NUM for IPSET List $IPSET_NAME"
  done

  # delete PREROUTING rules for VPN Client Bypass Routing
  iptables -nvL PREROUTING -t mangle --line | grep "match-set" | grep "0x8000" | awk '{print $1, $12}' | sort -nr | while read -r CHAIN_NUM IPSET_NAME; do
    if [ "$(nvram show | grep vpn_client_clientlist | grep -c "$IPSET_NAME")" -eq 1 ] && [ "$(echo "$VPN_IP_LIST" | grep -c "$IPSET_NAME")" -eq 0 ]; then
      iptables -t mangle -D PREROUTING "$CHAIN_NUM" && logger -st "($(basename "$0"))" $$ "Deleting PREROUTING Chain $CHAIN_NUM for IPSET List $IPSET_NAME"
    fi
  done

  ###################### Xentrk Hack remove fwmark/bitmask for OpenVPN Client
  # VPN Client
  ip rule del fwmark "$FWMARK/$FWMARK" && logger -st "($(basename "$0"))" $$ "00 Deleting fwmark $FWMARK/$FWMARK"
  # WAN fwmark 0x8000\0x8000 is not removed!

}

Set_VPN_Vars() {

  VPN_UNIT=$INSTANCE
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

INSTANCE=$1
SCRIPT_TYPE=$2

case "$INSTANCE" in
1 | 2 | 3 | 4 | 5) Set_VPN_Vars ;;
esac

if [ "$SCRIPT_TYPE" = "route-pre-down" ]; then
  purge_client_list
  if [ "$VPN_FORCE" -eq 1 ] && [ "$VPN_REDIR" -ge 2 ]; then
    create_client_list
  fi
fi

if [ "$SCRIPT_TYPE" = "route-up" ]; then
  purge_client_list
  create_client_list
fi

/usr/bin/logger -st "x3mRouting" "Configuring policy rules for client $VPN_UNIT"

logger -st "($(basename "$0"))" $$ "Completed routing policy configuration for client $VPN_UNIT"

exit 0
