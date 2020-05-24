#!/bin/sh
####################################################################################################
# Script: autoscan.sh
# VERSION=1.0.0
# Author: Xentrk
# Date: 24-May-2020
#
# Description:
#  Use this script to search for top level domain names that contain the keyword specified on the 'autoscan=' parm
#  Usage example:
#    sh autoscan.sh autoscan=disney
#    sh autoscan.sh autoscan=netflix,nflx
#
####################################################################################################

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
