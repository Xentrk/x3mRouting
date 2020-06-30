#!/bin/sh
####################################################################################################
# Script: mount_files_gui.sh
# VERSION=1.0.1
# Author: Xentrk
# Date: 27-July-2019
#
# Grateful:
# Thank you to @Martineau on snbforums.com for educating myself and others on Selective
# Routing techniques using Asuswrt-Merlin firmware.
#
#####################################################################################################
# Script Description:
#  This script is called from /jffs/scripts/init-start.
#  The script will mount files used by the Asuswrt-Merlin-Selective Routing project to override
#  the firmware files.
#
#####################################################################################################
logger -t "($(basename "$0"))" $$ Starting Script Execution

if [ "$(df | grep -c "/usr/sbin/vpnrouting.sh")" -eq 0 ]; then
  mount -o bind /jffs/addons/x3mRouting/vpnrouting.sh /usr/sbin/vpnrouting.sh
fi
if [ "$(df | grep -c "/usr/sbin/updown-client.sh")" -eq 0 ]; then
  mount -o bind /jffs/addons/x3mRouting/updown-client.sh /usr/sbin/updown-client.sh
fi
if [ "$(df | grep -c "/www/Advanced_OpenVPNClient_Content.asp")" -eq 0 ]; then
  mount -o bind /jffs/addons/x3mRouting/Advanced_OpenVPNClient_Content.asp /www/Advanced_OpenVPNClient_Content.asp
fi

logger -t "($(basename "$0"))" $$ Completed Script Execution
