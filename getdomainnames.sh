#!/bin/sh
trap cleanup 1 2 3 6
####################################################################################################
# Script: getdomainnames.sh
# VERSION=2.0.0
# Author: Xentrk
# Date: 24-May-2020
#_______________________________________________________________________________________________________________
#
# This script will format the output stored in 'myfile' created using the command: tail -f dnsmasq.log > myfile
# and save the output to myfile_domains. The file name 'myfile' is an example. You can enter any name.
#
# Usage Instructions:
#  1. Enter a meaningful name for the file used to store the results.
#  2. Enter the IPv4 address of the LAN Client used to perform lookups.
#  3. Access the streaming service and watch some videos for a few seconds and select each menu option to generate
#     domain names.
#  4. Type 'Ctrl-C' to exit
#  5. The domain names collected will appear on the screen and stored in the /opt/var/log directory.
#_______________________________________________________________________________________________________________

# Print between line beginning with '#_' to first blank line inclusive
ShowHelp() {
  awk '/^#__/{f=1} f{print; if (!NF) exit}' "$0" | more
}

cleanup() {
  printf '\n%s\n' "Done capturing domains from dnsmasq.log"
  echo "Sorting file."
  true >"$OUTPUT_FILE"
  grep "$IPv4" "${OUTPUT_FILE}_tmp" | grep "query" | awk '{ print $6 }' | sort -u >>"$OUTPUT_FILE"
  printf '%s\n\n' "File contents are:"
  printf '%s\n\n' "$(cat "$OUTPUT_FILE")"
  printf '%s\n' "File location is: $OUTPUT_FILE"
  exit 0
}

# Need assistance!???
if [ "$1" = "help" ] || [ "$1" = "-h" ]; then
  ShowHelp
  exit 0
fi

if [ ! -s "/opt/var/log/dnsmasq.log" ]; then
  printf '\nError: /opt/var/log/dnsmasq.log file does not exist\n' && printf '\nScript expects dnsmasq.log file to exist in /opt/var/log\n' && exit 1
fi

printf '\nEnter a descriptive name of the output file ==> '
read -r "FILE"
OUTPUT_FILE="/opt/var/log/$FILE"

printf '\nEnter the IP address ==> '
read -r "IPv4"
IP=$(echo "$IPv4" | grep -oE "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$")
if [ -z "$IP" ]; then
  printf 'Error! "%s" is not a valid IPv4 address\n' "$IPv4"
  exit 1
fi

if [ -s "/opt/var/log/dnsmasq.log" ]; then
  printf '\nPress Ctrl-C to stop logging\n'
  tail -f /opt/var/log/dnsmasq.log >${OUTPUT_FILE}_tmp
fi
