#!/bin/sh
####################################################################################################
# Script: load_MANUAL_ipset_iface.sh
# VERSION=1.0.0
# Author: Xentrk
# Date: 6-April-2019
#
# Grateful:
#   Thank you to @Martineau on snbforums.com for sharing his Selective Routing expertise
#   and on-going support!
#
####################################################################################################
# Script Description:
#
# This script will create an IPSET list from a file containing IPv4 addresses stored in the
# /opt/tmp directory on entware.  For example, I mined the domain names from MANUAL for BBC
# and converted the domain names to their respective IPv4 addresses.  You must pass the script
# the IPSET list name.  The IPSET list name must match the name of the file containing the IPv4
# addresses stored in /opt/tmp.
#
# Usage example:
#
# Usage:     load_MANUAL_ipset_iface.sh   {[0|1|2|3|4|5]}  ipset_name [del]  [dir='directory']
#
# Usage:     load_MANUAL_ipset_iface.sh   2   BBC
#               Create IPSET BBC via VPN Client 2
# Usage:     load_MANUAL_ipset_iface.sh   2   BBC  del
#               Delete IPSET BBC and remove from VPN Client 2
# Usage:     load_MANUAL_ipset_iface.sh   2   BBC   dir=/mnt/sda1/Backups
#               As per example one, but use '/mnt/sda1/Backups' rather than Entware's 'opt/tmp' for ipset save/restore
# Usage:     load_MANUAL_ipset_iface.sh   2  BBC   del dir=/mnt/sda1/Backups
#               As per example two, but use '/mnt/sda1/Backups' rather than Entware's 'opt/tmp' for ipset save/restore location
####################################################################################################
logger -t "($(basename "$0"))" $$ Starting Script Execution
# Uncomment the line below for debugging
set -x

Kill_Lock() {
  if [ -f "/tmp/load_MANUAL_ipset_iface.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/load_MANUAL_ipset_iface.lock)" ]; then
    logger -st "($(basename "$0"))" "[*] Killing Locked Processes ($(sed -n '1p' /tmp/load_MANUAL_ipset_iface.lock)) (pid=$(sed -n '2p' /tmp/load_MANUAL_ipset_iface.lock))"
    logger -st "($(basename "$0"))" "[*] $(ps | awk -v pid="$(sed -n '2p' /tmp/load_MANUAL_ipset_iface.lock)" '$1 == pid')"
    kill "$(sed -n '2p' /tmp/load_MANUAL_ipset_iface.lock)"
    rm -rf /tmp/load_MANUAL_ipset_iface.lock
    echo
  fi
}

Check_Lock() {
  if [ -f "/tmp/load_MANUAL_ipset_iface.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/load_MANUAL_ipset_iface.lock)" ] && [ "$(sed -n '2p' /tmp/load_MANUAL_ipset_iface.lock)" != "$$" ]; then
    if [ "$(($(date +%s) - $(sed -n '3p' /tmp/load_MANUAL_ipset_iface.lock)))" -gt "1800" ]; then
      Kill_Lock
    else
      logger -st "($(basename "$0"))" "[*] Lock File Detected ($(sed -n '1p' /tmp/load_MANUAL_ipset_iface.lock)) (pid=$(sed -n '2p' /tmp/load_MANUAL_ipset_iface.lock)) - Exiting (cpid=$$)"
      echo
      exit 1
    fi
  fi
  echo "$@" >/tmp/load_MANUAL_ipset_iface.lock
  echo "$$" >>/tmp/load_MANUAL_ipset_iface.lock
  date +%s >>/tmp/load_MANUAL_ipset_iface.lock
  lock_load_MANUAL_ipset_iface="true"
}

# Chk_Entware function provided by @Martineau at snbforums.com

Chk_Entware() {

  # ARGS [wait attempts] [specific_entware_utility]

  READY=1 # Assume Entware Utilities are NOT available
  ENTWARE="opkg"
  ENTWARE_UTILITY= # Specific Entware utility to search for
  MAX_TRIES=30

  if [ ! -z "$2" ] && [ ! -z "$(echo "$2" | grep -E '^[0-9]+$')" ]; then
    MAX_TRIES=$2
  fi

  if [ ! -z "$1" ] && [ -z "$(echo "$1" | grep -E '^[0-9]+$')" ]; then
    ENTWARE_UTILITY=$1
  else
    if [ -z "$2" ] && [ ! -z "$(echo "$1" | grep -E '^[0-9]+$')" ]; then
      MAX_TRIES=$1
    fi
  fi

  # Wait up to (default) 30 seconds to see if Entware utilities available.....
  TRIES=0

  while [ "$TRIES" -lt "$MAX_TRIES" ]; do
    if [ ! -z "$(which $ENTWARE)" ] && [ "$($ENTWARE -v | grep -o "version")" = "version" ]; then
      if [ ! -z "$ENTWARE_UTILITY" ]; then # Specific Entware utility installed?
        if [ ! -z "$("$ENTWARE" list-installed "$ENTWARE_UTILITY")" ]; then
          READY=0 # Specific Entware utility found
        else
          # Not all Entware utilities exists as a stand-alone package e.g. 'find' is in package 'findutils'
          if [ -d /opt ] && [ ! -z "$(find /opt/ -name "$ENTWARE_UTILITY")" ]; then
            READY=0 # Specific Entware utility found
          fi
        fi
      else
        READY=0 # Entware utilities ready
      fi
      break
    fi
    sleep 1
    logger -st "($(basename "$0"))" $$ "Entware" "$ENTWARE_UTILITY" "not available - wait time" $((MAX_TRIES - TRIES - 1))" secs left"
    TRIES=$((TRIES + 1))
  done

  return $READY
}

### Define interface/bitmask to route traffic to below
set_fwmark_parms() {
  FWMARK_WAN="0x8000/0x8000"
  FWMARK_OVPNC1="0x1000/0x1000"
  FWMARK_OVPNC2="0x2000/0x2000"
  FWMARK_OVPNC3="0x4000/0x4000"
  FWMARK_OVPNC4="0x7000/0x7000"
  FWMARK_OVPNC5="0x3000/0x3000"
}

set_ip_rule() {
  case "$VPNID" in
  0)
    ip rule del fwmark "$TAG_MARK" >/dev/null 2>&1
    ip rule add from 0/0 fwmark "$TAG_MARK" table 254 prio 9990
    ip route flush cache
    ;;
  1)
    ip rule del fwmark "$TAG_MARK" >/dev/null 2>&1
    ip rule add from 0/0 fwmark "$TAG_MARK" table 111 prio 9995
    ip route flush cache
    ;;

  2)
    ip rule del fwmark "$TAG_MARK" >/dev/null 2>&1
    ip rule add from 0/0 fwmark "$TAG_MARK" table 112 prio 9994
    ip route flush cache
    ;;

  3)
    ip rule del fwmark "$TAG_MARK" >/dev/null 2>&1
    ip rule add from 0/0 fwmark "TAG_MARK" table 113 prio 9993
    ip route flush cache
    ;;

  4)
    ip rule del fwmark "$TAG_MARK" >/dev/null 2>&1
    ip rule add from 0/0 fwmark "$TAG_MARK" table 114 prio 9992
    ip route flush cache
    ;;

  5)
    ip rule del fwmark "$TAG_MARK" >/dev/null 2>&1
    ip rule add from 0/0 fwmark "$TAG_MARK" table 115 prio 9991
    ip route flush cache
    ;;
  *)
    logger -st "($(basename "$0"))" $$ ERROR "$1" should be "0-WAN or 1-5=VPN"
    exit 99
    ;;
  esac
}

# if ipset list does not exist, create it
check_MANUAL_ipset_list_exist() {

  IPSET_NAME=$1
  if [ "$2" != "del" ]; then
    if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" != "$IPSET_NAME" ]; then #does ipset list exist?
      ipset create "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536 # No restore file, so create AMAZON ipset list from scratch
      logger -st "($(basename "$0"))" $$ IPSET created: "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536
    fi
  else
    if [ "$(ipset list -n "$IPSET_NAME"2>/dev/null)" = "$IPSET_NAME" ]; then # del condition is true
      ipset destroy "$IPSET_NAME" && logger -st "($(basename "$0"))" $$ "IPSET $IPSET_NAME deleted!" || logger -st "($(basename "$0"))" $$ Error attempting to delete IPSET "$IPSET_NAME"!
    fi
  fi
}

# if ipset list is empty or source file is older than 24 hours, download source file; load ipset list
check_MANUAL_ipset_list_values() {

  IPSET_NAME=$1
  DIR=$2
  if [ "$(ipset -L "$IPSET_NAME" 2>/dev/null | awk '{ if (FNR == 7) print $0 }' | awk '{print $4 }')" -eq "0" ]; then
    awk '{print "add '"$IPSET_NAME"' " $1}' "$DIR/$IPSET_NAME" | ipset restore -!
  fi
}

# Route IPSET to target WAN or VPN
create_routing_rules() {
  IPSET_NAME=$1
  iptables -t mangle -D PREROUTING -i br0 -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK" >/dev/null 2>&1
  if [ "$2" != "del" ]; then
    iptables -t mangle -A PREROUTING -i br0 -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK"
    logger -st "($(basename "$0"))" $$ Selective Routing Rule via $TARGET_DESC created "("TAG fwmark $TAG_MARK")"
  else
    logger -st "($(basename "$0"))" $$ Selective Routing Rule via $TARGET_DESC deleted "("TAG fwmark $TAG_MARK")"
  fi
}

#======================== end of functions

Check_Lock "$@"

#======================================================================================Martineau Hack
if [ "$(echo "$@" | grep -c 'dir=')" -gt 0 ]; then
  DIR=$(echo "$@" | sed -n "s/^.*dir=//p" | awk '{print $1}') # v1.2 Mount point/directory for backups
else
  DIR="/opt/tmp" # default location
fi

if [ -n "$1" ]; then
  VPNID=$1
else
  logger -st "($(basename "$0"))" $$ Warning missing arg1 "'destination_target' 0-WAN or 1-5=VPN," WAN assumed!
fi
if [ -n "$2" ]; then
  IPSET_NAME=$2
else
  logger -st "($(basename "$0"))" $$ ERROR missing arg2 "'ipset_name'"
  exit 97
fi

set_fwmark_parms

case $VPNID in
0)
  TAG_MARK=$FWMARK_WAN # Which Target WAN or VPN? Martineau Hack
  TARGET_DESC="WAN"
  ;;
1 | 2 | 3 | 4 | 5)
  eval "TAG_MARK=\$FWMARK_OVPNC"${VPNID}
  TARGET_DESC="VPN Client "$VPNID
  ;;
*)
  logger -st "($(basename "$0"))" $$ ERROR "$1" should be "0-WAN or 1-5=VPN"
  exit 99
  ;;
esac

# Delete mode?
if [ "$(echo "$@" | grep -cw 'del')" -gt 0 ]; then
  Chk_Entware 30
  create_routing_rules "$IPSET_NAME" "del"
  check_MANUAL_ipset_list_exist "$IPSET_NAME" "del"
else
  Chk_Entware 30
  check_MANUAL_ipset_list_exist "$IPSET_NAME"
  check_MANUAL_ipset_list_values "$IPSET_NAME" "$DIR"
  create_routing_rules "$IPSET_NAME"
fi

if [ "$lock_load_MANUAL_ipset_iface" = "true" ]; then rm -rf "/tmp/load_MANUAL_ipset_iface.lock"; fi

logger -t "($(basename "$0"))" $$ Ending Script Execution
