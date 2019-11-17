#!/bin/sh
####################################################################################################
# Script: route_all_server.sh
# VERSION=1.0.0
# Author: Martineau, Xentrk
# Date: 10-November-2019
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
logger -t "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging
#set -x

Routing_Rules() {

  VPN_SERVER_INSTANCE="$1"
  IFACE="$2"
  DEL_FLAG="$3"

  VPN_SERVER_SUBNET="$(nvram get vpn_server"${VPN_SERVER_INSTANCE}"_sn)/24"
  IPTABLES_D_ENTRY="iptables -D POSTROUTING -t nat -s $VPN_SERVER_SUBNET -o $IFACE -j MASQUERADE >/dev/null 2>&1"
  IPTABLES_A_ENTRY="iptables -A POSTROUTING -t nat -s $VPN_SERVER_SUBNET -o $IFACE -j MASQUERADE"

  vpnserver_up_file=/jffs/scripts/x3mRouting/vpnserver$VPN_SERVER_INSTANCE-up
  vpnserver_down_file=/jffs/scripts/x3mRouting/vpnserver$VPN_SERVER_INSTANCE-down

  if [ "$DEL_FLAG" != "del" ]; then #add entry
    if [ -s "/jffs/scripts/x3mRouting/vpnserver$VPN_SERVER_INSTANCE-up" ]; then #file exists
      #Check if an existing entry exists
      for iptables_entry in "$IPTABLES_D_ENTRY" "$IPTABLES_A_ENTRY"; do
        if [ "$(grep -c "$iptables_entry" "$vpnserver_up_file")" -ge "1" ]; then # if true, then one or more lines exist
          logger -t "($(basename "$0"))" $$ "Entry for iptables rule already exists"
        else
          # add entry
          echo "$iptables_entry" >>"$vpnserver_up_file"
        fi
      done
    else #file does not exist
      echo "#!/bin/sh" >"$vpnserver_up_file"
      echo "$IPTABLES_D_ENTRY" >>"$vpnserver_up_file"
      echo "$IPTABLES_A_ENTRY" >>"$vpnserver_up_file"
      chmod 755 "$vpnserver_up_file"
    fi
    if [ -s "/jffs/scripts/x3mRouting/vpnserver$VPN_SERVER_INSTANCE-down" ]; then #file exists
      #Check if an existing entry exists
      if [ "$(grep -c "$IPTABLES_D_ENTRY" "$vpnserver_up_file")" -ge "1" ]; then # if true, then one or more lines exist
        logger -t "($(basename "$0"))" $$ "Entry for iptables rule already exists"
      else
        # add entry
        echo "$iptables_entry" >>"$vpnserver_up_file"
      fi
    else #file does not exist
      echo "#!/bin/sh" >"$vpnserver_down_file"
      echo "$IPTABLES_D_ENTRY" >>"$vpnserver_down_file"
      chmod 755 "$vpnserver_down_file"
    fi
    service restart_vpnserver"$VPN_SERVER_INSTANCE"
  else
    # delete routing and routing rules in vpn server up down scripts
    iptables -D POSTROUTING -t nat -s "$VPN_SERVER_SUBNET" -o "$IFACE" -j MASQUERADE >/dev/null 2>&1
    sed -i "/$CLIENT_INSTANCE/d" "$vpnserver_up_file"
    logger -t "($(basename "$0"))" $$ "iptables entry deleted from $vpnserver_up_file"
    # check if she-bang is the only line that exists and remove file if it does.
    if [ "$(wc -l <"$vpnserver_up_file")" -le 1 ] && [ "$(head -n 1 "$vpnserver_up_file")" = "#!/bin/sh" ]; then
      rm -r "$vpnserver_up_file"
    fi
    sed -i "/$CLIENT_INSTANCE/d" "$vpnserver_down_file"
    logger -t "($(basename "$0"))" $$ "iptables entry deleted from $vpnserver_down_file"
    # check if she-bang is the only line that exists and remove file if it does.
    if [ "$(wc -l <"$vpnserver_down_file")" -eq 1 ] && [ "$(head -n 1 "$vpnserver_down_file")" = "#!/bin/sh" ]; then
      rm -r "$vpnserver_down_file"
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
SERVER_INSTANCE="$1"
CLIENT_INSTANCE="$2"

if [ -z "$SERVER_INSTANCE" ] || [ -z "$CLIENT_INSTANCE" ]; then
  Error_Exit 'Error! Expecting 2 parameters to be passed to script.\n'
fi

# Check for valid VPN Server parameter. Expecting a 1 or 2.
if [ -n "$SERVER_INSTANCE" ]; then
  if [ "$SERVER_INSTANCE" -ne 1 ] && [ "$SERVER_INSTANCE" -ne 2 ]; then
    Error_Exit 'Error! Expecting a 1 or 2 for VPN Server\n'
  fi
fi

# Check for valid VPN Server parameter. Expecting a 1 or 2.
if [ -n "$CLIENT_INSTANCE" ]; then
  if [ "$CLIENT_INSTANCE" -le 1 ] && [ "$SERVER_INSTANCE" -le 5 ]; then
    Error_Exit 'Error! Expecting a 1 thru 5 for VPN Client Instance\n'
  fi
fi

case "$CLIENT_INSTANCE" in
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
if [ "$(echo "$@" | grep -cw 'del')" -gt 0 ]; then
  Routing_Rules "$SERVER_INSTANCE" "$IFACE" "del"
else
  Routing_Rules "$SERVER_INSTANCE" "$IFACE"
fi

logger -t "($(basename "$0"))" $$ "Ending Script Execution"
