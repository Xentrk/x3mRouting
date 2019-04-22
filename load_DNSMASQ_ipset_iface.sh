#!/bin/sh
####################################################################################################
# Script: load_DNSMASQ_ipset_iface.sh
# VERSION=1.0.0
# Author: Martineau, Xentrk
# Date: 6-April-2019
#
# Grateful:
#   Thank you to @Martineau on snbforums.com for sharing his Selective Routing expertise
#   and on-going support!
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
# Usage:     load_DNSMASQ_ipset_iface.sh   {[0|1|2|3|4|5]  ipset_name  domains[,...]} ['autoscan'] [del]  [dir='directory']
#
# Usage:     load_DNSMASQ_ipset_iface.sh   2   BBC   bbc.co.uk
#               Create IPSET BBC via VPN Client 2 and autopopulate IPs for domain 'bbc.co.uk'
# Usage:     load_DNSMASQ_ipset_iface.sh   2   BBC   bbc.co.uk   del
#               Delete IPSET BBC and remove from VPN Client 2
# Usage:     load_DNSMASQ_ipset_iface.sh   2   BBC   bbc.co.uk   dir=/mnt/sda1/Backups
#               As per example one, but use '/mnt/sda1/Backups' rather than Entware's 'opt/tmp' for ipset save/restore
# Usage:     load_DNSMASQ_ipset_iface.sh   0   NETFLIX   amazonaws.com,netflix.com,nflxext.com,nflximg.net,nflxso.net,nflxvideo.net
#               Create IPSET NETFLIX via WAN and autopopulate IPs for multiple Netflix domains
# Usage:     load_DNSMASQ_ipset_iface.sh   2 SKY sky.com autoscan
#               Create IPSET SKY and extract all matching Top-Level domains containing 'sky.com' from
#               '/opt/var/log/dnsmasq.log'
#               e.g. ipset=/akadns.net/edgekey.net/edgesuite.net/epgsky.com/sky.com/SKY
#               from 'a674.hsar.cdn.sky.com.edgesuite.net/adm.sky.com/assets.sky.com/assets.sky.com-secure.edgekey.net/awk.epgsky.com' etc...
####################################################################################################
logger -st "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging
set -x

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
      logger -st "($(basename "$0"))" "[*] Lock File Detected ($(sed -n '1p' /tmp/load_DNSMASQ_ipset.lock)) (pid=$(sed -n '2p' /tmp/load_DNSMASQ_ipset_iface.lock)) - Exiting (cpid=$$)"
      echo
      exit 1
    fi
  fi
  echo "$@" >/tmp/load_DNSMASQ_ipset.lock
  echo "$$" >>/tmp/load_DNSMASQ_ipset.lock
  date +%s >>/tmp/load_DNSMASQ_ipset.lock
  lock_load_DNSMASQ_ipset_iface="true"
}

Chk_Entware() {

  # ARGS [wait attempts] [specific_entware_utility]

  READY=1 # Assume Entware Utilities are NOT available
  ENTWARE="opkg"
  ENTWARE_UTILITY= # Specific Entware utility to search for (Tacky GLOBAL variable returned!)

  MAX_TRIES=30
  if [ -n "$2" ] && [ -n "$(echo $2 | grep -E '^[0-9]+$')" ]; then
    MAX_TRIES=$2
  fi

  if [ -n "$1" ] && [ -z "$(echo $1 | grep -E '^[0-9]+$')" ]; then
    ENTWARE_UTILITY=$1
  else
    if [ -z "$2" ] && [ -n "$(echo $1 | grep -E '^[0-9]+$')" ]; then
      MAX_TRIES=$1
    fi
  fi

  # Wait up to (default) 30 seconds to see if Entware utilities available.....
  TRIES=0
  while [ "$TRIES" -lt "$MAX_TRIES" ]; do
    if [ -n "$(which $ENTWARE)" ] && [ "$($ENTWARE -v | grep -o "version")" = "version" ]; then # Check Entware exists and it executes OK
      if [ -n "$ENTWARE_UTILITY" ]; then # Specific Entware utility installed?
        if [ -n "$($ENTWARE list-installed $ENTWARE_UTILITY)" ]; then
          READY=0 # Specific Entware utility found
        else
          # Not all Entware utilities exist as a stand-alone package e.g. 'find' is in package 'findutils'
          # 	opkg files findutils
          #
          # 	Package findutils (4.6.0-1) is installed on root and has the following files:
          # 	/opt/bin/xargs
          # 	/opt/bin/find
          # Add 'executable' as 'stubby' leaves behind two directories containing the string 'stubby'
          if [ -d /opt ] && [ -n "$(find /opt/ -type f -executable -name $ENTWARE_UTILITY)" ]; then
            READY=0 # Specific Entware utility found
          fi
        fi
      else
        READY=0 # Entware utilities ready
      fi
      break
    fi
    sleep 1
    logger -st "($(basename $0))" $$ "Entware" "$ENTWARE_UTILITY" "not available - wait time" $((MAX_TRIES - TRIES - 1))" secs left"
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

# check if /jffs/configs/dnsmasq.conf.add contains 'ipset=' entry for the domains
check_dnsmasq() {

  if [ -s /jffs/configs/dnsmasq.conf.add ]; then # dnsmasq.conf.add file exists
    if [ "$(grep -c "$1" "/jffs/configs/dnsmasq.conf.add")" -eq "1" ]; then # see if line exists for $IPSET_NAME
      if [ "$2" = "del" ]; then
        sed -i "/^ipset.*${IPSET_NAME}$/d" /jffs/configs/dnsmasq.conf.add
        logger -st "($(basename "$0"))" $$ "'"ipset=$1"'" deleted from "'/jffs/configs/dnsmasq.conf.add'"
      fi
    else
      printf "ipset=$1\n" >>/jffs/configs/dnsmasq.conf.add # add 'ipset=' domains entry to dnsmasq.conf.add
    fi
    service restart_dnsmasq >/dev/null 2>&1
  else
    if [ "$2" != "del" ]; then
      printf "ipset=$1\n" >/jffs/configs/dnsmasq.conf.add # dnsmasq.conf.add does not exist, create dnsmasq.conf.add
      logger -st "($(basename "$0"))" $$ "'"ipset=$1"'" added to "'/jffs/configs/dnsmasq.conf.add'"
      service restart_dnsmasq >/dev/null 2>&1
    fi
  fi
}

check_ipset_list() {
  IPSET_NAME=$1

  if [ "$2" != "del" ]; then
    if [ "$(ipset list -n $IPSET_NAME 2>/dev/null)" != "$IPSET_NAME" ]; then #does ipset list exist?
      if [ -s "$DIR/$IPSET_NAME" ]; then # does $IPSET_NAME ipset restore file exist?
        ipset restore -! <"$DIR/$IPSET_NAME" # Restore ipset list if restore file exists at $DIR/$1
        logger -st "($(basename "$0"))" $$ IPSET restored: $1 from "'$DIR/$IPSET_NAME'"
      else
        ipset create $IPSET_NAME hash:net family inet hashsize 1024 maxelem 65536 # No restore file, so create $1 ipset list from scratch
        logger -st "($(basename "$0"))" $$ IPSET created: $IPSET_NAME hash:net family inet hashsize 1024 maxelem 65536
      fi
    fi
  else
    if [ "$(ipset list -n $IPSET_NAME 2>/dev/null)" = "$IPSET_NAME" ]; then
      ipset destroy $IPSET_NAME && logger -st "($(basename "$0"))" $$ IPSET "$IPSET_NAME" deleted! || logger -st "($(basename "$0"))" $$ Error attempting to delete IPSET "$IPSET_NAME"!
    fi
  fi
}

# if IPSET is older than 24 hours, save the current IPSET list to disk
check_restore_file_age() {
  IPSET_NAME=$1
  DIR=$2

  if [ -s "$DIR" ]; then
    if [ "$(find $DIR -name $IPSET_NAME -mtime +1 -print 2>/dev/null)" = "$DIR/$IPSET_NAME" ]; then
      ipset save $IPSET_NAME >"$DIR/$IPSET_NAME"
    fi
  fi
}

# If cronjob to back up the DOMAINS ipset list every 24 hours @ 2:00 AM does not exist, then create it
check_cron_job() {
  cru l | grep $1 2>/dev/null # Martineau Fix
  if [ "$?" = "1" ]; then # no cronjob entry found, create it
    if [ "$2" != "del" ]; then
      cru a $1 "0 2 * * * ipset save $1 > $DIR/$1"
      logger -st "($(basename "$0"))" $$ CRON schedule created: "#$1#" "'0 2 * * * ipset save $1'"
    fi
  else
    if [ "$2" = "del" ]; then
      cru d $1 "0 2 * * * ipset save $1"
      logger -st "($(basename "$0"))" $$ CRON schedule deleted: "#$1#" "'0 2 * * * ipset save $1'"
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

#==================== end of functions
Check_Lock "$@"

#======================================================================================Martineau Hack
VPNID=0
IPSET_NAME=
DOMAINS_LIST=

AUTOSCAN=
if [ "$(echo "$@" | grep -c 'autoscan')" -gt 0 ]; then
  AUTOSCAN=$(echo "$@" | sed -n "s/^.*autoscan=//p" | awk '{print $1}')
  [ -z "$AUTOSCAN" ] && AUTOSCAN="/opt/var/log/dnsmasq.log"
  if [ -n "$AUTOSCAN" ]; then
    if [ ! -f "$AUTOSCAN" ]; then
      logger -st "($(basename "$0"))" $$ "ERROR 'autoscan=$AUTOSCAN' file NOT found!"
      exit 99
    fi
  fi
fi

if [ "$(echo "$@" | grep -c 'dir=')" -gt 0 ]; then
  DIR=$(echo "$@" | sed -n "s/^.*dir=//p" | awk '{print $1}') # v1.2 Mount point/directory for backups
else
  DIR="/opt/tmp"
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
if [ -n "$3" ] && [ -z "$AUTOSCAN" ]; then # v1.3
  DOMAINS_LIST="$3"
else
  if [ -z "$AUTOSCAN" ]; then
    logger -st "($(basename "$0"))" $$ ERROR missing arg3 "'domain_list'"
    exit 98
  else
    DOMAIN=$3
    # So having extracted the matching domains
    # Extract only the two-part TL domain i.e. disregard the sub-domains
    DOMAINS_LIST=$(grep $DOMAIN $AUTOSCAN | grep reply | awk '{print $(NF-2)}' | awk -F\. '{print $(NF-1) FS $NF}' | sort | uniq | tr '\n' ',')
    if [ -z "$DOMAINS_LIST" ]; then
      logger -st "($(basename "$0"))" $$ "No domain names were harvested from /opt/var/log/dnsmasq.log"
      exit 98
    fi
  fi
fi

if [ "$(echo "$@" | grep -c 'dir=')" -gt 0 ]; then
  DIR=$(echo "$@" | sed -n "s/^.*dir=//p" | awk '{print $1}') # v1.2 Mount point/directory for backups
fi

if [ -z "$IPSET_NAME" ] || [ -z "$DOMAINS_LIST" ]; then
  logger -st "($(basename "$0"))" $$ ERROR missing args "'target destination' 'ipset_name' 'domain_list'"
  exit 98
fi

DOMAINS_LIST=$(echo "$DOMAINS_LIST" | sed 's/,$//' | tr ',' '/') # v1.3
DNSMASQ_ENTRY="/$DOMAINS_LIST/$IPSET_NAME"

set_fwmark_parms

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
  logger -st "($(basename "$0"))" $$ ERROR "$1" should be "0-WAN or 1-5=VPN"
  exit 99
  ;;
esac

# Delete mode?
if [ "$(echo "$@" | grep -cw 'del')" -gt 0 ]; then
  Chk_Entware 30
  check_dnsmasq "$DNSMASQ_ENTRY" "del"
  check_cron_job "$IPSET_NAME" "del"
  create_routing_rules "$IPSET_NAME" "del"
  check_ipset_list "$IPSET_NAME" "del"
else
  #==================================================================================================
  Chk_Entware 30
  set_ip_rule
  check_dnsmasq "$DNSMASQ_ENTRY"              # Martineau Hack
  check_ipset_list "$IPSET_NAME"              # Martineau Hack
  check_restore_file_age "$IPSET_NAME" "$DIR" # Martineau Hack
  check_cron_job "$IPSET_NAME"                # Martineau Hack
  create_routing_rules "$IPSET_NAME"          # Martineau Hack
fi

if [ "$lock_load_DNSMASQ_ipset_iface" = "true" ]; then rm -rf "/tmp/load_DNSMASQ_ipset_iface.lock"; fi
logger -st "($(basename "$0"))" $$ Completed Script Execution
