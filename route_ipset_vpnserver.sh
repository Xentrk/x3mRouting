#!/bin/sh
####################################################################################################
# Script: route_ipset_vpnserver.sh
# VERSION=1.0.1
# Author: Martineau, Xentrk
# Date: 26-November-2019
#
# Grateful:
#   Thank you to @Martineau on snbforums.com for sharing his Selective Routing expertise,
#   on-going support and collaboration on this project!
#
####################################################################################################
# Script Description:
#
#
#
# Usage example:
#
# Usage:   route_ipset_server.sh   {[1|2]   ipset_name   [del]
#
# Usage:   route_ipset_server.sh   1   BBC
#             Route incoming VPN Server 1 traffic to the interface defined for the IPSET list.
# Usage:   route_ipset_server.sh   1   BBC   del
#             Delete the routing rule for VPN Server 1 traffic defined for the IPSET list.
##########################################################################################
# -- SC2068: I don't want to quote array!
# shellcheck disable=SC2068
# -- SC2039: In POSIX sh, string indexing is undefined.
# shellcheck disable=SC2039

logger -t "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging
#set -x

# check if /jffs/scripts/x3mRouting/vpnserverX-down exists and has entry
Routing_Rules() {

  VPN_SERVER_INSTANCE=$1
  IFACE=$2
  IPSET_NAME=$3
  TAG_MARK=$4
  DEL_FLAG=$5

  # Get VPN Server Subnet Mask
  VPN_SERVER_IP=$(nvram get vpn_server"$VPN_SERVER_INSTANCE"_sn)

  # POSTROUTING CHAIN
  IPTABLES_POSTROUTING_DEL_ENTRY="iptables -t nat -D POSTROUTING -s $VPN_SERVER_IP/24 -o $IFACE -j MASQUERADE 2>/dev/null"
  IPTABLES_POSTROUTING_APP_ENTRY="iptables -t nat -A POSTROUTING -s $VPN_SERVER_IP/24 -o $IFACE -j MASQUERADE"

  # PREROUTING CHAIN
  IPTABLES_PREROUTING_DEL_ENTRY="iptables -t mangle -D PREROUTING -i tun21 -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK 2>/dev/null"
  IPTABLES_PREROUTING_APP_ENTRY="iptables -t mangle -A PREROUTING -i tun21 -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK"

  VPNSERVER_UP_FILE="/jffs/scripts/x3mRouting/vpnserver$VPN_SERVER_INSTANCE-up"
  VPNSERVER_DOWN_FILE="/jffs/scripts/x3mRouting/vpnserver$VPN_SERVER_INSTANCE-down"

  if [ "$DEL_FLAG" != "del" ]; then #add entry
    if [ -s "VPNSERVER_UP_FILE" ]; then #file exists
      #Check if an existing entry exists
      for IPTABLES_ENTRY in "$IPTABLES_POSTROUTING_DEL_ENTRY" "$IPTABLES_POSTROUTING_APP_ENTRY" "$IPTABLES_PREROUTING_DEL_ENTRY" "$IPTABLES_PREROUTING_APP_ENTRY"; do
        if [ "$(grep -c "$IPTABLES_ENTRY" "$VPNSERVER_UP_FILE")" -ge "1" ]; then # if true, then one or more lines exist
          logger -t "($(basename "$0"))" $$ "Entry for iptables rule already exists"
        else
          # add entry
          echo "$IPTABLES_ENTRY" >>"$VPNSERVER_UP_FILE"
        fi
      done
    else #file does not exist
      true >"$VPNSERVER_UP_FILE"
      {
        echo "#!/bin/sh"
        echo "$IPTABLES_POSTROUTING_DEL_ENTRY"
        echo "$IPTABLES_POSTROUTING_APP_ENTRY"
        echo "$IPTABLES_PREROUTING_DEL_ENTRY"
        echo "$IPTABLES_PREROUTING_APP_ENTRY"
      } >>"$VPNSERVER_UP_FILE"
      chmod 755 "$VPNSERVER_UP_FILE"
    fi
    if [ -s "$VPNSERVER_DOWN_FILE" ]; then #file exists
      #Check if an existing entry exists
      for IPTABLES_ENTRY in "$IPTABLES_POSTROUTING_DEL_ENTRY" "$IPTABLES_PREROUTING_DEL_ENTRY"; do
        if [ "$(grep -c "$IPTABLES_ENTRY" "$VPNSERVER_DOWN_FILE")" -ge "1" ]; then # if true, then one or more lines exist
          logger -t "($(basename "$0"))" $$ "Entry for iptables rule already exists"
        else
          # add entry
          echo "$IPTABLES_ENTRY" >>"$VPNSERVER_DOWN_FILE"
        fi
      done
    else #file does not exist
      true >"$VPNSERVER_DOWN_FILE"
      {
        echo "#!/bin/sh"
        echo "$IPTABLES_POSTROUTING_DEL_ENTRY"
        echo "$IPTABLES_PREROUTING_DEL_ENTRY"
      } >>"$VPNSERVER_DOWN_FILE"
      chmod 755 "$VPNSERVER_DOWN_FILE"
    fi
    sh "$VPNSERVER_UP_FILE"
  else # del option selected. delete entries
    iptables -t mangle -D PREROUTING -i tun21 -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK" 2>/dev/null
    iptables -t nat -D POSTROUTING -s "$VPN_SERVER_IP"/24 -o "$IFACE" -j MASQUERADE 2>/dev/null
    if [ -s "$VPNSERVER_UP_FILE" ]; then
      sed -i "/$IPSET_NAME/d" "$VPNSERVER_UP_FILE"
      sed -i "/$IFACE/d" "$VPNSERVER_UP_FILE"
      logger -t "($(basename "$0"))" $$ "iptables entry deleted from $VPNSERVER_UP_FILE"
      # check if ony she-ban exists and remove file if it does.
      sed -i "/^$/d" "$VPNSERVER_UP_FILE"
      if [ "$(grep "#!/bin/sh" "$VPNSERVER_UP_FILE")" = "#!/bin/sh" ] && [ "$(wc -l <"$VPNSERVER_UP_FILE")" -eq 1 ]; then
        rm -r "$VPNSERVER_UP_FILE"
      fi
    fi
    if [ -s "$VPNSERVER_DOWN_FILE" ]; then
      sed -i "/$IPSET_NAME/d" "$VPNSERVER_DOWN_FILE"
      sed -i "/$IFACE/d" "$VPNSERVER_DOWN_FILE"
      logger -t "($(basename "$0"))" $$ "iptables entry deleted from $VPNSERVER_DOWN_FILE"
      # check if ony she-ban exists and remove file if it does.
      sed -i "/^$/d" "$VPNSERVER_DOWN_FILE"
      if [ "$(grep "#!/bin/sh" "$VPNSERVER_DOWN_FILE")" = "#!/bin/sh" ] && [ "$(wc -l <"$VPNSERVER_DOWN_FILE")" -eq 1 ]; then
        rm -r "$VPNSERVER_DOWN_FILE"
      fi
    fi
  fi
}

Error_Exit() {

  error_str=$*
  echo "$error_str"
  exit 1
}

#====================> end of functions <====================#
# Begin

VPN_SERVER_INSTANCE="$1"
IPSET_NAME="$2"
DEL_FLAG="$3"

# Check for two parameters passesd

if [ -z "$VPN_SERVER_INSTANCE" ] || [ -z "$IPSET_NAME" ]; then
  Error_Exit "Error! Expecting 2 parameters to be passed to script."
fi

# Check for valid VPN Server parameter. Expecting a 1 or 2.

while true; do
  if [ -n "$VPN_SERVER_INSTANCE" ]; then
    case "$VPN_SERVER_INSTANCE" in
    [1-2])
      break
      ;;
    *)
      Error_Exit "Error! Expecting a 1 or 2 for VPN Server."
      ;;
    esac
  fi
done

# Check if IPSET list exists
if [ -n "$IPSET_NAME" ]; then
  if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" != "$IPSET_NAME" ]; then
    Error_Exit "IPSET name $IPSET_NAME does not exist."
  fi
fi

# Check of 3rd PARM is del flag
if [ -n "$DEL_FLAG" ]; then
  if [ "$DEL_FLAG" != "del" ]; then
    Error_Exit "Third parameter is invalid. Expecting null value or 'del'."
  fi
fi

### Define interface/bitmask to route traffic to. Use existing PREROUTING rule for IPSET to determine FWMARK.

FWMARK=$(iptables -nvL PREROUTING -t mangle --line | grep "br0" | grep "$IPSET_NAME" | awk '{print $16}')

if [ -z "$FWMARK" ]; then
  Error_Exit "Error! Mandatory PREROUTING rule for IPSET name $IPSET_NAME does not exist."
fi

TAG_MARK="$FWMARK/$FWMARK"
VPN_CLIENT_INSTANCE="${FWMARK:2:6}"

case "$VPN_CLIENT_INSTANCE" in
8000)
  IFACE="br0"
  ;;
1000)
  IFACE="tun11"
  ;;
2000)
  IFACE="tun12"
  ;;
4000)
  IFACE="tun13"
  ;;
7000)
  IFACE="tun14"
  ;;
3000)
  IFACE="tun15"
  ;;
*)
  Error_Exit "ERROR $1 should be a 1-5=VPN"
  ;;
esac

# Delete mode?
if [ "$(echo $@ | grep -cw 'del')" -gt 0 ]; then
  Routing_Rules "$VPN_SERVER_INSTANCE" "$IFACE" "$IPSET_NAME" "$TAG_MARK" "del"
else
  Routing_Rules "$VPN_SERVER_INSTANCE" "$IFACE" "$IPSET_NAME" "$TAG_MARK"
fi

logger -t "($(basename "$0"))" $$ "Ending Script Execution"
