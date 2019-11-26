#!/bin/sh
####################################################################################################
# Script: route_all_vpnserver.sh
# VERSION=1.0.2
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
# Usage example:
#
#                              VPN Server VPN Client
#                               Instance   Instance
# Usage:   route_all_server.sh   {[1|2]  [[1|2|3|4|5]   [del]
#
# Usage:   route_all_server.sh   1   2
#             Route incoming VPN Server 1 traffic to the OpenVPN client 2 interface.
# Usage:   route_all_server.sh   1   2  del
#             Delete the routing rule for incoming VPN Server 1 traffic to be routed to the OpenVPN
#             client 2 interface.
#####################################################################################################
# -- SC2068: I don't want to quote array!
# shellcheck disable=SC2068
logger -t "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging
#set -x

Routing_Rules() {

  VPN_SERVER_INSTANCE="$1"
  IFACE="$2"
  DEL_FLAG="$3"

  VPN_SERVER_SUBNET="$(nvram get vpn_server"${VPN_SERVER_INSTANCE}"_sn)/24"
  IPTABLES_DEL_ENTRY="iptables -t nat -D POSTROUTING -s $VPN_SERVER_SUBNET -o $IFACE -j MASQUERADE 2>/dev/null"
  IPTABLES_APP_ENTRY="iptables -t nat -A POSTROUTING -s $VPN_SERVER_SUBNET -o $IFACE -j MASQUERADE"

  VPNSERVER_UP_FILE="/jffs/scripts/x3mRouting/vpnserver$VPN_SERVER_INSTANCE-up"
  VPNSERVER_DOWN_FILE="/jffs/scripts/x3mRouting/vpnserver$VPN_SERVER_INSTANCE-down"

  if [ "$DEL_FLAG" != "del" ]; then #add entry
    if [ -s "$VPNSERVER_UP_FILE" ]; then #file exists
      #Check if an existing entry exists
      for IPTABLES_ENTRY in "$IPTABLES_DEL_ENTRY" "$IPTABLES_APP_ENTRY"; do
        if [ "$(grep -c "$IPTABLES_ENTRY" "$VPNSERVER_UP_FILE")" -ge "1" ]; then # if true, then one or more lines exist
          logger -t "($(basename "$0"))" $$ "Entry for iptables rule already exists"
        else
          # add entry
          echo "$IPTABLES_ENTRY" >>"$VPNSERVER_UP_FILE"
        fi
      done
    else #file does not exist
      echo "#!/bin/sh" >"$VPNSERVER_UP_FILE"
      echo "$IPTABLES_DEL_ENTRY" >>"$VPNSERVER_UP_FILE"
      echo "$IPTABLES_APP_ENTRY" >>"$VPNSERVER_UP_FILE"
      chmod 755 "$VPNSERVER_UP_FILE"
    fi
    if [ -s "$VPNSERVER_DOWN_FILE" ]; then #file exists
      #Check if an existing entry exists
      if [ "$(grep -c "$IPTABLES_DEL_ENTRY" "$VPNSERVER_UP_FILE")" -ge "1" ]; then # if true, then one or more lines exist
        logger -t "($(basename "$0"))" $$ "Entry for iptables rule already exists"
      else
        # add entry
        echo "$IPTABLES_ENTRY" >>"$VPNSERVER_UP_FILE"
      fi
    else #file does not exist
      echo "#!/bin/sh" >"$VPNSERVER_DOWN_FILE"
      echo "$IPTABLES_DEL_ENTRY" >>"$VPNSERVER_DOWN_FILE"
      chmod 755 "$VPNSERVER_DOWN_FILE"
    fi
    # Implement routing rules
    sh "$VPNSERVER_UP_FILE"
  else
    # delete routing and routing rules in vpn server up down scripts
    iptables -t nat -D POSTROUTING -s "$VPN_SERVER_SUBNET" -o "$IFACE" -j MASQUERADE 2>/dev/null
    if [ -s "$VPNSERVER_UP_FILE" ]; then #file exists
      sed -i "/$VPN_CLIENT_INSTANCE/d" "$VPNSERVER_UP_FILE"
      logger -t "($(basename "$0"))" $$ "iptables entry deleted from $VPNSERVER_UP_FILE"
      # check if she-bang is the only line that exists and remove file if it does.
      sed -i "/^$/d" "$VPNSERVER_UP_FILE"
      if [ "$(grep "#!/bin/sh" "$VPNSERVER_UP_FILE")" = "#!/bin/sh" ] && [ "$(wc -l <"$VPNSERVER_UP_FILE")" -eq 1 ]; then
        rm -r "$VPNSERVER_UP_FILE"
      fi
    fi
    if [ -s "$VPNSERVER_DOWN_FILE" ]; then #file exists
      sed -i "/$VPN_CLIENT_INSTANCE/d" "$VPNSERVER_DOWN_FILE"
      logger -t "($(basename "$0"))" $$ "iptables entry deleted from $VPNSERVER_DOWN_FILE"
      # check if she-bang is the only line that exists and remove file if it does.
      sed -i "/^$/d" "$VPNSERVER_DOWN_FILE"
      if [ "$(grep "#!/bin/sh" "$VPNSERVER_DOWN_FILE")" = "#!/bin/sh" ] && [ "$(wc -l <"$VPNSERVER_DOWN_FILE")" -eq 1 ]; then
        rm -r "$VPNSERVER_DOWN_FILE"
      fi
    fi
  fi
}

Error_Exit() {

  error_str="$*"
  echo "$error_str"
  exit 1
}

#==================== end of functions
# Begin
VPN_SERVER_INSTANCE="$1"
VPN_CLIENT_INSTANCE="$2"
DEL_FLAG="$3"

if [ -z "$VPN_SERVER_INSTANCE" ] || [ -z "$VPN_CLIENT_INSTANCE" ]; then
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
      Error_Exit "Error! Expecting a 1 or 2 for VPN Server"
      ;;
    esac
  fi
done

# Check for valid VPN Client parameter. Expecting a 1, 2, 3, 4 or 5
while true; do
  if [ -n "$VPN_CLIENT_INSTANCE" ]; then
    case "$VPN_CLIENT_INSTANCE" in
    [1-5])
      break
      ;;
    *)
      Error_Exit "Error! Expecting a 1 thru 5 for VPN Client Instance"
      ;;
    esac
  fi
done

# Check of 3rd PARM is del flag
if [ -n "$DEL_FLAG" ]; then
  if [ "$DEL_FLAG" != "del" ]; then
    Error_Exit "Third parameter is invalid. Expecting null value or 'del'."
  fi
fi

case "$VPN_CLIENT_INSTANCE" in
1)
  IFACE="tun11"
  ;;
2)
  IFACE="tun12"
  ;;
3)
  IFACE="tun13"
  ;;
4)
  IFACE="tun14"
  ;;
5)
  IFACE="tun15"
  ;;
*)
  Error_Exit "ERROR $1 should be a 1-5=VPN"
  ;;
esac

# Delete mode?
if [ "$(echo $@ | grep -cw 'del')" -gt 0 ]; then
  Routing_Rules "$VPN_SERVER_INSTANCE" "$IFACE" "del"
else
  Routing_Rules "$VPN_SERVER_INSTANCE" "$IFACE"
fi

logger -t "($(basename "$0"))" $$ "Ending Script Execution"
