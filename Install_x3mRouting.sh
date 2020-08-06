#!/bin/sh
####################################################################################################
# Script: x3mRouting_rules.sh
# VERSION=2.1.0
# Author: Xentrk
# Date: 6-August-2020
#
#####################################################################################################
# Description:
#   Create nvram LAN client files based on the routing configuration defined in the file
#   /jffs/configs/x3mRouting_lan_client_rules
#
#####################################################################################################

Chk_Entware() {

  # ARGS [wait attempts] [specific_entware_utility]
  READY="1"          # Assume Entware Utilities are NOT available
  ENTWARE_UTILITY="" # Specific Entware utility to search for
  MAX_TRIES="30"

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
      if [ -n "$ENTWARE_UTILITY" ]; then # Specific Entware utility installed?
        if [ -n "$(opkg list-installed "$ENTWARE_UTILITY")" ]; then
          READY="0" # Specific Entware utility found
        else
          # Not all Entware utilities exists as a stand-alone package e.g. 'find' is in package 'findutils'
          if [ -d /opt ] && [ -n "$(find /opt/ -name "$ENTWARE_UTILITY")" ]; then
            READY="0" # Specific Entware utility found
          fi
        fi
      else
        READY="0" # Entware utilities ready
      fi
      break
    fi
    sleep 1
    logger -st "($(basename "$0"))" "$$ Entware $ENTWARE_UTILITY not available - wait time $((MAX_TRIES - TRIES - 1)) secs left"
    TRIES=$((TRIES + 1))
  done
  return "$READY"
}

Chk_Entware 30
if [ "$READY" -eq 1 ]; then
  echo "You must first install Entware before proceeding"
  printf 'Exiting %s\n' "$(basename "$0")"
  exit 1
fi

while true; do
  echo "Downloading, please wait patiently..."
  mkdir -p /jffs/addons/x3mRouting
  /usr/sbin/curl -s --retry 3 https://raw.githubusercontent.com/Xentrk/x3mRouting/x3mRouting-384.19/x3mRouting_Menu.sh -o /jffs/addons/x3mRouting/x3mRouting_Menu.sh
  chmod 755 /jffs/addons/x3mRouting/x3mRouting_Menu.sh
  # Remove old link or alias if exist
  if [ "$(/opt/bin/find /opt/bin/ -maxdepth 1 -type l -ls | grep -c "/opt/bin/x3mRouting -> /jffs/scripts/x3mRouting/x3mRouting.sh")" -eq 0 ]; then
    if [ -d "/opt/bin" ] && [ "$(/opt/bin/find /opt/bin/ -maxdepth 1 -type l -ls | grep -c "/opt/bin/x3mRouting -> /jffs/addons/x3mRouting/x3mRouting_Menu.sh")" -eq 0 ]; then
      if [ -s "/opt/bin/x3mRouting" ]; then # old alias situation
        rm -rf /opt/bin/x3mRouting 2>/dev/null
      fi
    else
      rm -rf /opt/bin/x3mRouting 2>/dev/null
    fi
  fi
  rm -rf /opt/bin/x3mMenu 2>/dev/null
  ln -s "/jffs/addons/x3mRouting/x3mRouting_Menu.sh" "/opt/bin/x3mMenu"
  x3mMenu
  exit 0
done
