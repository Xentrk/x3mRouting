#!/bin/sh
####################################################################################################
# Script: autoscan.sh
# VERSION=1.0.0
# Author: Xentrk
# Date: 28-June-2020
#
####################################################################################################
#_____________________________________________________________________________________________________________
#
# Description:
#
# Use this script to search for top level domain names that contain the keyword specified on the 'autoscan=' parm
#
# Usage examples:
#
#    sh autoscan.sh autoscan=disney
#    sh autoscan.sh autoscan=netflix,nflx
#_____________________________________________________________________________________________________________

# Print between line beginning with '#__' to first blank line inclusive (source: Martineau)
ShowHelp() {
  awk '/^#__/{f=1} f{print; if (!NF) exit}' "$0" | more
}

# Need assistance!???
if [ "$1" = "help" ] || [ "$1" = "-h" ]; then
  ShowHelp
  exit 0
fi

if [ ! -s "/opt/var/log/dnsmasq.log" ]; then
  printf '\nError: /opt/var/log/dnsmasq.log file does not exist\n' && printf '\nScript expects dnsmasq.log file to exist in /opt/var/log\n' && exit 1
fi

[ "$(echo "$@" | grep -c "autoscan=")" -eq 0 ] && echo "Expecting 'autoscan=' parm" && exit 1

SCAN_SPACE_LIST=$(echo "$@" | sed -n "s/^.*autoscan=//p" | awk '{print $1}' | tr ',' ' ')

true >/opt/tmp/DOMAIN_LIST

for TOP_LEVEL_DOMAIN in $SCAN_SPACE_LIST; do
  SCAN_LIST=$(grep "$TOP_LEVEL_DOMAIN" "/opt/var/log/dnsmasq.log" | grep query | awk '{print $(NF-2)}' | awk -F\. '{print $(NF-1) FS $NF}' | sort | uniq)
  [ -n "$SCAN_LIST" ] && echo "$SCAN_LIST" >>/opt/tmp/DOMAIN_LIST
done
echo
cat /opt/tmp/DOMAIN_LIST
echo
rm -rf /opt/tmp/DOMAIN_LIST
