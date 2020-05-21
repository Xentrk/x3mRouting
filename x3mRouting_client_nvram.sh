#!/bin/sh
####################################################################################################
# Script: x3mRouting_rules.sh
# VERSION=2.0.0
# Author: Xentrk
# 13-April-2020
#
#####################################################################################################
# Description:
#   Create nvram LAN client files based on the routing configuration defined in the file
#   /jffs/configs/x3mRouting_lan_client_rules
#
#####################################################################################################

# Uncomment the line below for debugging
# set -x

ADDON_DIR=/jffs/addons/x3mRouting

for VAR in 1 2 3 4 5; do
[ -f $ADDON_DIR/ovpnc${VAR}.nvram ] && rm -rf $ADDON_DIR/ovpnc${VAR}.nvram
done

Create_LAN_Client_Routes() {

  CONFIG_FILE="/jffs/scripts/x3mRouting/x3mRouting_client_rules"
  OLDIFS="$IFS"
  IFS=" "
  DEST="0.0.0.0"
  VPN="VPN"
  RECORD_BEGIN="<"
  FIELD_SEPARATOR=">"

  [ ! -s "$CONFIG_FILE" ] && echo "No $CONFIG_FILE found to process" | exit 1

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
    awk '{ print }' ORS='' <"/tmp/ovpnc1.$$" >"$ADDON_DIR/ovpnc1.nvram"
    echo "Created nvram file for OpenVPN Client 1"
    rm /tmp/ovpnc1.$$
  fi

  # OVPNC2 clients
  if [ -s "/tmp/ovpnc2.$$" ]; then
    awk '{ print }' ORS='' <"/tmp/ovpnc2.$$" >"$ADDON_DIR/ovpnc2.nvram"
    echo "Created nvram file for OpenVPN Client 2"
    rm -rf /tmp/ovpnc2.$$
  fi

  # OVPNC3 clients
  if [ -s "/tmp/ovpnc3.$$" ]; then
    awk '{ print }' ORS='' <"/tmp/ovpnc3.$$" >"$ADDON_DIR/ovpnc3.nvram"
    echo "Created nvram file for OpenVPN Client 3"
    rm -rf /tmp/ovpnc3.$$
  fi

  # OVPNC4 clients
  if [ -s "/tmp/ovpnc4.$$" ]; then
    awk '{ print }' ORS='' <"/tmp/ovpnc4.$$" >"$ADDON_DIR/ovpnc4.nvram"
    echo "Created nvram file for OpenVPN Client 4"
    rm -rf /tmp/ovpnc4.$$
  fi

  # OVPNC5 clients
  if [ -s "/tmp/ovpnc5.$$" ]; then
    awk '{ print }' ORS='' <"/tmp/ovpnc5.$$" >"$ADDON_DIR/ovpnc5.nvram"
    echo "Created nvram file for OpenVPN Client 5"
    rm -rf /tmp/ovpnc5.$$
  fi
}

# End of functions
# Begin
mkdir -p /jffs/addons/x3mRouting
Create_LAN_Client_Routes
echo "Script completed"
