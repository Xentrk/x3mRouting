#!/bin/sh
####################################################################################################
# Script: load_AMAZON_ipset.sh
# Version 1.0
# Author: Xentrk
# Date: 15-March-2019
#
# Grateful:
#
# Thank you to @Martineau on snbforums.com for educating myself and others on Selective
# Routing techniques using Asuswrt-Merlin firmware.
#
#####################################################################################################
# Script Description:
#
# Selectively route Netflix and AmazonAWS US traffic to an OpenVPN Client interface on AsusWRT-Merlin firmware
# Netflix also hosts on Amazon AWS servers. Because of this, the script will also route Amazon AWS
# traffic, including Amazon and Amazon Prime traffic, to the OpenVPN interface.
#
#####################################################################################################
logger -t "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging
set -x

FILE_DIR="/opt/tmp"

# Chk_Entware function provided by @Martineau at snbforums.com

Chk_Entware () {

    # ARGS [wait attempts] [specific_entware_utility]

    READY=1                   # Assume Entware Utilities are NOT available
    ENTWARE="opkg"
    ENTWARE_UTILITY=                # Specific Entware utility to search for
    MAX_TRIES=30

    if [ ! -z "$2" ] && [ ! -z "$(echo "$2" | grep -E '^[0-9]+$')" ];then
        MAX_TRIES=$2
    fi

    if [ ! -z "$1" ] && [ -z "$(echo "$1" | grep -E '^[0-9]+$')" ];then
        ENTWARE_UTILITY=$1
    else
        if [ -z "$2" ] && [ ! -z "$(echo "$1" | grep -E '^[0-9]+$')" ];then
            MAX_TRIES=$1
        fi
    fi

   # Wait up to (default) 30 seconds to see if Entware utilities available.....
   TRIES=0

   while [ "$TRIES" -lt "$MAX_TRIES" ];do
      if [ ! -z "$(which $ENTWARE)" ] && [ "$($ENTWARE -v | grep -o "version")" = "version" ];then
         if [ ! -z "$ENTWARE_UTILITY" ];then            # Specific Entware utility installed?
            if [ ! -z "$("$ENTWARE" list-installed "$ENTWARE_UTILITY")" ];then
                READY=0                                 # Specific Entware utility found
            else
                # Not all Entware utilities exists as a stand-alone package e.g. 'find' is in package 'findutils'
                if [ -d /opt ] && [ ! -z "$(find /opt/ -name "$ENTWARE_UTILITY")" ];then
                  READY=0                               # Specific Entware utility found
                fi
            fi
         else
            READY=0                                     # Entware utilities ready
         fi
         break
      fi
      sleep 1
      logger -st "($(basename "$0"))" $$ "Entware" "$ENTWARE_UTILITY" "not available - wait time" $((MAX_TRIES - TRIES-1))" secs left"
      TRIES=$((TRIES + 1))
   done

   return $READY
}

# Download Amazon AWS json file
download_AMAZON () {
    wget https://ip-ranges.amazonaws.com/ip-ranges.json -O "$FILE_DIR/ip-ranges.json"
    if [ "$?" = "1" ]; then  # file download failed
        logger -t "($(basename "$0"))" $$ Script execution failed because https://ip-ranges.amazonaws.com/ip-ranges.json file could not be downloaded
        exit 1
    fi
    true > "$FILE_DIR/AMAZON"
    for REGION in us-east-1 us-east-2 us-west-1 us-west-2
        do
            jq '.prefixes[] | select(.region=='\"$REGION\"') | .ip_prefix' < "$FILE_DIR/ip-ranges.json" | sed 's/"//g' | sort -u >> "$FILE_DIR/AMAZON"
        done
}

# if ipset AMAZON does not exist, create it

check_ipset_list_exist_AMAZON () {
    if [ "$(ipset list -n AMAZON 2>/dev/null)" != "AMAZON" ]; then
        ipset create AMAZON hash:net family inet hashsize 1024 maxelem 65536
    fi
}

# if ipset list AMAZON is empty or source file is older than 7 days, download source file; load ipset list

check_ipset_list_values_AMAZON () {
    if [ "$(ipset -L AMAZON 2>/dev/null | awk '{ if (FNR == 7) print $0 }' | awk '{print $4 }')" -eq "0" ]; then
        if [ ! -s "$FILE_DIR/AMAZON" ] || [ "$(find "$FILE_DIR" -name AMAZON -mtime +7 -print)" = "$FILE_DIR/AMAZON" ]; then
            download_AMAZON
        fi
        awk '{print "add AMAZON " $1}' "$FILE_DIR/AMAZON" | ipset restore -!
    else
        if [ ! -s "$FILE_DIR/AMAZON" ]; then
            download_AMAZON
        fi
    fi
}

# Call functions below this line

Chk_Entware 30 jq

check_ipset_list_exist_AMAZON
check_ipset_list_values_AMAZON

logger -t "($(basename "$0"))" $$ Completed Script Execution
