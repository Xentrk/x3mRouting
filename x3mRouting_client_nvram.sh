#!/bin/sh
####################################################################################################
# Script: x3mRouting_rules.sh
# VERSION=2.0.0
# Author: Xentrk
# Date: 5-August-2020
#
#####################################################################################################
# Description:
#   Create nvram LAN client files based on the routing configuration defined in the file
#   /jffs/configs/x3mRouting_lan_client_rules
#
#####################################################################################################

Cleanup_OLD_LAN_Client_Routes() {
  for VPN_ID in 1 2 3 4 5; do
    [ -f "$ADDONS_DIR/ovpnc${VPN_ID}.nvram" ] && rm -rf "$ADDONS_DIR/ovpnc${VPN_ID}.nvram"
  done

}

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

  for VPN_ID in 1 2 3 4 5; do
    if [ -s "/tmp/ovpnc${VPN_ID}.$$" ]; then
      awk '{ print }' ORS='' <"/tmp/ovpnc${VPN_ID}.$$" >"$ADDONS_DIR/ovpnc${VPN_ID}.nvram"
      echo "Created nvram file for OpenVPN Client $VPN_ID" && echo "Restarting OpenVPN Client $VPN_ID to apply assignments"
      service restart_vpnclient${VPN_ID}
      rm /tmp/ovpnc${VPN_ID}.$$
    fi
  done

}

# End of functions
# Begin
ADDONS_DIR=/jffs/addons/x3mRouting
REPO_DIR=/jffs/scripts/x3mRouting

Cleanup_OLD_LAN_Client_Routes
Create_LAN_Client_Routes
echo "Script completed"
