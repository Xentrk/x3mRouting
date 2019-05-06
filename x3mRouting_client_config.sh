#!/bin/sh
####################################################################################################
# Script: x3mRouting_client_config.sh
# VERSION=1.0.0
# Author: Xentrk
# 21-April-2019
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

# Retrieve Static DHCP assignments; remove < and > symbols and separate fields with a space.
nvram get dhcp_staticlist | sed 's/<//;s/>/ /g;s/</ /g' >/tmp/my-scripts.$$

# count number of fields in the file
word_count=$(head -1 /tmp/my-scripts.$$ | wc -w)

# count number of static leases. This is the number of loops required to get IP address and client name
# divide word_count by 3 since client information is listed in groups of 3 fields: MAC_Address, IP_Address and Client_Name
static_leases_count=$((word_count / 3))

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

#Write IP address and Client Name to lan_clients
loop_count=1
IP=2
CLIENT=3

# write a new x3mRouting_rules file
true >"$CONFIG_FILE"

# write Static DHCP LAN Clients to /jffs/scripts/x3mRouting_rules
while [ "$loop_count" -le "$static_leases_count" ]; do
  cut -d' ' -f"$IP","$CLIENT" </tmp/my-scripts.$$ >>"$CONFIG_FILE"
  IP=$((IP + 3))
  CLIENT=$((CLIENT + 3))
  loop_count=$((loop_count + 1))
done

sort "$CONFIG_FILE" -o "$CONFIG_FILE"

rm -rf /tmp/my-scripts.$$

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
