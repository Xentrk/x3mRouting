#!/bin/sh
####################################################################################################
# Script: x3mRouting_rules.sh
# Version 1.0
# Author: Xentrk
# 29-July-2018
#
#####################################################################################################
# Description:
#
#####################################################################################################
logger -t "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging

set -x

create_lan_client_routes () {
# Implement routing rules for LAN clients configured in /jffs/configs/x3mRouting_lan_client_rules

    OLDIFS="$IFS"
    IFS=" "
    DEST="0.0.0.0"
    VPN="VPN"
    RECORD_BEGIN="<"
    FIELD_SEPARATOR=">"

    while IFS=" " read -r OVPNC IP DESCRIPTION
    do
        if [ $(echo "$OVPNC" | cut -c 1) != "#" ]; then
            if [ "$OVPNC" -ge "0" ]; then
                case "$OVPNC" in
                    1) printf '%s%s%s%s%s%s%s%s\n' "$RECORD_BEGIN" "$DESCRIPTION" "$FIELD_SEPARATOR" "$IP" "$FIELD_SEPARATOR" "$DEST" "$FIELD_SEPARATOR" "$VPN" >> /tmp/ovpnc1.$$ ;;
                    2) printf '%s%s%s%s%s%s%s%s\n' "$RECORD_BEGIN" "$DESCRIPTION" "$FIELD_SEPARATOR" "$IP" "$FIELD_SEPARATOR" "$DEST" "$FIELD_SEPARATOR" "$VPN" >> /tmp/ovpnc2.$$ ;;
                    3) printf '%s%s%s%s%s%s%s%s\n' "$RECORD_BEGIN" "$DESCRIPTION" "$FIELD_SEPARATOR" "$IP" "$FIELD_SEPARATOR" "$DEST" "$FIELD_SEPARATOR" "$VPN" >> /tmp/ovpnc3.$$ ;;
                    4) printf '%s%s%s%s%s%s%s%s\n' "$RECORD_BEGIN" "$DESCRIPTION" "$FIELD_SEPARATOR" "$IP" "$FIELD_SEPARATOR" "$DEST" "$FIELD_SEPARATOR" "$VPN" >> /tmp/ovpnc4.$$ ;;
                    5) printf '%s%s%s%s%s%s%s%s\n' "$RECORD_BEGIN" "$DESCRIPTION" "$FIELD_SEPARATOR" "$IP" "$FIELD_SEPARATOR" "$DEST" "$FIELD_SEPARATOR" "$VPN" >> /tmp/ovpnc5.$$ ;;
                esac
            fi
        fi
    done < /jffs/configs/x3mRouting_lan_client_rules
     IFS=$OLDIFS

# route OVPNC1 clients
    if [ -s "/tmp/ovpnc1.$$" ]; then
            awk '{ print }' ORS='' < "/tmp/ovpnc1.$$" > /jffs/configs/ovpnc1.nvram
#            nvram set vpn_client1_clientlist=$(cat /jffs/configs/ovpnc1.nvram)
#            nvram commit
#            service restart_vpnclient1 &
    fi

# route OVPNC2 clients
    if [ -s "/tmp/ovpnc2.$$" ]; then
            awk '{ print }' ORS='' < "/tmp/ovpnc2.$$" > /jffs/configs/ovpnc2.nvram
#            nvram set vpn_client2_clientlist=$(cat /jffs/configs/ovpnc2.nvram)
#            nvram commit
#            service restart_vpnclient2 &
    fi

# route OVPNC3 clients
    if [ -s "/tmp/ovpnc3.$$" ]; then
            awk '{ print }' ORS='' < "/tmp/ovpnc3.$$" > /jffs/configs/ovpnc3.nvram
#            nvram set vpn_client3_clientlist=$(cat /jffs/configs/ovpnc3.nvram)
#            nvram commit
#            service restart_vpnclient3 &
    fi

# route OVPNC4 clients
    if [ -s "/tmp/ovpnc4.$$" ]; then
            awk '{ print }' ORS='' < "/tmp/ovpnc4.$$" > /jffs/configs/ovpnc4.nvram
#            nvram set vpn_client4_clientlist=$(cat /jffs/configs/ovpnc4.nvram)
#            nvram commit
#            service restart_vpnclient4 &
    fi

# route OVPNC5 clients
    if [ -s "/tmp/ovpnc5.$$" ]; then
            awk '{ print }' ORS='' < "/tmp/ovpnc5.$$" > /jffs/configs/ovpnc5.nvram
#            nvram set vpn_client5_clientlist=$(cat /jffs/configs/ovpnc5.nvram)
#            nvram commit
#            service restart_vpnclient5 &
    fi
}

create_lan_client_routes

logger -t "($(basename "$0"))" $$ Ending Script Execution
