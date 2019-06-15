#!/bin/sh
####################################################################################################
# Script: load_ASN_ipsets_iface.sh
# VERSION=1.0.0
# Authors: Xentrk, Martineau
# Date: 15-June-2019
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
# Usage: load_ASN_ipset_iface.sh {ipset_name ASN} [del] [dir='directory']
#
# Usage: load_ASN_ipset_iface.sh NETFLIX  AS2906
#          Create IPSET NETFLIX from AS2906
#
# Usage: load_ASN_ipset_iface.sh NETFLIX  AS2906  dir=/mnt/sda1/Backups
#          As per example one, but use '/mnt/sda1/Backups' rather than Entware's 'opt/tmp' for ipset save/restore directory
#
# Usage: load_ASN_ipset_iface.sh NETFLIX  del
#          Delete IPSET NETFLIX
#
####################################################################################################
logger -st "($(basename "$0"))" $$ Starting Script Execution
# Uncomment the line below for debugging
#set -x

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
  ENTWARE_UTILITY= # Specific Entware utility to search for
  MAX_TRIES=30

  if [ -n "$2" ] && [ "$2" -eq "$2" ] 2>/dev/null; then
    MAX_TRIES="$2"
  elif [ -z "$2" ] && [ "$1" -eq "$1" ] 2>/dev/null; then
    MAX_TRIES="$1"
  fi

  if [ -n "$1" ] && ! [ "$1" -eq "$1" ] 2>/dev/null; then
    ENTWARE_UTILITY="$1"
  fi

  # Wait up to (default) 30 seconds to see if Entware utilities available.....
  TRIES="0"

  while [ "$TRIES" -lt "$MAX_TRIES" ]; do
    if [ -f "/opt/bin/opkg" ]; then
      if [ -n "$ENTWARE_UTILITY" ]; then            # Specific Entware utility installed?
        if [ -n "$(opkg list-installed "$ENTWARE_UTILITY")" ]; then
          READY="0"                                 # Specific Entware utility found
        else
          # Not all Entware utilities exists as a stand-alone package e.g. 'find' is in package 'findutils'
          if [ -d /opt ] && [ -n "$(find /opt/ -name "$ENTWARE_UTILITY")" ]; then
            READY="0"                               # Specific Entware utility found
          fi
        fi
      else
        READY="0"                                     # Entware utilities ready
      fi
      break
    fi
    sleep 1
    logger -st "($(basename "$0"))" "$$ Entware $ENTWARE_UTILITY not available - wait time $((MAX_TRIES - TRIES-1)) secs left"
    TRIES=$((TRIES + 1))
  done
  return "$READY"
}

#Download ASN ipset list

Downlad_ASN_Ipset_List() {

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
      logger -st "($(basename "$0"))" $$ IPSET created: "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536
    fi
  else
    if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" = "$IPSET_NAME" ]; then # del condition is true
      if [ "$(ipset destroy "$IPSET_NAME")" ]
        then
            logger -st "($(basename "$0"))" $$ "IPSET $IPSET_NAME deleted!"
        else
            Error_Exit "Error attempting to delete IPSET $IPSET_NAME!"
      fi
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
    if [ ! -s "$DIR/$IPSET_NAME" ] || [ "$(find "$DIR" -name "$IPSET_NAME" -mtime +1 -print)" = "$DIR/$IPSET_NAME" ]; then
      Downlad_ASN_Ipset_List "$IPSET_NAME" "$ASN" "$NUMBER" "$DIR"
    fi
    awk '{print "add '"$IPSET_NAME"' " $1}' "$DIR/$IPSET_NAME" | ipset restore -!
  else
    if [ ! -s "$DIR/$IPSET_NAME" ]; then
      Download_ASN_Ipset_List "$IPSET_NAME" "$ASN" "$NUMBER" "$DIR"
    fi
  fi
}

# Route IPSET to target WAN or VPN
create_routing_rules() {
  IPSET_NAME="$1"
  iptables -t mangle -D PREROUTING -i br0 -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK" >/dev/null 2>&1
  if [ "$2" != "del" ]; then
    iptables -t mangle -A PREROUTING -i br0 -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK"
    logger -st "($(basename "$0"))" $$ Selective Routing Rule via "$TARGET_DESC" created for "$IPSET_NAME" TAG fwmark "$TAG_MARK"
  else
    logger -st "($(basename "$0"))" $$ Selective Routing Rule via "$TARGET_DESC" deleted for "$IPSET_NAME" TAG fwmark "$TAG_MARK"
  fi
}

Unlock_Script() {

  if [ "$lock_load_ASN_ipset" = "true" ]; then
    rm -rf "/tmp/load_ASN_ipset.lock"
  fi
}

Error_Exit() {

    error_str="$*"
    logger -st "($(basename "$0"))" $$ "$error_str"
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

if [ -n "$1" ]; then
  IPSET_NAME=$1
else
  Error_Exit "ERROR missing arg1 'ipset_name'"
fi

if [ -n "$2" ]; then
  ASN="$2"
  NUMBER="$(echo "$ASN" | sed 's/^AS//')"
else
  Error_Exit "ERROR missing arg2 'ASN'"
fi

# Delete mode?
if [ "$(echo "$@" | grep -cw 'del')" -gt 0 ]; then
  Check_ASN_Ipset_List_Exist "$IPSET_NAME" "del"
else
  Chk_Entware 60
  if [ "$READY" -eq 1 ]; then Error_Exit "Entware not ready. Unable to access ipset save/restore location"; fi
  Check_ASN_Ipset_List_Exist "$IPSET_NAME"
  Check_ASN_Ipset_List_Values "$IPSET_NAME" "$ASN" "$NUMBER" "$DIR"
fi

Unlock_Script

logger -st "($(basename "$0"))" $$ Ending Script Execution
