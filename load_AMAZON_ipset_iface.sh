#!/bin/sh
####################################################################################################
# Script: load_AMAZON_ipset_iface.sh
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
#####################################################################################################
# Script Description:
#  This script will create an IPSET list called AMAZON containing all IPv4 address for the Amazon
#  AWS US region.  The IPSET list is required to route Amazon Prime traffic.
#
# Requirements:
#  This script requires the entware package 'jq'. To install, enter the command:
#    opkg install jq
#  from an SSH session.
#
# You must specify one of the regions below when creating the IPSET list:
#
# AP - Asia Pacific
# CA - Canada
# CN - China
# EU - European Union
# SA - South America
# US - USA
# GV - USA Government
# GLOBAL - Global
#
# Usage example:
#
# Usage:     load_AMAZON_ipset_iface.sh   {[0|1|2|3|4|5]} ipset_name [US|CA|CN|EU|SA|US|GV|GLOBAL]} [del] [dir='directory']
#
# Usage:     load_AMAZON_ipset_iface.sh   2 AMAZON-US US
#               Create and populate IPSET AMAZON-US from US region and route via VPN Client 2
#
# Usage:     load_AMAZON_ipset_iface.sh   2 AMAZON-US US dir=/mnt/sda1/Backups
#               As per example one, but use '/mnt/sda1/Backups' rather than Entware's 'opt/tmp' for ipset save/restore
#
# Usage:     load_AMAZON_ipset_iface.sh   2 AMAZON-US del
#               Delete IPSET AMAZON-US and remove route via VPN Client 2
#
#####################################################################################################
logger -st "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging
#set -x

Kill_Lock() {

  if [ -f "/tmp/load_AMAZON_ipset_iface.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/load_AMAZON_ipset_iface.lock)" ]; then
    logger -st "($(basename "$0"))" "[*] Killing Locked Processes ($(sed -n '1p' /tmp/load_AMAZON_ipset_iface.lock)) (pid=$(sed -n '2p' /tmp/load_AMAZON_ipset_iface.lock))"
    logger -st "($(basename "$0"))" "[*] $(ps | awk -v pid="$(sed -n '2p' /tmp/load_AMAZON_ipset_iface.lock)" '$1 == pid')"
    kill "$(sed -n '2p' /tmp/load_AMAZON_ipset_iface.lock)"
    rm -rf /tmp/load_AMAZON_ipset_iface.lock
    echo
  fi
}

Check_Lock() {

  if [ -f "/tmp/load_AMAZON_ipset_iface.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/load_AMAZON_ipset_iface.lock)" ] && [ "$(sed -n '2p' /tmp/load_AMAZON_ipset_iface.lock)" != "$$" ]; then
    if [ "$(($(date +%s) - $(sed -n '3p' /tmp/load_AMAZON_ipset_iface.lock)))" -gt "1800" ]; then
      Kill_Lock
    else
      Error_Exit "[*] Lock File Detected ($(sed -n '1p' /tmp/load_AMAZON_ipset_iface.lock)) (pid=$(sed -n '2p' /tmp/load_AMAZON_ipset_iface.lock)) - Exiting (cpid=$$)"
    fi
  fi
  echo "$@" >/tmp/load_AMAZON_ipset_iface.lock
  echo "$$" >>/tmp/load_AMAZON_ipset_iface.lock
  date +%s >>/tmp/load_AMAZON_ipset_iface.lock
  lock_load_AMAZON_ipset_iface="true"
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
      opkg install "$ENTWARE_UTILITY" && READY=0 && logger -st "($(basename "$0"))" $$ "Entware $ENTWARE_UTILITY successfully installed"
    fi

  return $READY
}

# Download Amazon AWS json file
Download_AMAZON() {

  IPSET_NAME="$1"
  REGION="$2"

  wget https://ip-ranges.amazonaws.com/ip-ranges.json -O "$DIR/ip-ranges.json"
  if [ "$?" = "1" ]; then # file download failed
    Error_Exit "Script execution failed because https://ip-ranges.amazonaws.com/ip-ranges.json file could not be downloaded"
  fi
  true >"$DIR/$IPSET_NAME"
#  for REGION in us-east-1 us-east-2 us-west-1 us-west-2; do
# don't quote the parameter so it is treated like an array!
   for REGION in $REGION; do
    jq '.prefixes[] | select(.region=='\"$REGION\"') | .ip_prefix' <"$DIR/ip-ranges.json" | sed 's/"//g' | sort -u >>"$DIR/$IPSET_NAME"
  done
}
# if ipset AMAZON does not exist, create it

Check_Ipset_List_Exist() {

  IPSET_NAME="$1"
  DEL_FLAG="$2"

  if [ "$DEL_FLAG"  != "del" ]; then
      if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" != "$IPSET_NAME" ]; then #does ipset list exist?
        ipset create "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536 # No restore file, so create AMAZON ipset list from scratch
        logger -st "($(basename "$0"))" $$ IPSET created: "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536
      fi
  else
    if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" = "$IPSET_NAME" ]; then # del condition is true
      ipset destroy "$IPSET_NAME" && logger -st "($(basename "$0"))" $$ "IPSET $IPSET_NAME deleted!" || Error_Exit "Error attempting to delete IPSET $IPSET_NAME!"
    fi
  fi
}

# if ipset list AMAZON is empty or source file is older than 7 days, download source file; load ipset list

Check_Ipset_List_Values() {

  IPSET_NAME="$1"
  REGION="$2"

  if [ "$(ipset -L $IPSET_NAME 2>/dev/null | awk '{ if (FNR == 7) print $0 }' | awk '{print $4 }')" -eq "0" ]; then
    if [ ! -s "$DIR/$IPSET_NAME" ] || [ "$(find "$DIR" -name $IPSET_NAME -mtime +7 -print)" = "$DIR/$IPSET_NAME" ]; then
      Download_AMAZON "$IPSET_NAME" "$REGION"
    fi
    awk '{print "add '"$IPSET_NAME"' " $1}' "$DIR/$IPSET_NAME" | ipset restore -!
  else
    if [ ! -s "$DIR/$IPSET_NAME" ]; then
      Download_AMAZON "$IPSET_NAME" "$REGION"
    fi
  fi
}

# Route IPSET to target WAN or VPN
Create_Routing_Rules() {

  IPSET_NAME="$1"
  DEL_FLAG="$2"

  iptables -t mangle -D PREROUTING -i br0 -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK" >/dev/null 2>&1
  if [ "$DEL_FLAG" != "del" ]; then
    iptables -t mangle -A PREROUTING -i br0 -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK"
    logger -st "($(basename "$0"))" $$ Selective Routing Rule via $TARGET_DESC created for "$IPSET_NAME" "("TAG fwmark $TAG_MARK")"
  else
    logger -st "($(basename "$0"))" $$ Selective Routing Rule via $TARGET_DESC deleted for "$IPSET_NAME" "("TAG fwmark $TAG_MARK")"
  fi
}

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
    Error_Exit "ERROR $1 should be 0-WAN or 1-5=VPN"
    ;;
  esac
}

Unlock_Script() {

  if [ "$lock_load_AMAZON_ipset_iface" = "true" ]; then
    rm -rf "/tmp/load_AMAZON_ipset_iface.lock"
  fi
}

Error_Exit() {

    error_str="$@"
    logger -st "($(basename "$0"))" $$ "$error_str"
    Unlock_Script
    exit 1
}

# Call functions below this line
Check_Lock "$@"

if [ "$(echo "$@" | grep -c 'dir=')" -gt 0 ]; then
  DIR=$(echo "$@" | sed -n "s/^.*dir=//p" | awk '{print $1}') # v1.2 Mount point/directory for backups
else
  DIR="/opt/tmp"
fi

if [ -n "$1" ]; then
  VPNID=$1
else
  VPNID=0
  logger -st "($(basename "$0"))" $$ "Warning missing arg1 'destination_target' 0-WAN or 1-5=VPN, WAN assumed!"
fi

if [ -n "$2" ]; then
  IPSET_NAME=$2
else
  Error_Exit "ERROR missing arg2 'ipset_name'"
fi

if [ -n "$3" ]; then
  if [ "$(echo "$@" | grep -cw 'del')" -eq 0 ]; then
    REGION="$3"
    case "$REGION" in
    AP)
      REGION="ap-east-1 ap-northeast-1 ap-northeast-2 ap-northeast-3 ap-south-1 ap-southeast-1 ap-southeast-2"
      break
      ;;
    CA)
      REGION="ca-central-1"
      break
      ;;
    CN)
      REGION="cn-north-1 cn-northwest-1"
      break
      ;;
    EU)
      REGION="eu-central-1 eu-north-1 eu-west-1 eu-west-2 eu-west-3"
      break
      ;;
    SA)
      REGION="sa-east-1"
      break
      ;;
    US)
      REGION="us-east-1 us-east-2 us-west-1 us-west-2"
      break
      ;;
    GV)
      REGION="us-gov-east-1 us-gov-west-1"
      break
      ;;
    GLOBAL)
      REGION="GLOBAL"
      break
      ;;
    *)
      Error_Exit "Invalid AMAZON region specified: $REGION. Valid values are: AP CA CN EU SA US GV GLOBAL"
      ;;
    esac
  fi
else
  Error_Exit "ERROR missing arg2 'Region'"
fi


Set_Fwmark_Parms

case "$VPNID" in
0)
  TAG_MARK="$FWMARK_WAN" # Which Target WAN or VPN? Martineau Hack
  TARGET_DESC="WAN"
  ;;
1 | 2 | 3 | 4 | 5)
  eval "TAG_MARK=\$FWMARK_OVPNC"${VPNID}
  TARGET_DESC="VPN Client "$VPNID
  ;;
*)
  Error_Exit "ERROR $1 should be 0-WAN or 1-5=VPN"
  ;;
esac

# Delete mode?
if [ "$(echo "$@" | grep -cw 'del')" -gt 0 ]; then
  Create_Routing_Rules "$IPSET_NAME" "del"
  Check_Ipset_List_Exist "$IPSET_NAME" "del"
else
  Chk_Entware jq 60
  if [ "$READY" -eq 1 ]; then Error_Exit "Required entware package 'jq' not installed"; fi
  Set_IP_Rule "$VPNID"
  Check_Ipset_List_Exist "$IPSET_NAME"
  Check_Ipset_List_Values "$IPSET_NAME" "$REGION"
  Create_Routing_Rules "$IPSET_NAME"
fi
#==================================================================================================

Unlock_Script

logger -st "($(basename "$0"))" $$ Completed Script Execution
