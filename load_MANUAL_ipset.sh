#!/bin/sh
####################################################################################################
# Script: load_MANUAL_ipset.sh
# VERSION=1.0.0
# Author: Xentrk, Martineau
# Date: 28-April-2019
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
# Script Description:
#
# This script will create an IPSET list from a file containing IPv4 addresses stored in the
# /opt/tmp directory on entware.  For example, I mined the domain names fom dnsmasq for BBC
# and converted the domain names to their respective IPv4 addresses and saved to a file.  
# The IPSET list name must match the name of the file containing the IPv4 addresses stored in /opt/tmp.
#
# Usage example:
#
# Usage:     load_MANUAL_ipset.sh   ipset_name [del]  [dir='directory']
#
# Usage:     load_MANUAL_ipset.sh   BBC
#               Create IPSET BBC
# Usage:     load_MANUAL_ipset.sh   BBC  del
#               Delete IPSET BBC
# Usage:     load_MANUAL_ipset.sh   BBC   dir=/mnt/sda1/Backups
#               As per example one, but use '/mnt/sda1/Backups' rather than Entware's 'opt/tmp' for ipset save/restore location
# Usage:     load_MANUAL_ipset.sh   BBC   del dir=/mnt/sda1/Backups
#               As per example two, but use '/mnt/sda1/Backups' rather than Entware's 'opt/tmp' for ipset save/restore location
####################################################################################################
logger -t "($(basename "$0"))" $$ Starting Script Execution
# Uncomment the line below for debugging
#set -x

Kill_Lock() {

  if [ -f "/tmp/load_MANUAL_ipset.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/load_MANUAL_ipset.lock)" ]; then
    logger -st "($(basename "$0"))" "[*] Killing Locked Processes ($(sed -n '1p' /tmp/load_MANUAL_ipset.lock)) (pid=$(sed -n '2p' /tmp/load_MANUAL_ipset.lock))"
    logger -st "($(basename "$0"))" "[*] $(ps | awk -v pid="$(sed -n '2p' /tmp/load_MANUAL_ipset.lock)" '$1 == pid')"
    kill "$(sed -n '2p' /tmp/load_MANUAL_ipset.lock)"
    rm -rf /tmp/load_MANUAL_ipset.lock
    echo
  fi
}

Check_Lock() {

  if [ -f "/tmp/load_MANUAL_ipset.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/load_MANUAL_ipset.lock)" ] && [ "$(sed -n '2p' /tmp/load_MANUAL_ipset.lock)" != "$$" ]; then
    if [ "$(($(date +%s) - $(sed -n '3p' /tmp/load_MANUAL_ipset.lock)))" -gt "1800" ]; then
      Kill_Lock
    else
      logger -st "($(basename "$0"))" "[*] Lock File Detected ($(sed -n '1p' /tmp/load_MANUAL_ipset.lock)) (pid=$(sed -n '2p' /tmp/load_MANUAL_ipset.lock)) - Exiting (cpid=$$)"
      echo
      exit 1
    fi
  fi
  echo "$@" >/tmp/load_MANUAL_ipset.lock
  echo "$$" >>/tmp/load_MANUAL_ipset.lock
  date +%s >>/tmp/load_MANUAL_ipset.lock
  lock_load_MANUAL_ipset="true"
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

# Create IPSET lists if it doesn not exist

Check_MANUAL_Ipset_List_Exist() {

  IPSET_NAME=$1

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

# if ipset list is empty or source file is older than 24 hours, download source file; load ipset list
Check_MANUAL_Ipset_List_Values() {

  IPSET_NAME=$1
  DIR=$2

  if [ "$(ipset -L "$IPSET_NAME" 2>/dev/null | awk '{ if (FNR == 7) print $0 }' | awk '{print $4 }')" -eq "0" ]; then
    awk '{print "add '"$IPSET_NAME"' " $1}' "$DIR/$IPSET_NAME" | ipset restore -!
  fi
}

# Route IPSET to target WAN or VPN
create_routing_rules() {

  iptables -t mangle -D PREROUTING -i br0 -m set --match-set $1 dst -j MARK --set-mark "$TAG_MARK" >/dev/null 2>&1
  if [ "$2" != "del" ]; then
    iptables -t mangle -A PREROUTING -i br0 -m set --match-set $1 dst -j MARK --set-mark "$TAG_MARK"
    logger -st "($(basename "$0"))" $$ Selective Routing Rule via $TARGET_DESC created "("TAG fwmark $TAG_MARK")"
  else
    logger -st "($(basename "$0"))" $$ Selective Routing Rule via $TARGET_DESC deleted "("TAG fwmark $TAG_MARK")"
  fi
}

Unlock_Script() {

  if [ "$lock_load_MANUAL_ipset" = "true" ]; then 
    rm -rf "/tmp/load_MANUAL_ipset.lock"; 
  fi
}

Error_Exit() {

    error_str="$@"
    logger -t "($(basename "$0"))" $$ "$error_str"
    Unlock_Script
    exit 1
}

#======================== end of functions

Check_Lock "$@"

#======================================================================================Martineau Hack
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

# Delete mode?
if [ "$(echo "$@" | grep -cw 'del')" -gt 0 ]; then
  Chk_Entware 30
  Check_MANUAL_Ipset_List_Exist "$IPSET_NAME" "del"
else
  Chk_Entware 30
  if [ "$READY" -eq 1 ]; then Error_Exit "Entware not ready. Unable to access ipset save/restore location"; fi
  Check_MANUAL_Ipset_List_Exist "$IPSET_NAME"
  Check_MANUAL_Ipset_List_Values "$IPSET_NAME" "$DIR"
fi

Unlock_Script

logger -t "($(basename "$0"))" $$ Ending Script Execution
