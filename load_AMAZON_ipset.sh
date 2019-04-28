#!/bin/sh
####################################################################################################
# Script: load_AMAZON_ipset.sh
# VERSION=1.0.0
# Authors: Xentrk, Martineau
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
#  This script will create an IPSET list called AMAZON containing all IPv4 address for the Amazon
#  AWS US region.  The IPSET list is required to route Amazon Prime traffic.  
#
# Requirements:
#  This script requires the entware package 'jq'. To install, enter the command:
#    opkg install jq
#  from an SSH session.
#
# Usage example:
#
# Usage:     load_AMAZON_ipset.sh   [del] [dir='directory']
#
# Usage:     load_AMAZON_ipset.sh   
#               Create and populate IPSET AMAZON
#
# Usage:     load_AMAZON_ipset.sh   dir=/mnt/sda1/Backups
#               As per example one, but use '/mnt/sda1/Backups' rather than Entware's 'opt/tmp' for ipset save/restore directory
#
# Usage:     load_AMAZON_ipset.sh   del
#               Delete IPSET AMAZON
#
#####################################################################################################
logger -t "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging
set -x

Kill_Lock() {

  if [ -f "/tmp/load_AMAZON_ipset.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/load_AMAZON_ipset.lock)" ]; then
    logger -st "($(basename "$0"))" "[*] Killing Locked Processes ($(sed -n '1p' /tmp/load_AMAZON_ipset.lock)) (pid=$(sed -n '2p' /tmp/load_AMAZON_ipset.lock))"
    logger -st "($(basename "$0"))" "[*] $(ps | awk -v pid="$(sed -n '2p' /tmp/load_AMAZON_ipset.lock)" '$1 == pid')"
    kill "$(sed -n '2p' /tmp/load_AMAZON_ipset.lock)"
    rm -rf /tmp/load_AMAZON_ipset.lock
    echo
  fi
}

Check_Lock() {

  if [ -f "/tmp/load_AMAZON_ipset.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/load_AMAZON_ipset.lock)" ] && [ "$(sed -n '2p' /tmp/load_AMAZON_ipset.lock)" != "$$" ]; then
    if [ "$(($(date +%s) - $(sed -n '3p' /tmp/load_AMAZON_ipset.lock)))" -gt "1800" ]; then
      Kill_Lock
    else
      logger -st "($(basename "$0"))" "[*] Lock File Detected ($(sed -n '1p' /tmp/load_AMAZON_ipset.lock)) (pid=$(sed -n '2p' /tmp/load_AMAZON_ipset.lock)) - Exiting (cpid=$$)"
      echo
      exit 1
    fi
  fi
  echo "$@" >/tmp/load_AMAZON_ipset.lock
  echo "$$" >>/tmp/load_AMAZON_ipset.lock
  date +%s >>/tmp/load_AMAZON_ipset.lock
  lock_load_AMAZON_ipset="true"
}

# Chk_Entware function provided by @Martineau at snbforums.com
Chk_Entware() {

  # ARGS [wait attempts] [specific_entware_utility]

  READY=1 # Assume Entware Utilities are NOT available
  ENTWARE="opkg"
  ENTWARE_UTILITY= # Specific Entware utility to search for
  MAX_TRIES=30

  if [ -n "$2" ] && [ -n "$(echo "$2" | grep -E '^[0-9]+$')" ]; then
    MAX_TRIES=$2
  fi

  if [ -n "$1" ] && [ -z "$(echo "$1" | grep -E '^[0-9]+$')" ]; then
    ENTWARE_UTILITY=$1
  else
    if [ -z "$2" ] && [ -n "$(echo "$1" | grep -E '^[0-9]+$')" ]; then
      MAX_TRIES=$1
    fi
  fi

  # Wait up to (default) 30 seconds to see if Entware utilities available.....
  TRIES=0

  while [ "$TRIES" -lt "$MAX_TRIES" ]; do
    if [ -n "$(which $ENTWARE)" ] && [ "$($ENTWARE -v | grep -o "version")" = "version" ]; then
      if [ -n "$ENTWARE_UTILITY" ]; then # Specific Entware utility installed?
        if [ -n "$("$ENTWARE" list-installed "$ENTWARE_UTILITY")" ]; then
          READY=0 # Specific Entware utility found
        else
          # Not all Entware utilities exists as a stand-alone package e.g. 'find' is in package 'findutils'
          if [ -d /opt ] && [ -n "$(find /opt/ -name "$ENTWARE_UTILITY")" ]; then
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
  # Attempt  to install missing package if not found
    if [ "$READY" -eq 1 ]; then
      opkg install "$ENTWARE_UTILITY" && READY=0 && echo "entware package $ENTWARE_UTILITY installed"
    fi
  
  return $READY
}


# Download Amazon AWS json file
Download_AMAZON() {

  wget https://ip-ranges.amazonaws.com/ip-ranges.json -O "$DIR/ip-ranges.json"
  if [ "$?" = "1" ]; then # file download failed
    logger -t "($(basename "$0"))" $$ Script execution failed because https://ip-ranges.amazonaws.com/ip-ranges.json file could not be downloaded
    exit 1
  fi
  true >"$DIR/AMAZON"
  for REGION in us-east-1 us-east-2 us-west-1 us-west-2; do
    jq '.prefixes[] | select(.region=='\"$REGION\"') | .ip_prefix' <"$DIR/ip-ranges.json" | sed 's/"//g' | sort -u >>"$DIR/AMAZON"
  done
}

# if ipset AMAZON does not exist, create it

Check_Ipset_List_Exist_AMAZON() {
  
  IPSET_NAME="$1"
  
  if [ "$2" != "del" ]; then
      if [ "$(ipset list -n $IPSET_NAME 2>/dev/null)" != "$IPSET_NAME" ]; then #does ipset list exist?
        ipset create "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536 # No restore file, so create AMAZON ipset list from scratch
        logger -st "($(basename "$0"))" $$ IPSET created: "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536
      fi
  else
    if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" = "$IPSET_NAME" ]; then # del condition is true
      ipset destroy "$IPSET_NAME" && logger -st "($(basename "$0"))" $$ "IPSET $IPSET_NAME deleted!" || logger -st "($(basename "$0"))" $$ Error attempting to delete IPSET "$IPSET_NAME"!
    fi
  fi
}

# if ipset list AMAZON is empty or source file is older than 7 days, download source file; load ipset list

Check_Ipset_List_Values_AMAZON() {
  IPSET_NAME="$1"
  if [ "$(ipset -L $IPSET_NAME 2>/dev/null | awk '{ if (FNR == 7) print $0 }' | awk '{print $4 }')" -eq "0" ]; then
    if [ ! -s "$DIR/$IPSET_NAME" ] || [ "$(find "$DIR" -name $IPSET_NAME -mtime +7 -print)" = "$DIR/$IPSET_NAME" ]; then
      Download_AMAZON
    fi
    awk '{print "add '"$IPSET_NAME"' " $1}' "$DIR/$IPSET_NAME" | ipset restore -!
  else
    if [ ! -s "$DIR/$IPSET_NAME" ]; then
      Download_AMAZON
    fi
  fi
}

Unlock_Script() {
  if [ "$lock_load_AMAZON_ipset" = "true" ]; then 
    rm -rf "/tmp/load_AMAZON_ipset.lock"
  fi
}

Error_Exit() {
    error_str="$@"
    logger -t "($(basename "$0"))" $$ "$error_str"
    Unlock_Script
    exit 1
}

# Call functions below this line
Check_Lock "$@"

#======================================================================================Martineau Hack

if [ "$(echo "$@" | grep -c 'dir=')" -gt 0 ]; then
  DIR=$(echo "$@" | sed -n "s/^.*dir=//p" | awk '{print $1}') # v1.2 Mount point/directory for backups
else
  DIR="/opt/tmp"
fi

#============================================================================= End of Martineau Hacks

# Delete mode?
if [ "$(echo "$@" | grep -cw 'del')" -gt 0 ]; then
  Check_Ipset_List_Exist_AMAZON "AMAZON" "del"
else
  Chk_Entware jq 30
  if [ "$READY" -eq 1 ]; then Error_Exit "Required entware package 'jq' not installed"; fi
  Check_Ipset_List_Exist_AMAZON "AMAZON"
  Check_Ipset_List_Values_AMAZON "AMAZON"
fi
#==================================================================================================

Unlock_Script

logger -t "($(basename "$0"))" $$ Completed Script Execution
