#!/bin/sh
####################################################################################################
# Script: x3mRouting_rules.sh
# VERSION=1.0.0
# Author: Xentrk
# 22-March-2019
#
#####################################################################################################
# Description:
#   Create nvram LAN client files based on the routing configuration defined in the file
#   /jffs/configs/x3mRouting_lan_client_rules
#
#####################################################################################################
logger -t "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging
# set -x

Create_LAN_Client_Routes() {

  CONFIG_FILE="/jffs/configs/x3mRouting_client_rules"
  OLDIFS="$IFS"
  IFS=" "
  DEST="0.0.0.0"
  VPN="VPN"
  RECORD_BEGIN="<"
  FIELD_SEPARATOR=">"

  while IFS=" " read -r OVPNC IP DESCRIPTION; do
    if [ "$(echo "$OVPNC" | cut -c 1)" != "#" ]; then
      if [ "$OVPNC" -ge "0" ]; then
        case "$OVPNC" in
        1) printf '%s%s%s%s%s%s%s%s\n' "$RECORD_BEGIN" "$DESCRIPTION" "$FIELD_SEPARATOR" "$IP" "$FIELD_SEPARATOR" "$DEST" "$FIELD_SEPARATOR" "$VPN" >>/tmp/ovpnc1.$$ ;;
        2) printf '%s%s%s%s%s%s%s%s\n' "$RECORD_BEGIN" "$DESCRIPTION" "$FIELD_SEPARATOR" "$IP" "$FIELD_SEPARATOR" "$DEST" "$FIELD_SEPARATOR" "$VPN" >>/tmp/ovpnc2.$$ ;;
        3) printf '%s%s%s%s%s%s%s%s\n' "$RECORD_BEGIN" "$DESCRIPTION" "$FIELD_SEPARATOR" "$IP" "$FIELD_SEPARATOR" "$DEST" "$FIELD_SEPARATOR" "$VPN" >>/tmp/ovpnc3.$$ ;;
        4) printf '%s%s%s%s%s%s%s%s\n' "$RECORD_BEGIN" "$DESCRIPTION" "$FIELD_SEPARATOR" "$IP" "$FIELD_SEPARATOR" "$DEST" "$FIELD_SEPARATOR" "$VPN" >>/tmp/ovpnc4.$$ ;;
        5) printf '%s%s%s%s%s%s%s%s\n' "$RECORD_BEGIN" "$DESCRIPTION" "$FIELD_SEPARATOR" "$IP" "$FIELD_SEPARATOR" "$DEST" "$FIELD_SEPARATOR" "$VPN" >>/tmp/ovpnc5.$$ ;;
        esac
      fi
    fi
  done <"$CONFIG_FILE"
  IFS=$OLDIFS

  # OVPNC1 clients
  if [ -s "/tmp/ovpnc1.$$" ]; then
    awk '{ print }' ORS='' <"/tmp/ovpnc1.$$" >/jffs/configs/ovpnc1.nvram
    rm /tmp/ovpnc1.$$
  fi

  # OVPNC2 clients
  if [ -s "/tmp/ovpnc2.$$" ]; then
    awk '{ print }' ORS='' <"/tmp/ovpnc2.$$" >/jffs/configs/ovpnc2.nvram
    rm -rf /tmp/ovpnc2.$$
  fi

  # OVPNC3 clients
  if [ -s "/tmp/ovpnc3.$$" ]; then
    awk '{ print }' ORS='' <"/tmp/ovpnc3.$$" >/jffs/configs/ovpnc3.nvram
    rm -rf /tmp/ovpnc3.$$
  fi

  # OVPNC4 clients
  if [ -s "/tmp/ovpnc4.$$" ]; then
    awk '{ print }' ORS='' <"/tmp/ovpnc4.$$" >/jffs/configs/ovpnc4.nvram
    rm -rf /tmp/ovpnc4.$$
  fi

  # OVPNC5 clients
  if [ -s "/tmp/ovpnc5.$$" ]; then
    awk '{ print }' ORS='' <"/tmp/ovpnc5.$$" >/jffs/configs/ovpnc5.nvram
    rm -rf /tmp/ovpnc5.$$
  fi
}

Create_LAN_Client_Routes

logger -t "($(basename "$0"))" $$ Ending Script Execution
