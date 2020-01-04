#!/bin/sh
####################################################################################################
# Script: x3mRouting_client_config.sh
# VERSION=1.0.4
# Author: Xentrk
# 4-January-2019
#
#####################################################################################################
# Description:
#
# Create the file /jffs/configs/x3mRouting_rules.  The file contains a separate line for each for each LAN
# client with a static IP assignment.  Each record contains three fields separated by a space.  The first
# field is number representing the interface assignment, followed by the LAN client IP address and
# description.  By default, each LAN client is assigned to the OVPNC1 interface.  The user must edit
# /jffs/configs/x3mRouting_rules and assign the interface for each LAN client after running the script.  If
# an existing /jffs/configs/x3mRouting_rules file exists, a backup copy of the existing x3mRouting_rules file will be
# made by appending the timestamp to the existing /jffs/configs/x3mRouting_rules file.
#
#####################################################################################################
logger -st "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging
#set -x

VERSION="1.0.0"
GITHUB_URL="https://github.com/Xentrk/x3mRouting"
CONFIG_FILE="/jffs/configs/x3mRouting_client_rules"
COLOR_WHITE='\033[0m'
COLOR_GREEN='\e[0;32m'

printf '\n'
printf '_______________________________________________________________\n'
printf '|                                                             |\n'
printf '|  Welcome to the %bx3mRouting%b LAN Client Configuration Script  |\n' "$COLOR_GREEN" "$COLOR_WHITE"
printf '|  Version %b%s%b by Xentrk                                    |\n' "$COLOR_GREEN" "$VERSION" "$COLOR_WHITE"
printf '|                                                             |\n'
printf '|           Configuration instuctions available at            |\n'
printf '|            %b%s%b             |\n' "$COLOR_GREEN" "$GITHUB_URL" "$COLOR_WHITE"
printf '|         ____        _         _                             |\n'
printf '|        |__  |      | |       | |                            |\n'
printf '|  __  __  _| |_ _ _ | |_  ___ | | __    ____ ____  _ _ _     |\n'
printf '|  \ \/ / |_  | %b %b \  __|/ _ \| |/ /   /  _//    \| %b %b \    |\n' "\`" "\`" "\`" "\`"
printf '|   /  /  __| | | | |  |_ | __/|   <   (  (_ | [] || | | |    |\n'
printf '|  /_/\_\|___ |_|_|_|\___|\___||_|\_\[] \___\\\____/|_|_|_|    |\n'
printf '|                                                             |\n'
printf '|_____________________________________________________________|\n\n'

Parse_Hostnames() {

  true >/tmp/hostnames.$$
  OLDIFS=$IFS
  IFS="<"

  for ENTRY in $HOSTNAME_LIST; do
    if [ "$ENTRY" = "" ]; then
      continue
    fi
    MACID=$(echo "$ENTRY" | cut -d ">" -f 1)
    HOSTNAME=$(echo "$ENTRY" | cut -d ">" -f 2)
    echo "$MACID $HOSTNAME" >>/tmp/hostnames.$$
  done

  IFS=$OLDIFS
}

Save_MacIpHostname_Format() {

  # Obtain MAC and IP address from dhcp_staticlist and exclude DNS field by filtering using the first three octets of the lan_ipaddr
  if [ -s /jffs/nvram/dhcp_staticlist ]; then #HND Routers store dhcp_staticlist in a file
    awk '{print $0}' /jffs/nvram/dhcp_staticlist | grep -oE "((([0-9a-fA-F]{2})[ :-]){5}[0-9a-fA-F]{2})|(([0-9a-fA-F]){6}[:-]([0-9a-fA-F]){6})|([0-9a-fA-F]{12})" >/tmp/static_mac.$$
    awk '{print $0}' /jffs/nvram/dhcp_staticlist | grep -oE "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" | grep "$(nvram get lan_ipaddr | grep -Eo '([0-9]{1,3}\.[0-9]{1,3}(\.[0-9]{1,3}))')" >/tmp/static_ip.$$
  else # non-HND Routers store dhcp_staticlist in nvram
    nvram get dhcp_staticlist | grep -oE "((([0-9a-fA-F]{2})[ :-]){5}[0-9a-fA-F]{2})|(([0-9a-fA-F]){6}[:-]([0-9a-fA-F]){6})|([0-9a-fA-F]{12})" >/tmp/static_mac.$$
    nvram get dhcp_staticlist | grep -oE "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" | grep "$(nvram get lan_ipaddr | grep -Eo '([0-9]{1,3}\.[0-9]{1,3}(\.[0-9]{1,3}))')" >/tmp/static_ip.$$
  fi

  # output /tmp/static_mac.$$ and /tmp/static_ip.$$ to /tmp/staticlist.$$ in two columns side by side
  #https://www.unix.com/shell-programming-and-scripting/161826-how-combine-2-files-into-1-file-2-columns.html
  awk 'NR==FNR{a[i++]=$0};{b[x++]=$0;};{k=x-i};END{for(j=0;j<i;) print a[j++],b[k++]}' /tmp/static_mac.$$ /tmp/static_ip.$$ >/tmp/staticlist.$$

  if [ -s /jffs/nvram/dhcp_hostnames ]; then #HND Routers store hostnames in a file
    HOSTNAME_LIST=$(awk '{print $0}' /jffs/nvram/dhcp_hostnames | sed 's/>undefined//')
  else
    HOSTNAME_LIST=$(nvram get dhcp_hostnames | sed 's/>undefined//')
  fi

  # Have to parse by internal field separator since hostnames are not required
  Parse_Hostnames

  # Join the /tmp/hostnames.$$ and /tmp/staticlist.$$ files together to form one file containing MAC, IP, HOSTNAME
  awk '
    NR==FNR { k[$1]=$2; next }
    { print $0, k[$1] }
  ' /tmp/hostnames.$$ /tmp/staticlist.$$ >/tmp/MACIPHOSTNAMES.$$
}

# Check to see if a prior x3mRouting_rules file exists. Make a backup if it does.
if [ -s "$CONFIG_FILE" ]; then
  TIMESTAMP=$(date +"%Y-%m-%d-%H.%M.%S")
  if ! mv "$CONFIG_FILE" "$CONFIG_FILE"."$TIMESTAMP"; then
    printf '\nBackup of the prior %b%s%b file could not be made.\n' "$COLOR_GREEN" "$CONFIG_FILE" "$COLOR_WHITE"
  else
    printf '\nExisting %b%s%b file found.\n' "$COLOR_GREEN" "$CONFIG_FILE" "$COLOR_WHITE"
    printf 'A backup of the existing file was made.\n'
  fi
fi

Save_MacIpHostname_Format

# write a new x3mRouting_rules file
true >"$CONFIG_FILE"

# write IP and HOSTNAME for Static DHCP LAN Clients to $CONFIG_FILE
while read -r MAC IP HOSTNAME; do
  echo "$IP $HOSTNAME" >>$CONFIG_FILE
done </tmp/MACIPHOSTNAMES.$$

sort "$CONFIG_FILE" -o "$CONFIG_FILE"

rm -rf /tmp/static_mac.$$
rm -rf /tmp/static_ip.$$
rm -rf /tmp/staticlist.$$
rm -rf /tmp/hostnames.$$
rm -rf /tmp/MACIPHOSTNAMES.$$

# Default all lan clients to OVPNC1 interface
sed -i -e 's/^/1 /' "$CONFIG_FILE"

# Add instructions at the top of the file
sed -i '1s/^/#########################################################\n/' "$CONFIG_FILE"
sed -i '1s/^/# 5 = OVPNC5                                            #\n/' "$CONFIG_FILE"
sed -i '1s/^/# 4 = OVPNC4                                            #\n/' "$CONFIG_FILE"
sed -i '1s/^/# 3 = OVPNC3                                            #\n/' "$CONFIG_FILE"
sed -i '1s/^/# 2 = OVPNC2                                            #\n/' "$CONFIG_FILE"
sed -i '1s/^/# 1 = OVPNC1                                            #\n/' "$CONFIG_FILE"
sed -i '1s/^/# 0 = WAN                                               #\n/' "$CONFIG_FILE"
sed -i '1s/^/# the appropriate interface number in the first column  #\n/' "$CONFIG_FILE"
sed -i '1s/^/# Assign the interface for each LAN client by entering  #\n/' "$CONFIG_FILE"
sed -i '1s/^/#########################################################\n/' "$CONFIG_FILE"

printf '\nYou must now edit %b%s%b and\n' "$COLOR_GREEN" "$CONFIG_FILE" "$COLOR_WHITE"
printf 'assign the interface for each LAN client.\n'
printf '\n'

logger -st "($(basename "$0"))" $$ Ending Script Execution
