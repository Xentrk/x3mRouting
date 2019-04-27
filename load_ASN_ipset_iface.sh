#!/bin/sh
####################################################################################################
# Script: load_ASN_ipsets_iface.sh
# VERSION=1.0.0
# Author: Xentrk
# Date: 15-March-2019
#
# Description:
#   Selective Routing Script for Hulu
#
# Grateful:
#   Thank you to @Martineau on snbforums.com for sharing his Selective Routing expertise
#   and on-going support!
#
####################################################################################################
# This script will create an IPSET list using the AS Number.  The IPv4 addresses are downloaded
# from https://ipinfo.io/. https://ipinfo.io/ may require whitelisting if you use an ad-blocker
# program.  You must pass the script the name of the IPSET list followed by the AS Number.
#
# Usage example:
#
# Usage: load_ASN_ipset_iface.sh {[0|1|2|3|4|5]} ipset_name ASN [del] [dir='directory']
#
# Usage: load_ASN_ipset_iface.sh 2  NETFLIX  AS2906
#          Create IPSET NETFLIX from AS2906 via VPN Client 2
#
# Usage: load_ASN_ipset_iface.sh 2  NETFLIX  AS2906  dir=/mnt/sda1/Backups
#          As per example one, but use '/mnt/sda1/Backups' rather than Entware's 'opt/tmp' for ipset save/restore
#
# Usage: load_ASN_ipset_iface.sh 2  NETFLIX  del
#          Delete IPSET NETFLIX and remove routing via VPN Client 2
#
####################################################################################################
logger -t "($(basename "$0"))" $$ Starting Script Execution
# Uncomment the line below for debugging
set -x

Kill_Lock() {
  if [ -f "/tmp/load_ASN_ipset.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/load_ASN_ipset.lock)" ]; then
    logger -st "($(basename "$0"))" "[*] Killing Locked Processes ($(sed -n '1p' /tmp/load_ASN_ipset.lock)) (pid=$(sed -n '2p' /tmp/load_ASN_ipset.lock))"
    logger -st "($(basename "$0"))" "[*] $(ps | awk -v pid="$(sed -n '2p' /tmp/load_ASN_ipset.lock)" '$1 == pid')"
    kill "$(sed -n '2p' /tmp/load_ASN_ipset.lock)"
    rm -rf /tmp/load_ASN_ipset.lock
    echo
  fi
}

Check_Lock() {
  if [ -f "/tmp/load_ASN_ipset.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/load_ASN_ipset.lock)" ] && [ "$(sed -n '2p' /tmp/load_ASN_ipset.lock)" != "$$" ]; then
    if [ "$(($(date +%s) - $(sed -n '3p' /tmp/load_ASN_ipset.lock)))" -gt "1800" ]; then
      Kill_Lock
    else
      logger -st "($(basename "$0"))" "[*] Lock File Detected ($(sed -n '1p' /tmp/load_ASN_ipset.lock)) (pid=$(sed -n '2p' /tmp/load_ASN_ipset.lock)) - Exiting (cpid=$$)"
      echo
      exit 1
    fi
  fi
  echo "$@" >/tmp/load_ASN_ipset.lock
  echo "$$" >>/tmp/load_ASN_ipset.lock
  date +%s >>/tmp/load_ASN_ipset.lock
  lock_load_ASN_ipset="true"
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
    ip rule add from 0/0 fwmark "$TAG_MARK" table 113 prio 9993
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

#Download ASN ipset list

download_ASN_ipset_list() {

  IPSET_NAME=$1
  ASN=$2
  NUMBER=$3
  DIR=$4

  curl https://ipinfo.io/"$ASN" 2>/dev/null | grep -E "a href.*$NUMBER\/" | grep -v ":" | sed 's|^.*<a href="/'"$ASN"'/||' | sed 's|" >||' >"$DIR/$IPSET_NAME"

  if [ "$?" = "1" ]; then # file download failed
    logger -t "($(basename "$0"))" $$ Script execution failed because $ASN file could not be downloaded
    exit 1
  fi
}

# Create IPSET lists
# if ipset list does not exist, create it
check_ASN_ipset_list_exist() {

  IPSET_NAME="$1"
  if [ "$2" != "del" ]; then
    if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" != "$IPSET_NAME" ]; then #does ipset list exist?
      ipset create "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536 # No restore file, so create AMAZON ipset list from scratch
      logger -st "($(basename "$0"))" $$ IPSET created: "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536
    fi
  else
    if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" = "$IPSET_NAME" ]; then # del condition is true
      ipset destroy "$IPSET_NAME" && logger -st "($(basename "$0"))" $$ "IPSET $IPSET_NAME deleted!" || logger -st "($(basename "$0"))" $$ Error attempting to delete IPSET "$IPSET_NAME"!
    fi
  fi
}

# if ipset list x3mRouting_HULU is empty or source file is older than 24 hours, download source file; load ipset list

check_ASN_ipset_list_values() {

  IPSET_NAME=$1
  ASN=$2
  NUMBER=$3
  DIR=$4

  if [ "$(ipset -L "$IPSET_NAME" 2>/dev/null | awk '{ if (FNR == 7) print $0 }' | awk '{print $4 }')" -eq "0" ]; then
    if [ ! -s "$DIR/$IPSET_NAME" ] || [ "$(find "$DIR" -name $IPSET_NAME -mtime +1 -print)" = "$DIR/$IPSET_NAME" ]; then
      download_ASN_ipset_list $IPSET_NAME $ASN $NUMBER $DIR
    fi
    awk '{print "add '"$IPSET_NAME"' " $1}' "$DIR/$IPSET_NAME" | ipset restore -!
  else
    if [ ! -s "$DIR/$IPSET_NAME" ]; then
      download_ASN_ipset_list $IPSET_NAME $ASN $NUMBER $DIR
    fi
  fi
}

# Route IPSET to target WAN or VPN
create_routing_rules() {
  IPSET_NAME="$1"
  iptables -t mangle -D PREROUTING -i br0 -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK" >/dev/null 2>&1
  if [ "$2" != "del" ]; then
    iptables -t mangle -A PREROUTING -i br0 -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK"
    logger -st "($(basename "$0"))" $$ Selective Routing Rule via $TARGET_DESC created for $IPSET_NAME "("TAG fwmark $TAG_MARK")"
  else
    logger -st "($(basename "$0"))" $$ Selective Routing Rule via $TARGET_DESC deleted for $IPSET_NAME "("TAG fwmark $TAG_MARK")"
  fi
}

#================================ end of functions

Check_Lock "$@"

#======================================================================================Martineau Hack

if [ "$(echo "$@" | grep -c 'dir=')" -gt 0 ]; then
  DIR=$(echo "$@" | sed -n "s/^.*dir=//p" | awk '{print $1}') # v1.2 Mount point/directory for backups
else
  DIR="/opt/tmp"
fi

VPNID=0
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
if [ -n "$3" ]; then
  ASN="$3"
  NUMBER="$(echo $ASN | sed 's/^AS//')"
else
  logger -st "($(basename "$0"))" $$ ERROR missing arg3 "ASN"
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
  set_ip_rule
  create_routing_rules "$IPSET_NAME" "del"
  check_ASN_ipset_list_exist "$IPSET_NAME" "del"
else
  Chk_Entware 30
  check_ASN_ipset_list_exist "$IPSET_NAME"
  check_ASN_ipset_list_values "$IPSET_NAME" "$ASN" "$NUMBER" "$DIR"
  create_routing_rules "$IPSET_NAME" # Martineau Hack
fi

if [ "$lock_load_ASN_ipset" = "true" ]; then rm -rf "/tmp/load_ASN_ipset.lock"; fi

logger -t "($(basename "$0"))" $$ Ending Script Execution
