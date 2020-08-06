#!/bin/sh
####################################################################################################
# Script: updown-dns.sh
# VERSION=1.0.0
# Author: Xentrk
# Date: 4-August-2020
#
# Description: This script will create the appropriate VPN DNS Strict or Exclusive rules for LAN clients
# specified using the LAN Client Routing feature (Option 1 x3mRouting Menu)
#
#####################################################################################################
/usr/bin/logger -t "($(basename "$0"))" $$ "Starting script execution"

INSTANCE=$1
SCRIPT_TYPE=$2
FILEDIR="/jffs/addons/x3mRouting"
DNSSCRIPT="$FILEDIR/client${INSTANCE}_dns.sh"
RESOLVFILE="/etc/openvpn/client${INSTANCE}/client.resolv"
SERVERLINE=$(grep -m 1 "server=" "$RESOLVFILE")
SERVER=$(echo "$SERVERLINE" | sed -n "s/^.*server=//p" | awk '{print $1}')

create_client_list() {

  if [ -s "/jffs/addons/x3mRouting/ovpnc${INSTANCE}.nvram" ]; then
    VPN_IP_LIST="$(cat "/jffs/addons/x3mRouting/ovpnc${INSTANCE}.nvram")"
    OLDIFS=$IFS
    IFS="<"
    [ -s "$DNSSCRIPT" ] && rm "$DNSSCRIPT" # remove existing file if exists to prevent duplicates

    for ENTRY in $VPN_IP_LIST; do
      [ -z "$ENTRY" ] && continue
      VPN_IP=$(echo "$ENTRY" | cut -d ">" -f 2)
      if [ -n "$VPN_IP" ]; then
        TARGET_ROUTE=$(echo "$ENTRY" | cut -d ">" -f 4)
        if [ "$TARGET_ROUTE" = "VPN" ]; then
          echo "/usr/sbin/iptables -t nat -A DNSVPN${INSTANCE} -s $VPN_IP -j DNAT --to-destination $SERVER" >>"$DNSSCRIPT"
          /usr/bin/logger -t "openvpn-updown" "Forcing $VPN_IP to use DNS SERVER $SERVER"
        fi
      else
        echo "/usr/sbin/iptables -t nat -I DNSVPN${INSTANCE} -s $VPN_IP -j RETURN" >>"$DNSSCRIPT"
        /usr/bin/logger -t "openvpn-updown" "Excluding $VPN_IP from forced DNS routing"
      fi
    done
  fi

  IFS=$OLDIFS
}

### Begin

if [ "$SCRIPT_TYPE" = "up" ]; then
  if [ "$(nvram get vpn_client"${INSTANCE}"_rgw)" -ge 2 ] && [ "$(nvram get vpn_client"${INSTANCE}"_adns)" -eq 3 ]; then
    create_client_list
    [ -s "$DNSSCRIPT" ] && sed -i '1s~^~#!/bin/sh\n~' "$DNSSCRIPT" && chmod 755 "$DNSSCRIPT" && sh "$DNSSCRIPT"
  fi
fi

if [ "$SCRIPT_TYPE" = "down" ]; then
  [ -s "$DNSSCRIPT" ] && rm "$DNSSCRIPT"
fi

/usr/bin/logger -t "($(basename "$0"))" $$ "Ending script execution"

exit 0
