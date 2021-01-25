#!/bin/sh
####################################################################################################
# Script: autoscan.sh
# VERSION=1.2.1
# Author: Xentrk
# Date: 16-January-2021
#
####################################################################################################
#_____________________________________________________________________________________________________________
#
# Description:
#
# Used to identify and analyze domain names queried by dnsmasq for selective routing purposes.
# Output is displayed in IPSET format followed by the Fully Qualified Domain Name (FQDN).
#
# Script can also be used to list the Fully Qualified Domain Name(FQDN) added to the IPSET list using the 'ipset_name=' parm
# Usage examples:
#
# Display query records
#   sh autoscan.sh scan=disney
#   sh autoscan.sh scan=netflix,nflx
#   sh autoscan.sh scan=hbo,hbomax
#
# Display Fully Qualified Domain Name(FQDN) added to IPSET list
#   sh autoscan.sh ipset_name=HBOMAX
#   sh autoscan.sh ipset_name=NETFLIX,HBOMAX
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

if [ "$(echo "$@" | grep -c "scan=")" -eq 1 ]; then

  SCAN_SPACE_LIST=$(echo "$@" | sed -n "s/^.*scan=//p" | awk '{print $1}' | tr ',' ' ')

  true >/opt/tmp/DOMAIN_LIST

  for TOP_LEVEL_DOMAIN in $SCAN_SPACE_LIST; do
    SCAN_LIST=$(grep -F "query[A]" "/opt/var/log/dnsmasq.log" | grep "$TOP_LEVEL_DOMAIN" | awk '{print $(NF-2)}' | awk -F\. '{print $(NF-1) FS $NF}' | sort | uniq)
    [ -n "$SCAN_LIST" ] && echo "$SCAN_LIST" >>/opt/tmp/DOMAIN_LIST
  done
  echo
  echo "IPSET Format"
  echo "-------------------------------------"
  grep . /opt/tmp/DOMAIN_LIST | sort -u
  echo
  rm -rf /opt/tmp/DOMAIN_LIST

  #if [ "$1" = "long" ] || [ "$1" = "-l" ]; then
  true >/opt/tmp/DOMAIN_LIST

  for TOP_LEVEL_DOMAIN in $SCAN_SPACE_LIST; do
    SCAN_LIST=$(grep -F "query[A]" "/opt/var/log/dnsmasq.log" | grep "$TOP_LEVEL_DOMAIN" | grep -F "query[A]" | awk '{print $6}' | sort -u)
    [ -n "$SCAN_LIST" ] && echo "$SCAN_LIST" >>/opt/tmp/DOMAIN_LIST
  done
  echo
  echo "FQDN Format"
  echo "-------------------------------------"
  grep . /opt/tmp/DOMAIN_LIST | sort -u
  echo
  rm -rf /opt/tmp/DOMAIN_LIST
  exit
fi

if [ "$(echo "$@" | grep -c "ipset_name=")" -eq 1 ]; then

  true >/opt/tmp/DOMAIN_LIST

  IPSETS=$(echo "$@" | sed -n "s/^.*ipset_name=//p" | awk '{print $1}' | tr ',' ' ')
  for IPSET_NAME in $IPSETS; do
    if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" = "$IPSET_NAME" ]; then #does ipset list exist?
      echo
      echo "FQDN added to $IPSET_NAME"
      echo "-------------------------------------"
      grep -w "$IPSET_NAME" /opt/var/log/dnsmasq.log | grep -v "([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4}" | awk '{print $9}' | sort -u
      echo
    else
      echo "IPSET '$IPSET_NAME' does not exist"
      echo
    fi
  done
else
  echo "Expecting 'autoscan=' or 'scan=' parm" && exit 1
fi
