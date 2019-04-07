#!/bin/sh
####################################################################################################
# Script: x3mRouting_rules.sh
# VERSION=1.0.0
# Author: Xentrk
# 29-July-2018
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
logger -t "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging
set -x

VERSION="1.0"
GITHUB_URL="https://github.com/Xentrk/Asuswrt-Merlin-Selective-Routing"
GIT_REPO="Asuswrt-Merlin-Selective-Routing"
COLOR_WHITE='\033[0m'
COLOR_GREEN='\e[0;32m'

printf '\n'
printf '#############################################################################################################\n'
printf '##                                                                                                         ##\n'
printf '##  Welcome to the %bAsuswrt-Merlin-Selective-Routing%b configuration script                                   ##\n' "$COLOR_GREEN" "$COLOR_WHITE"
printf '##  Version %s by Xentrk                                                                                  ##\n' "$VERSION"
printf '##                                                                                                         ##\n'
printf '##  Configuration instuctions available at %b%s%b      ##\n' "$COLOR_GREEN" "$GITHUB_URL" "$COLOR_WHITE"
printf '##         ____        _         _                                                                         ##\n'
printf '##        |__  |      | |       | |                                                                        ##\n'
printf '##  __  __  _| |_ _ _ | |_  ___ | | __    ____ ____  _ _ _                                                 ##\n'
printf '##  \ \/ / |_  | %b %b \  __|/ _ \| |/ /   /  _//    \| %b %b \                                                ##\n' "\`" "\`" "\`" "\`"
printf '##   /  /  __| | | | |  |_ | __/|   <   (  (_ | [] || | | |                                                ##\n'
printf '##  /_/\_\|___ |_|_|_|\___|\___||_|\_\[] \___\\\____/|_|_|_|                                                ##\n'
printf '##                                                                                                         ##\n'
printf '#############################################################################################################\n'
printf '\n'

# Retrieve Static DHCP assignments; remove < and > symbols and separate fields with a space.
nvram get dhcp_staticlist | sed 's/<//;s/>/ /g;s/</ /g' >/tmp/my-scripts.$$

# count number of fields in the file
word_count=$(head -1 /tmp/my-scripts.$$ | wc -w)

# count number of static leases. This is the number of loops required to get IP address and client name
# divide word_count by 3 since client information is listed in groups of 3 fields: MAC_Address, IP_Address and Client_Name
static_leases_count=$((word_count / 3))

# Check to see if a prior x3mRouting_rules file exists. Make a backup if it does.
if [ -s "/jffs/configs/x3mRouting_rules" ]; then
  TIMESTAMP=$(date +"%Y-%m-%d-%H.%M.%S")
  if ! mv /jffs/configs/x3mRouting_rules /jffs/configs/x3mRouting_rules."$TIMESTAMP"; then
    printf '\nBackup of the prior %b/jffs/configs/x3mRouting_rules%b file could not be made\n' "$COLOR_GREEN" "$COLOR_WHITE"
  else
    printf '\nExisting %b/jffs/configs/x3mRouting_rules%b file found.  A backup of the existing %b/jffs/configs/x3mRouting_rules%b file was made\n' "$COLOR_GREEN" "$COLOR_WHITE" "$COLOR_GREEN" "$COLOR_WHITE"
  fi
fi

#Write IP address and Client Name to lan_clients
loop_count=1
IP=2
CLIENT=3

# write a new x3mRouting_rules file
true > /jffs/configs/x3mRouting_rules

# write Static DHCP LAN Clients to /jffs/scripts/x3mRouting_rules
while [ "$loop_count" -le "$static_leases_count" ]; do
  cut -d' ' -f$IP,$CLIENT </tmp/my-scripts.$$ >>/jffs/configs/x3mRouting_rules
  IP=$((IP + 3))
  CLIENT=$((CLIENT + 3))
  loop_count=$((loop_count + 1))
done

sort /jffs/configs/x3mRouting_rules -o /jffs/configs/x3mRouting_rules

rm /tmp/my-scripts.$$

# Default all lan clients to OVPNC1 interface
sed -i -e 's/^/1 /' /jffs/configs/x3mRouting_rules

# Add instructions at the top of the file
sed -i '1s/^/#########################################################\n/' /jffs/configs/x3mRouting_rules
sed -i '1s/^/# 5 = OVPNC5                                            #\n/' /jffs/configs/x3mRouting_rules
sed -i '1s/^/# 4 = OVPNC4                                            #\n/' /jffs/configs/x3mRouting_rules
sed -i '1s/^/# 3 = OVPNC3                                            #\n/' /jffs/configs/x3mRouting_rules
sed -i '1s/^/# 2 = OVPNC2                                            #\n/' /jffs/configs/x3mRouting_rules
sed -i '1s/^/# 1 = OVPNC1                                            #\n/' /jffs/configs/x3mRouting_rules
sed -i '1s/^/# 0 = WAN                                               #\n/' /jffs/configs/x3mRouting_rules
sed -i '1s/^/# the appropriate interface number in the first column  #\n/' /jffs/configs/x3mRouting_rules
sed -i '1s/^/# Assign the interface for each LAN client by entering  #\n/' /jffs/configs/x3mRouting_rules
sed -i '1s/^/#########################################################\n/' /jffs/configs/x3mRouting_rules

printf '\nYou must now edit %b/jffs/configs/x3mRouting_rules%b and assign the interface for each LAN client\n' "$COLOR_GREEN" "$COLOR_WHITE"
printf '\n'

logger -t "($(basename "$0"))" $$ Ending Script Execution
