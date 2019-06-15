#!/bin/sh
####################################################################################################
# Script: load_DNSMASQ_ipset.sh
# VERSION=1.0.0
# Author: Martineau, Xentrk
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
# Script Description:
#
# This script will create an IPSET list using the ipset feature inside of dnsmasq to collect IPv4
# addresses when the domain is looked up by dnsmasq.  The script will also create a cron job to
# backup the list every 24 hours to the /opt/tmp directory so the IPSET list can be restored on
# system boot.  Pass the script the name of the IPSET list followed by the domain names separated
# by a comma.
#
# Usage example:
#
# Usage:     load_DNSMASQ_ipset.sh   {ipset_name  domains[,...]} ['autoscan'] [del]  [dir='directory']
#
# Usage:     load_DNSMASQ_ipset.sh   BBC   bbc.co.uk
#               Create IPSET BBC via VPN Client 2 and autopopulate IPs for domain 'bbc.co.uk'
# Usage:     load_DNSMASQ_ipset.sh   BBC   bbc.co.uk   del
#               Delete IPSET BBC and remove from VPN Client 2
# Usage:     load_DNSMASQ_ipset.sh   BBC   bbc.co.uk   dir=/mnt/sda1/Backups
#               As per example one, but use '/mnt/sda1/Backups' rather than Entware's 'opt/tmp' for ipset save/restore
# Usage:     load_DNSMASQ_ipset.sh   NETFLIX   amazonaws.com,netflix.com,nflxext.com,nflximg.net,nflxso.net,nflxvideo.net
#               Create IPSET NETFLIX via WAN and autopopulate IPs for multiple Netflix domains
# Usage:     load_DNSMASQ_ipset.sh   SKY sky.com autoscan
#               Create IPSET SKY and extract all matching Top-Level domains containing 'sky.com' from
#               '/opt/var/log/dnsmasq.log'
#               e.g. ipset=/akadns.net/edgekey.net/edgesuite.net/epgsky.com/sky.com/SKY
#               from 'a674.hsar.cdn.sky.com.edgesuite.net/adm.sky.com/assets.sky.com/assets.sky.com-secure.edgekey.net/awk.epgsky.com' etc...
####################################################################################################
logger -st "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging
#set -x

Kill_Lock() {

  if [ -f "/tmp/load_DNSMASQ_ipset.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/load_DNSMASQ_ipset.lock)" ]; then
    logger -st "($(basename "$0"))" "[*] Killing Locked Processes ($(sed -n '1p' /tmp/load_DNSMASQ_ipset.lock)) (pid=$(sed -n '2p' /tmp/load_DNSMASQ_ipset.lock))"
    logger -st "($(basename "$0"))" "[*] $(ps | awk -v pid="$(sed -n '2p' /tmp/load_DNSMASQ_ipset.lock)" '$1 == pid')"
    kill "$(sed -n '2p' /tmp/load_DNSMASQ_ipset.lock)"
    rm -rf /tmp/load_DNSMASQ_ipset.lock
    echo
  fi
}

Check_Lock() {

  if [ -f "/tmp/load_DNSMASQ_ipset.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/load_DNSMASQ_ipset.lock)" ] && [ "$(sed -n '2p' /tmp/load_DNSMASQ_ipset.lock)" != "$$" ]; then
    if [ "$(($(date +%s) - $(sed -n '3p' /tmp/load_DNSMASQ_ipset.lock)))" -gt "1800" ]; then
      Kill_Lock
    else
      logger -st "($(basename "$0"))" "[*] Lock File Detected ($(sed -n '1p' /tmp/load_DNSMASQ_ipset.lock)) (pid=$(sed -n '2p' /tmp/load_DNSMASQ_ipset.lock)) - Exiting (cpid=$$)"
      echo
      exit 1
    fi
  fi
  echo "$@" >/tmp/load_DNSMASQ_ipset.lock
  echo "$$" >>/tmp/load_DNSMASQ_ipset.lock
  date +%s >>/tmp/load_DNSMASQ_ipset.lock
  lock_load_DNSMASQ_ipset="true"
}

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

# check if /jffs/configs/dnsmasq.conf.add contains 'ipset=' entry for the domains
Check_Dnsmasq() {

  DNSMASQ_ENTRY="$1"

  if [ -s /jffs/configs/dnsmasq.conf.add ]; then # dnsmasq.conf.add file exists
    if [ "$(grep -c "$DNSMASQ_ENTRY" "/jffs/configs/dnsmasq.conf.add")" -ge "1" ]; then # if true, then one or more lines exist in dnsmasq.conf.add
      if [ "$2" = "del" ]; then
        sed -i "/^ipset.*${IPSET_NAME}$/d" /jffs/configs/dnsmasq.conf.add
        logger -st "($(basename "$0"))" $$ ipset="$DNSMASQ_ENTRY" entry deleted from "'/jffs/configs/dnsmasq.conf.add'"
      fi
    else
      echo "ipset=$DNSMASQ_ENTRY" >>/jffs/configs/dnsmasq.conf.add # add 'ipset=' domains entry to dnsmasq.conf.add
    fi
    service restart_dnsmasq >/dev/null 2>&1
#  else
#    if [ "$2" != "del" ]; then
#      printf "ipset=$DNSMASQ_ENTRY\n" >/jffs/configs/dnsmasq.conf.add # dnsmasq.conf.add does not exist, create dnsmasq.conf.add
#      logger -st "($(basename "$0"))" $$ "'"ipset=$DNSMASQ_ENTRY"'" added to "'/jffs/configs/dnsmasq.conf.add'"
#      service restart_dnsmasq >/dev/null 2>&1
#    fi
  fi
}

Check_Ipset_List() {

  IPSET_NAME="$1"

  if [ "$2" != "del" ]; then
    if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" != "$1" ]; then #does ipset list exist?
      if [ -s "$DIR/$IPSET_NAME" ]; then # does $1 ipset restore file exist?
        ipset restore -! <"$DIR/$IPSET_NAME" # Restore ipset list if restore file exists at $DIR/$1
        logger -st "($(basename "$0"))" $$ IPSET restored: "$IPSET_NAME" from "$DIR/$IPSET_NAME"
      else
        ipset create "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536 # No restore file, so create $1 ipset list from scratch
        logger -st "($(basename "$0"))" $$ IPSET created: "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536
      fi
    fi
  else
    if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" = "$IPSET_NAME" ]; then
      ipset destroy "$IPSET_NAME"
      logger -st "($(basename "$0"))" $$ IPSET "$1" deleted!
    fi
  fi
}

# if IPSET is older than 24 hours, save the current IPSET list to disk
Check_Restore_File_Age() {

  IPSET_NAME="$1"
  DIR="$2"

  if [ -s "$DIR" ]; then
    if [ "$(find "$DIR" -name "$IPSET_NAME" -mtime +1 -print 2>/dev/null)" = "$DIR/$IPSET_NAME" ]; then
      ipset save "$IPSET_NAME" >"$DIR/$IPSET_NAME"
    fi
  fi
}

# If cronjob to back up the DOMAINS ipset list every 24 hours @ 2:00 AM does not exist, then create it
Check_Cron_Job() {

  IPSET_NAME="$1"

  cru l | grep "$1" >/dev/null 2>&1 # Martineau Fix
  if [ "$?" = "1" ]; then # no cronjob entry found, create it
    if [ "$2" != "del" ]; then
      cru a "$IPSET_NAME" "0 2 * * * ipset save $IPSET_NAME > $DIR/$IPSET_NAME" >/dev/null 2>&1
      logger -st "($(basename "$0"))" $$ CRON schedule created: "#$IPSET_NAME#" "'0 2 * * * ipset save $IPSET_NAME'"
    fi
  else
    if [ "$2" = "del" ]; then
      cru d "$IPSET_NAME" "0 2 * * * ipset save $IPSET_NAME" >/dev/null 2>&1
      logger -st "($(basename "$0"))" $$ CRON schedule deleted: "#$IPSET_NAME#" "'0 2 * * * ipset save $IPSET_NAME'"
    fi
  fi
}

Unlock_Script() {

  if [ "$lock_load_DNSMASQ_ipset" = "true" ]; then
    rm -rf "/tmp/load_DNSMASQ_ipset.lock"
  fi
}

Error_Exit() {

    error_str="$*"
    logger -st "($(basename "$0"))" $$ "$error_str"
    Unlock_Script
    exit 1
}

#==================== End of Functions
Check_Lock "$@"

AUTOSCAN=
if [ "$(echo "$@" | grep -c 'autoscan')" -gt 0 ]; then
  AUTOSCAN=$(echo "$@" | sed -n "s/^.*autoscan=//p" | awk '{print $1}')
  [ -z "$AUTOSCAN" ] && AUTOSCAN="/opt/var/log/dnsmasq.log"
  if [ -n "$AUTOSCAN" ]; then
    if [ ! -f "$AUTOSCAN" ]; then
      Error_Exit "ERROR 'autoscan=$AUTOSCAN' file NOT found!"
    fi
  fi
fi

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

if [ -n "$2" ] && [ -z "$AUTOSCAN" ]; then # v1.3
  DOMAINS_LIST="$2"
else
  if [ -z "$AUTOSCAN" ]; then
    Error_Exit "ERROR missing arg2 'domain_list'"
  else
    DOMAIN=$2
    # So having extracted the matching domains
    # Extract only the two-part TL domain i.e. disregard the sub-domains
    DOMAINS_LIST=$(grep "$DOMAIN" $AUTOSCAN | grep reply | awk '{print $(NF-2)}' | awk -F\. '{print $(NF-1) FS $NF}' | sort | uniq | tr '\n' ',')
    if [ -z "$DOMAINS_LIST" ]; then
      Error_Exit "No domain names were harvested from /opt/var/log/dnsmasq.log"
    fi
  fi
fi

if [ "$(echo "$@" | grep -c 'dir=')" -gt 0 ]; then
  DIR=$(echo "$@" | sed -n "s/^.*dir=//p" | awk '{print $1}') # v1.2 Mount point/directory for backups
fi

if [ -z "$IPSET_NAME" ] || [ -z "$DOMAINS_LIST" ]; then
  Error_Exit "ERROR missing args 'ipset_name' 'domain_list'"
fi

DOMAINS_LIST=$(echo "$DOMAINS_LIST" | sed 's/,$//' | tr ',' '/') # v1.3
DNSMASQ_ENTRY="/$DOMAINS_LIST/$IPSET_NAME"

# Delete mode?
if [ "$(echo "$@" | grep -cw 'del')" -gt 0 ]; then
  Check_Dnsmasq "$DNSMASQ_ENTRY" "del"
  Check_Cron_Job "$IPSET_NAME" "del"
  Check_Ipset_List "$IPSET_NAME" "del"
else
  Chk_Entware 60
  if [ "$READY" -eq 1 ]; then Error_Exit "Entware not ready. Unable to access ipset save/restore location"; fi
  Check_Dnsmasq "$DNSMASQ_ENTRY"
  Check_Ipset_List "$IPSET_NAME"
  Check_Restore_File_Age "$IPSET_NAME" "$DIR"
  Check_Cron_Job "$IPSET_NAME"
fi

Unlock_Script

logger -st "($(basename "$0"))" $$ Completed Script Execution
