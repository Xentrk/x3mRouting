#!/bin/sh
####################################################################################################
# Script: load_ASN_ipsets_iface.sh
# VERSION=1.0.0
# Authors: Xentrk, Martineau
# Date: 6-May-2019
#
# Grateful:
#   Thank you to @Martineau on snbforums.com for sharing his Selective Routing expertise,
#   on-going support and collaboration on this project!
#
#   Chk_Entware function and code to process the passing of parms written by Martineau
#
#   Kill_Lock, Check_Lock and Unlock_Script functions provided by Adamm https://github.com/Adamm00
# 
####################################################################################################
# This script will create an IPSET list using the AS Number.  The IPv4 addresses are downloaded
# from https://ipinfo.io/. https://ipinfo.io/ may require whitelisting if you use an ad-blocker
# program.  You must pass the script the name of the IPSET list followed by the AS Number.
#
# Usage example:
#
# Usage: load_ASN_ipset_iface.sh {[0|1|2|3|4|5] ipset_name ASN} [del] [dir='directory']
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
#set -x

Kill_Lock() {

  if [ -f "/tmp/load_ASN_ipset_iface.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/load_ASN_ipset_iface.lock)" ]; then
    logger -t "($(basename "$0"))" "[*] Killing Locked Processes ($(sed -n '1p' /tmp/load_ASN_ipset_iface.lock)) (pid=$(sed -n '2p' /tmp/load_ASN_ipset_iface.lock))"
    logger -t "($(basename "$0"))" "[*] $(ps | awk -v pid="$(sed -n '2p' /tmp/load_ASN_ipset_iface.lock)" '$1 == pid')"
    kill "$(sed -n '2p' /tmp/load_ASN_ipset_iface.lock)"
    rm -rf /tmp/load_ASN_ipset_iface.lock
    echo
  fi
}

Check_Lock() {

  if [ -f "/tmp/load_ASN_ipset_iface.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/load_ASN_ipset_iface.lock)" ] && [ "$(sed -n '2p' /tmp/load_ASN_ipset_iface.lock)" != "$$" ]; then
    if [ "$(($(date +%s) - $(sed -n '3p' /tmp/load_ASN_ipset_iface.lock)))" -gt "1800" ]; then
      Kill_Lock
    else
      logger -t "($(basename "$0"))" "[*] Lock File Detected ($(sed -n '1p' /tmp/load_ASN_ipset_iface.lock)) (pid=$(sed -n '2p' /tmp/load_ASN_ipset_iface.lock)) - Exiting (cpid=$$)"
      echo
      exit 1
    fi
  fi
  echo "$@" >/tmp/load_ASN_ipset_iface.lock
  echo "$$" >>/tmp/load_ASN_ipset_iface.lock
  date +%s >>/tmp/load_ASN_ipset_iface.lock
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
    logger -t "($(basename "$0"))" $$ "Entware" "$ENTWARE_UTILITY" "not available - wait time" $((MAX_TRIES - TRIES - 1))" secs left"
    TRIES=$((TRIES + 1))
  done

  return $READY
}

### Define interface/bitmask to route traffic to below
Set_Fwmark_Parms() {

  FWMARK_WAN="0x8000/0x8000"
  FWMARK_OVPNC1="0x1000/0x1000"
  FWMARK_OVPNC2="0x2000/0x2000"
  FWMARK_OVPNC3="0x4000/0x4000"
  FWMARK_OVPNC4="0x7000/0x7000"
  FWMARK_OVPNC5="0x3000/0x3000"
}

Set_IP_Rule() {

  VPNID=$1

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
    Error_Exit "ERROR $VPNID" should be "0-WAN or 1-5=VPN"
    ;;
  esac
}

#Download ASN ipset list

Download_ASN_Ipset_List() {

  IPSET_NAME=$1
  ASN=$2
  NUMBER=$3
  DIR=$4

  curl https://ipinfo.io/"$ASN" 2>/dev/null | grep -E "a href.*$NUMBER\/" | grep -v ":" | sed 's|^.*<a href="/'"$ASN"'/||' | sed 's|" >||' >"$DIR/$IPSET_NAME"

  if [ "$?" = "1" ]; then # file download failed
    Error_Exit "Script execution failed because $ASN file could not be downloaded"
  fi
}

# Create IPSET lists
# if ipset list does not exist, create it
Check_ASN_Ipset_List_Exist() {

  IPSET_NAME="$1"
  
  if [ "$2" != "del" ]; then
    if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" != "$IPSET_NAME" ]; then #does ipset list exist?
      ipset create "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536 # No restore file, so create AMAZON ipset list from scratch
      logger -t "($(basename "$0"))" $$ IPSET created: "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536
    fi
  else
    if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" = "$IPSET_NAME" ]; then # del condition is true
      ipset destroy "$IPSET_NAME" && logger -t "($(basename "$0"))" $$ "IPSET $IPSET_NAME deleted!" || $$ "IPSET $IPSET_NAME deleted!" || Error_Exit "Error attempting to delete IPSET $IPSET_NAME!"
    fi
  fi
}

# if ipset list x3mRouting_HULU is empty or source file is older than 24 hours, download source file; load ipset list

Check_ASN_Ipset_List_Values() {

  IPSET_NAME=$1
  ASN=$2
  NUMBER=$3
  DIR=$4

  if [ "$(ipset -L "$IPSET_NAME" 2>/dev/null | awk '{ if (FNR == 7) print $0 }' | awk '{print $4 }')" -eq "0" ]; then
    if [ ! -s "$DIR/$IPSET_NAME" ] || [ "$(find "$DIR" -name $IPSET_NAME -mtime +1 -print)" = "$DIR/$IPSET_NAME" ]; then
      Download_ASN_Ipset_List $IPSET_NAME $ASN $NUMBER $DIR
    fi
    awk '{print "add '"$IPSET_NAME"' " $1}' "$DIR/$IPSET_NAME" | ipset restore -!
  else
    if [ ! -s "$DIR/$IPSET_NAME" ]; then
      Download_ASN_Ipset_List $IPSET_NAME $ASN $NUMBER $DIR
    fi
  fi
}

# Route IPSET to target WAN or VPN
Create_Routing_Rules() {

  IPSET_NAME="$1"
  iptables -t mangle -D PREROUTING -i br0 -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK" >/dev/null 2>&1
  if [ "$2" != "del" ]; then
    iptables -t mangle -A PREROUTING -i br0 -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK"
    logger -t "($(basename "$0"))" $$ Selective Routing Rule via $TARGET_DESC created for $IPSET_NAME "("TAG fwmark $TAG_MARK")"
  else
    logger -t "($(basename "$0"))" $$ Selective Routing Rule via $TARGET_DESC deleted for $IPSET_NAME "("TAG fwmark $TAG_MARK")"
  fi
}

Unlock_Script() {

  if [ "$lock_load_ASN_ipset" = "true" ]; then 
    rm -rf "/tmp/load_ASN_ipset_iface.lock"
  fi
}

Error_Exit() {

    error_str="$@"
    logger -t "($(basename "$0"))" $$ "$error_str"
    Unlock_Script
    exit 1
}

#================================ End of Functions

Check_Lock "$@"

if [ "$(echo "$@" | grep -c 'dir=')" -gt 0 ]; then
  DIR=$(echo "$@" | sed -n "s/^.*dir=//p" | awk '{print $1}') # v1.2 Mount point/directory for backups
else
  DIR="/opt/tmp"
fi

VPNID=0
if [ -n "$1" ]; then
  VPNID=$1
else
  VPNID=0
  logger -t "($(basename "$0"))" "WARNING missing arg1 'destination_target' 0-WAN or 1-5=VPN, WAN assumed!"
fi

if [ -n "$2" ]; then
  IPSET_NAME=$2
else
   Error_Exit "ERROR missing arg2 'ipset_name'"
fi

if [ -n "$3" ]; then
  ASN="$3"
  NUMBER="$(echo $ASN | sed 's/^AS//')"
else
  Error_Exit "ERROR missing arg3 'ASN'"
fi

Set_Fwmark_Parms

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
  Error_Exit "ERROR $VPNID" should be "0-WAN or 1-5=VPN"
  ;;
esac

# Delete mode?
if [ "$(echo "$@" | grep -cw 'del')" -gt 0 ]; then
  Create_Routing_Rules "$IPSET_NAME" "del"
  Check_ASN_Ipset_List_Exist "$IPSET_NAME" "del"
else
  Chk_Entware 30
  if [ "$READY" -eq 1 ]; then Error_Exit "Entware not ready. Unable to access ipset save/restore location"; fi
  Set_IP_Rule "$VPN_ID"
  Check_ASN_Ipset_List_Exist "$IPSET_NAME"
  Check_ASN_Ipset_List_Values "$IPSET_NAME" "$ASN" "$NUMBER" "$DIR"
  Create_Routing_Rules "$IPSET_NAME" # Martineau Hack
fi

Unlock_Script

logger -t "($(basename "$0"))" $$ Ending Script Execution
