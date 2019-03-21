#!/bin/sh
####################################################################################################
# Script: load_DNSMASQ_ipset.sh
# Version 1.3
# Author: Xentrk
# Date: 7-September-2018
#       22-October-2018        v1.1 Modified by Martineau to be generic rather than Netflix specific.
#       24-October-2018        v1.2 Modified by Martineau Added 'dir=' to allow using custom directory rather than Entware's '/opt/tmp' directory for ipset save/rstore
#       10-December-2018       v1.3 Modified by Martineau Added 'autoscan[{=}[logfile]]' option to extract domains from logfile or '/opt/var/log/dnsmasq.log' if 'autoscan=' used
#
# Description:
#    Selective Routing Script for domains using Asuswrt-Merlin firmware.  This version uses the ipset method
#    built into dnsmasq.
#
#
# Usage:     IPSET_Domains.sh   {[0|1|2|3|4|5]  ipset_name  domains[,...]} ['autoscan'] [del]  [dir='directory']
#
# Usage:     IPSET_Domains.sh   2   BBC   bbc.co.uk
#                               Create IPSET BBC via VPN Client 2 and autopopulate IPs for domain 'bbc.co.uk'
# Usage:     IPSET_Domains.sh   2   BBC   bbc.co.uk   del
#                               Delete IPSET BBC and remove from VPN Client 2
# Usage:     IPSET_Domains.sh   2   BBC   bbc.co.uk   dir=/mnt/sda1/Backups
#                               As per example one, but use '/mnt/sda1/Backups' rather than Entware's 'opt/tmp' for ipset save/restore
# Usage:     IPSET_Domains.sh   0   x3mRouting_NETFLIX_DNSMASQ   amazonaws.com,netflix.com,nflxext.com,nflximg.net,nflxso.net,nflxvideo.net
#                               Create IPSET x3mRouting_NETFLIX_DNSMASQ via WAN and autopopulate IPs for multiple Netflix domains
# Usage:     IPSET_Domains.sh   2 SKY sky.com autoscan
#                               Create IPSET SKY and extract all matching Top-Level domains containing 'sky.com' from '/opt/var/log/dnsmasq.log'
#                               e.g. ipset=/akadns.net/edgekey.net/edgesuite.net/epgsky.com/sky.com/SKY
#                                    from 'a674.hsar.cdn.sky.com.edgesuite.net/adm.sky.com/assets.sky.com/assets.sky.com-secure.edgekey.net/awk.epgsky.com' etc.


# Print the names of IPSETs defined in dnsmasq
#for IPSET in $(grep -E "^ipset=" /etc/dnsmasq.conf | awk -F "/" '{print $NF}');do echo $IPSET;ipset list $IPSET -t;done

# Loop through all of the domains and perform 'nslookup'
#for DOMAIN in $(grep -E "^ipset=" /etc/dnsmasq.conf | sed 's~/~ ~g; s/ipset=//' | awk '$NF=" " {print $0}');do echo -e "\n\t\tDomain="$DOMAIN"\n";nslookup $DOMAIN;done

#
# Grateful:
#   Thank you to @Martineau on snbforums.com for sharing his Selective Routing expertise
#   and on-going support!
#
####################################################################################################
logger -st "($(basename "$0"))" $$ Starting Script Execution

# Uncomment the line below for debugging
set -x

PROGNAME=$(basename "$0")
LOCKFILE_DIR=/tmp
LOCK_FD=200

lock() {
    local prefix=$1
    local fd=${2:-$LOCK_FD}
    local lock_file=$LOCKFILE_DIR/$prefix.lock

    # create lock file
    eval "exec $fd>$lock_file"

    # acquier the lock
    flock -n "$fd" \
        && return 0 \
        || return 1
}

error_exit() {
    error_str="$@"
    logger -t "($(basename "$0"))" $$ "$error_str"
    exit 1
}

main() {
    lock "$PROGNAME" || error_exit "Exiting $PROGNAME. Only one instance of $PROGNAME can run at one time."

# Chk_Entware function provided by @Martineau at snbforums.com

Chk_Entware () {

    # ARGS [wait attempts] [specific_entware_utility]

    local READY=1                  # Assume Entware Utilities are NOT available
    local ENTWARE="opkg"
    ENTWARE_UTILITY=                # Specific Entware utility to search for (Tacky GLOBAL variable returned!)

    local MAX_TRIES=30
    if [ -n "$2" ] && [ -n "$(echo $2 | grep -E '^[0-9]+$')" ];then
        local MAX_TRIES=$2
    fi

    if [ -n "$1" ] && [ -z "$(echo $1 | grep -E '^[0-9]+$')" ];then
        ENTWARE_UTILITY=$1
    else
        if [ -z "$2" ] && [ -n "$(echo $1 | grep -E '^[0-9]+$')" ];then
            MAX_TRIES=$1
        fi
    fi

   # Wait up to (default) 30 seconds to see if Entware utilities available.....
   local TRIES=0
   while [ $TRIES -lt $MAX_TRIES ];do
      if [ -n "$(which $ENTWARE)" ] && [ "$($ENTWARE -v | grep -o "version")" == "version" ];then		# Check Entware exists and it executes OK
         if [ -n "$ENTWARE_UTILITY" ];then      								# Specific Entware utility installed?
            if [ -n "$($ENTWARE list-installed $ENTWARE_UTILITY)" ];then
                READY=0                                                         # Specific Entware utility found
            else
                # Not all Entware utilities exist as a stand-alone package e.g. 'find' is in package 'findutils'
				# 	opkg files findutils
				#
				# 	Package findutils (4.6.0-1) is installed on root and has the following files:
				# 	/opt/bin/xargs
				# 	/opt/bin/find
				# Add 'executable' as 'stubby' leaves behind two directories containing the string 'stubby'
				if [ -d /opt ] && [ -n "$(find /opt/ -type f -executable -name $ENTWARE_UTILITY)" ];then
					READY=0														# Specific Entware utility found
				fi
            fi
         else
            READY=0                                                             # Entware utilities ready
         fi
         break
      fi
      sleep 1
      logger -st "($(basename $0))" $$ "Entware" $ENTWARE_UTILITY "not available - wait time" $((MAX_TRIES - TRIES-1))" secs left"
      local TRIES=$((TRIES + 1))
   done

   return $READY
}

# check if /jffs/configs/dnsmasq.conf.add contains 'ipset=' entry for the domains
check_dnsmasq () {

    if [ -s /jffs/configs/dnsmasq.conf.add ]; then  # dnsmasq.conf.add file exists
        if [ "$(grep -c "$1" "/jffs/configs/dnsmasq.conf.add")" -eq "1" ]; then  # see if line exists for $IPSET_NAME
			if [ "$2" == "del" ];then
				sed -i "/^ipset.*${IPSET_NAME}$/d" /jffs/configs/dnsmasq.conf.add
				logger -st "($(basename "$0"))" $$ "'"ipset=$1"'" deleted from "'/jffs/configs/dnsmasq.conf.add'"
			fi
		else
			printf "ipset=$1\n" >> /jffs/configs/dnsmasq.conf.add # add 'ipset=' domains entry to dnsmasq.conf.add
		fi
        service restart_dnsmasq > /dev/null 2>&1
    else
		if [ "$2" != "del" ];then
			printf "ipset=$1\n" > /jffs/configs/dnsmasq.conf.add # dnsmasq.conf.add does not exist, create dnsmasq.conf.add
			logger -st "($(basename "$0"))" $$ "'"ipset=$1"'" added to "'/jffs/configs/dnsmasq.conf.add'"
			service restart_dnsmasq > /dev/null 2>&1
		fi
    fi
}

check_ipset_list () {
	if [ "$2" != "del" ];then
		if [ "$(ipset list -n $1 2>/dev/null)" != "$1" ]; then #does ipset list exist?
			if [ -s "$DIR/$1" ]; then # does $1 ipset restore file exist?
				ipset restore -! < "$DIR/$1"   # Restore ipset list if restore file exists at $DIR/$1
				logger -st "($(basename "$0"))" $$ IPSET restored: $1 from "'$DIR/$1'"
			else
				ipset create $1 hash:net family inet hashsize 1024 maxelem 65536  # No restore file, so create $1 ipset list from scratch
				logger -st "($(basename "$0"))" $$ IPSET created: $1 hash:net family inet hashsize 1024 maxelem 65536
			fi
		fi
	else
		if [ "$(ipset list -n $1 2>/dev/null)" == "$1" ]; then
			ipset destroy $1
			logger -st "($(basename "$0"))" $$ IPSET $1 deleted!
		fi
	fi
}

# if IPSET is older than 24 hours, save the current IPSET list to disk
check_restore_file_age () {
    if [ -s "$DIR" ]; then
        if [ "$(find $DIR -name $1 -mtime +1 -print 2&>/dev/null )" = "$DIR/$1" ] ; then
            ipset save $1 > "$DIR/$1"
        fi
    fi
}

# If cronjob to back up the DOMAINS ipset list every 24 hours @ 2:00 AM does not exist, then create it
check_cron_job () {
    #cru l | grep $1_ipset_list
	cru l | grep $1	2&>/dev/null						# Martineau Fix
    if [ "$?" = "1" ]; then  # no cronjob entry found, create it
		if [ "$2" != "del" ];then
			cru a $1 "0 2 * * * ipset save $1 > $DIR/$1"
			logger -st "($(basename "$0"))" $$ CRON schedule created: "#"$1"#" "'0 2 * * * ipset save $1'"
		fi
	else
		if [ "$2" == "del" ];then
			cru d $1 "0 2 * * * ipset save $1"
			logger -st "($(basename "$0"))" $$ CRON schedule deleted: "#"$1"#" "'0 2 * * * ipset save $1'"
		fi
    fi
}

#==================================================================================================Martineau Hack
IPSET_NAME=
DOMAINS_LIST=
DIR="/opt/tmp"


AUTOSCAN=															# v1.3
if [ "$(echo "$@" | grep -c 'autoscan')" -gt 0 ];then
	AUTOSCAN=$(echo "$@" | sed -n "s/^.*autoscan=//p" | awk '{print $1}')
	[ -z "$AUTOSCAN" ] && AUTOSCAN="/opt/var/log/dnsmasq.log"
	if [ -n "$AUTOSCAN" ];then
		if [ ! -f "$AUTOSCAN" ];then
			logger -st "($(basename "$0"))" $$ "ERROR 'autoscan=$AUTOSCAN' file NOT found!"
			exit 99
		fi
	fi
fi

#if [ ! -z "$1" ];then
#	VPNID=$1
#else
#	logger -st "($(basename "$0"))" $$ Warning missing arg1 "'destination_target' 0-WAN or 1-5=VPN," WAN assumed!
#fi
if [ -n "$1" ];then
	IPSET_NAME=$1
else
	logger -st "($(basename "$0"))" $$ ERROR missing arg2 "'ipset_name'"
	exit 97
fi
if [ -n "$2" ] && [ -z "$AUTOSCAN" ];then								# v1.3
	DOMAINS_LIST="$2"
else
	if [ -z "$AUTOSCAN" ];then								# v1.3
		logger -st "($(basename "$0"))" $$ ERROR missing arg3 "'domain_list'"
		exit 98
	else
		DOMAIN=$2
		# So having extracted the matching domains						# v1.3
		# Extract only the two-part TL domain i.e. disregard the sub-domains
		DOMAINS_LIST=$(grep $DOMAIN $AUTOSCAN | grep reply | awk '{print $(NF-2)}' | awk -F\. '{print $(NF-1) FS $NF}' | sort | uniq | tr '\n' ',')
	fi
fi

if [ "$(echo "$@" | grep -c 'dir=')" -gt 0 ];then
	DIR=$(echo "$@" | sed -n "s/^.*dir=//p" | awk '{print $1}')	# v1.2 Mount point/directory for backups
fi

if [ -z "$IPSET_NAME" ] || [ -z "$DOMAINS_LIST" ];then
	logger -st "($(basename "$0"))" $$ ERROR missing args "'target destination' 'ipset_name' 'domain_list'"
	exit 98
fi

DOMAINS_LIST=$(echo "$DOMAINS_LIST" | sed 's/,$//' | tr ',' '/')	# v1.3
DNSMASQ_ENTRY="/"${DOMAINS_LIST}"/"${IPSET_NAME}

# Delete mode?
if [ "$(echo $@ | grep -cw 'del')" -gt 0 ];then
	check_dnsmasq			"$DNSMASQ_ENTRY"	"del"
	check_cron_job			"$IPSET_NAME"		"del"
	check_ipset_list		"$IPSET_NAME"		"del"
else
#==================================================================================================
	Chk_Entware
	check_dnsmasq 			"$DNSMASQ_ENTRY"			# Martineau Hack
	check_ipset_list		"$IPSET_NAME"				# Martineau Hack
	check_restore_file_age	"$IPSET_NAME"				# Martineau Hack
	check_cron_job			"$IPSET_NAME"				# Martineau Hack
fi
logger -st "($(basename "$0"))" $$ Completed Script Execution

}
main "$@"											# Martineau Hack
