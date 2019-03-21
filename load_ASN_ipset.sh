#!/bin/sh
####################################################################################################
# Script: load_ASN_ipsets.sh
# Version 1.0
# Author: Xentrk
# Date: 15-March-2019
#
# Description:
#   Selective Routing Script for Hulu
#
# Grateful:
#   Thank you to @Martineau on snbforums.com for sharing his Selective Routing expertise
#   and on-going support!
#
####################################################################################################
logger -t "($(basename "$0"))" $$ Starting Script Execution
# Uncomment the line below for debugging
set -x

IPSET_NAME="$1"
ASN="$2"
NUMBER="$(echo $ASN | sed 's/^AS//')"
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

#Download ASN ipset list

download_ASN_ipset_list () {

    ASN=$1
    NUMBER=$2

    curl https://ipinfo.io/"$ASN" 2>/dev/null | grep -E "a href.*$NUMBER\/" | grep -v ":" | sed 's|^.*<a href="/'"$ASN"'/||' | sed 's|" >||' > "$FILE_DIR/$IPSET_NAME"

    if [ "$?" = "1" ]; then  # file download failed
        logger -t "($(basename "$0"))" $$ Script execution failed because $ASN file could not be downloaded
    exit 1
    fi
}

# Create IPSET lists
# if ipset list does not exist, create it
check_ASN_ipset_list_exist () {

    IPSET_NAME=$1

    if [ "$(ipset list -n $IPSET_NAME 2>/dev/null)" != "$IPSET_NAME" ]; then
        ipset create "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536
    fi
}

# if ipset list x3mRouting_HULU is empty or source file is older than 24 hours, download source file; load ipset list

check_ASN_ipset_list_values () {

IPSET_NAME=$1
ASN=$2
NUMBER=$3

    if [ "$(ipset -L "$IPSET_NAME" 2>/dev/null | awk '{ if (FNR == 7) print $0 }' | awk '{print $4 }')" -eq "0" ]; then
        if [ ! -s "$FILE_DIR/$IPSET_NAME" ] || [ "$(find "$FILE_DIR" -name $IPSET_NAME -mtime +1 -print)" = "$FILE_DIR/$IPSET_NAME" ]; then
            download_ASN_ipset_list $ASN $NUMBER
        fi
        COMMAND="add $IPSET_NAME"
        awk '{print "add '"$IPSET_NAME"' " $1}' "$FILE_DIR/$IPSET_NAME" | ipset restore -!
    else
        if [ ! -s "$FILE_DIR/$IPSET_NAME" ]; then
            download_ASN_ipset_list $ASN $NUMBER
        fi
    fi
}

Chk_Entware 30

check_ASN_ipset_list_exist $IPSET_NAME
check_ASN_ipset_list_values $IPSET_NAME $ASN $NUMBER

logger -t "($(basename "$0"))" $$ Ending Script Execution
