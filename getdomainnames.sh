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
#  1. Navigate to the log file directory /opt/var/log
#  2. Enter the command: tail -f dnsmasq.log > myfile
#  3. Access the streaming service and watch some videos for a few seconds and select each menu option to generate
#     domain names.
#  4. Type 'Ctrl-C' to exit
#  5. Navigate to /jffs/scripts
#  6. Run getdomainnames.sh
#  7. The domains collected will be stored in /opt/var/log/ directory using the same name as the output file
#     with '_domains' concatenated at the end of the file name (e.g myfile_domains)
#
# Parameters Passed
# $1 = provide the name of the source file when running the script
# $2 = IPv4 address of client device that was used to query domains
# Usage Example:
#   sh getdomainnames.sh myfile 192.168.1.50
#_______________________________________________________________________________________________________________

# Print between line beginning with '#_' to first blank line inclusive
ShowHelp() {
  awk '/^#__/{f=1} f{print; if (!NF) exit}' "$0" | more
}

cleanup()
{
  echo "Done capturing domains from dnsmasq.log"
  echo "Sorting file."
  true >"$OUTPUT_FILE"
  grep "$IPv4" "${OUTPUT_FILE}_tmp" | grep "query" | awk '{ print $6 }' | sort -u >>"$OUTPUT_FILE"
  printf '%s\n%s' "File contents are:" "$(cat "$OUTPUT_FILE")"
  printf '%s\n' "File location is: $OUTPUT_FILE"
  exit 0
}

# Need assistance!???
if [ "$1" = "help" ] || [ "$1" = "-h" ]; then
  ShowHelp
  exit 0
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
  printf '\nPress the Enter key to stop logging\n'
    tail -f /opt/var/log/dnsmasq.log > ${OUTPUT_FILE}_tmp
else
  printf '\nError /opt/var/log/dnsmasq.log file does not exist\n'
  exit 0
fi
