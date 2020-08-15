#!/bin/sh
####################################################################################################
# Script: mount_files_lan.sh
# VERSION=2.1.0
# Author: Xentrk
# Date: 4-August-2020
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

logger -t "($(basename "$0"))" $$ Completed Script Execution
