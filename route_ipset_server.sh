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
logger -st "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging
#set -x

# check if /jffs/scripts/x3mRouting/vpnserverX-up exists and has entry
Check_vpnserverX_up() {

  DNSMASQ_ENTRY=$1

  if [ -s /jffs/configs/dnsmasq.conf.add ]; then # dnsmasq.conf.add file exists
    if [ "$(grep -c "$DNSMASQ_ENTRY" "/jffs/configs/dnsmasq.conf.add")" -ge "1" ]; then # if true, then one or more lines exist in dnsmasq.conf.add
      if [ "$2" = "del" ]; then
        sed -i "/^ipset.*${IPSET_NAME}$/d" /jffs/configs/dnsmasq.conf.add
        logger -st "($(basename "$0"))" $$ ipset="$DNSMASQ_ENTRY" deleted from "/jffs/configs/dnsmasq.conf.add"
      fi
    else
      echo "ipset=$DNSMASQ_ENTRY" >>/jffs/configs/dnsmasq.conf.add # add 'ipset=' domains entry to dnsmasq.conf.add
    fi
    service restart_dnsmasq >/dev/null 2>&1
  else
    if [ "$2" != "del" ]; then
      printf 'ipset=%s\n' "$DNSMASQ_ENTRY" >/jffs/configs/dnsmasq.conf.add # dnsmasq.conf.add does not exist, create dnsmasq.conf.add
      logger -st "($(basename "$0"))" $$ "ipset=$DNSMASQ_ENTRY" added to "/jffs/configs/dnsmasq.conf.add"
      service restart_dnsmasq >/dev/null 2>&1
    fi
  fi
}

# check if /jffs/scripts/x3mRouting/vpnserverX-down exists and has entry
Check_vpnserverX_down() {

  DNSMASQ_ENTRY=$1

  if [ -s /jffs/configs/dnsmasq.conf.add ]; then # dnsmasq.conf.add file exists
    if [ "$(grep -c "$DNSMASQ_ENTRY" "/jffs/configs/dnsmasq.conf.add")" -ge "1" ]; then # if true, then one or more lines exist in dnsmasq.conf.add
      if [ "$2" = "del" ]; then
        sed -i "/^ipset.*${IPSET_NAME}$/d" /jffs/configs/dnsmasq.conf.add
        logger -st "($(basename "$0"))" $$ ipset="$DNSMASQ_ENTRY" deleted from "/jffs/configs/dnsmasq.conf.add"
      fi
    else
      echo "ipset=$DNSMASQ_ENTRY" >>/jffs/configs/dnsmasq.conf.add # add 'ipset=' domains entry to dnsmasq.conf.add
    fi
    service restart_dnsmasq >/dev/null 2>&1
  else
    if [ "$2" != "del" ]; then
      printf 'ipset=%s\n' "$DNSMASQ_ENTRY" >/jffs/configs/dnsmasq.conf.add # dnsmasq.conf.add does not exist, create dnsmasq.conf.add
      logger -st "($(basename "$0"))" $$ "ipset=$DNSMASQ_ENTRY" added to "/jffs/configs/dnsmasq.conf.add"
      service restart_dnsmasq >/dev/null 2>&1
    fi
  fi
}

Routing_Rules() {

  VPN_SERVER_INSTANCE=$1
  IPSET_NAME=$2
  TAG_MARK=$3
  DEL_FLAG=$4
    IPTABLES_D_ENTRY="iptables -t mangle -D PREROUTING -i tun2$VPN_SERVER_INSTANCE -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK" >/dev/null 2>&1"
  IPTABLES_A_ENTRY=iptables -t mangle -A PREROUTING -i tun2$VPN_SERVER_INSTANCE -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK"

if [ "$4" != "del" ]; then
  if [ -s /jffs/sciprts/x3mRouting/vpnserver$VPN_SERVER_INSTANCE-up ]; then #file exists
  for iptables_entry in "$IPTABLES_D_ENTRY" "$IPTABLES_A_ENTRY";
    do
  #Check if an existing entry exists
  # If entry exist, don't add.
  # If entry doesn't not exist, add.
    done


  printf 'ipset=%s\n' "$DNSMASQ_ENTRY" >/jffs/configs/dnsmasq.conf.add # dnsmasq.conf.add does not exist, create dnsmasq.conf.add
  logger -st "($(basename "$0"))" $$ "ipset=$DNSMASQ_ENTRY" added to "/jffs/configs/dnsmasq.conf.add"
  service restart_dnsmasq >/dev/null 2>&1
fi
  if [ -s /jffs/sciprts/x3mRouting/vpnserver-up ]; then #file exists
    if [ "$(grep -c "$DNSMASQ_ENTRY" "/jffs/scripts/x3mRouting/vpnserver-up")" -ge "1" ]; then # if true, then one or more lines exist in dnsmasq.conf.add
      if [ "$4" = "del" ]; then
        sed -i "/^ipset.*${IPSET_NAME}$/d" /jffs/configs/dnsmasq.conf.add
        logger -st "($(basename "$0"))" $$ ipset="$DNSMASQ_ENTRY" deleted from "/jffs/configs/dnsmasq.conf.add"
      fi
    else
      echo "ipset=$DNSMASQ_ENTRY" >>/jffs/configs/dnsmasq.conf.add # add 'ipset=' domains entry to dnsmasq.conf.add
    fi
    service restart_dnsmasq >/dev/null 2>&1
  else
    if [ "$2" != "del" ]; then
      printf 'ipset=%s\n' "$DNSMASQ_ENTRY" >/jffs/configs/dnsmasq.conf.add # dnsmasq.conf.add does not exist, create dnsmasq.conf.add
      logger -st "($(basename "$0"))" $$ "ipset=$DNSMASQ_ENTRY" added to "/jffs/configs/dnsmasq.conf.add"
      service restart_dnsmasq >/dev/null 2>&1
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

# Check for valid VPN Server parameter. Expecting a 1 or 2.
if [ -n "$1" ]; then
  if [ $1 -ne 1 ] || [ $1 -ne 2 ]; then
    Error_Exit 'Error! Expecting a 1 or 2 for VPN Server\n'
  fi
fi

# Check if IPSET parameter passed
if [ -z "$IPSET_NAME" ]; then
  Error_Exit "ERROR! Missing args 'ipset_name'"
fi

# Check if IPSET list exists
if [ -n "$2" ]; then
  IPSET_NAME=$2
  if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" != "$IPSET_NAME" ]; then
    Error_Exit "IPSET name $IPSET_NAME does not exist"
  fi
fi

### Define interface/bitmask to route traffic to below
FWMARK=$(iptables -nvL PREROUTING -t mangle --line | grep "$IPSET_NAME" | awk '{print $16}')
TAG_MARK="$FWMARK/$FWMARK"

# Delete mode?
if [ "$(echo "$@" | grep -cw 'del')" -gt 0 ]; then
  Routing_Rules "$1" "$2" "$TAG_MARK" "del"
else
  Routing_Rules "$1" "$2" "$TAG_MARK"
fi

logger -st "($(basename "$0"))" $$ Completed Script Execution
