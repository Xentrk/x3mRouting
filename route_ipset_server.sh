#!/bin/sh
####################################################################################################
# Script: route_ipset_server.sh
# VERSION=1.0.0
# Author: Martineau, Xentrk
# Date: 9-November-2019
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
logger -t "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging
set -x

# check if /jffs/scripts/x3mRouting/vpnserverX-down exists and has entry
Routing_Rules() {

  VPN_SERVER_INSTANCE=$1
  IPSET_NAME=$2
  TAG_MARK=$3
  DEL_FLAG="$4"

  IPTABLES_D_ENTRY="iptables -t mangle -D PREROUTING -i tun2$VPN_SERVER_INSTANCE -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK >/dev/null 2>&1"

  IPTABLES_A_ENTRY="iptables -t mangle -A PREROUTING -i tun2$VPN_SERVER_INSTANCE -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK"

  vpnserver_up_file=/jffs/scripts/x3mRouting/vpnserver$VPN_SERVER_INSTANCE-up
  vpnserver_down_file=/jffs/scripts/x3mRouting/vpnserver$VPN_SERVER_INSTANCE-down

  if [ "$DEL_FLAG" != "del" ]; then #add entry
    if [ -s "/jffs/scripts/x3mRouting/vpnserver$VPN_SERVER_INSTANCE-up" ]; then #file exists
      #Check if an existing entry exists
      for iptables_entry in "$IPTABLES_D_ENTRY" "$IPTABLES_A_ENTRY"; do
        if [ "$(grep -c "$IPSET_NAME" "$vpnserver_up_file")" -ge "1" ]; then # if true, then one or more lines exist
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
  else
    sed -i "/$IPSET_NAME/d" "$vpnserver_up_file"
    logger -t "($(basename "$0"))" $$ "iptables entry deleted from $vpnserver_up_file"
    # check if on she-ban exists and remove file if it does.
    if [ $(wc -l <"$vpnserver_up_file") -le 1 ]; then
      rm -r "$vpnserver_up_file"
    fi
  fi
  # service restart_vpnserver$$VPN_SERVER_INSTANCE
}

Error_Exit() {

  error_str="$*"
  echo "$error_str"
  exit 1
}

#==================== end of functions
# Begin
SERVER_INSTANCE="$1"
IPSET_NAME="$2"

# Check for valid VPN Server parameter. Expecting a 1 or 2.
if [ -n "$SERVER_INSTANCE" ]; then
  if [ "$SERVER_INSTANCE" -ge 1 ] || [ "$SERVER_INSTANCE" -le 2 ]; then
    continue
  else
    Error_Exit 'Error! Expecting a 1 or 2 for VPN Server\n'
  fi
fi

# Check if IPSET parameter passed
if [ -z "$IPSET_NAME" ]; then
  Error_Exit "ERROR! Missing args 'ipset_name'"
fi

# Check if IPSET list exists
if [ -n "$IPSET_NAME" ]; then
  if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" != "$IPSET_NAME" ]; then
    Error_Exit "IPSET name $IPSET_NAME does not exist"
  fi
fi

### Define interface/bitmask to route traffic to below
FWMARK=$(iptables -nvL PREROUTING -t mangle --line | grep "$IPSET_NAME" | awk '{print $16}')
TAG_MARK="$FWMARK/$FWMARK"

# Delete mode?
if [ "$(echo "$@" | grep -cw 'del')" -gt 0 ]; then
  Routing_Rules "$SERVER_INSTANCE" "$IPSET_NAME" "$TAG_MARK" "del"
else
  Routing_Rules "$SERVER_INSTANCE" "$IPSET_NAME" "$TAG_MARK"
fi

logger -t "($(basename "$0"))" $$ "Ending Script Execution"
