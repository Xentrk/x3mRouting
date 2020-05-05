#!/bin/sh
# shellcheck disable=SC2031 # IPSET_NAME was modified in a subshell. That change might be lost.
# shellcheck disable=SC2068 # Double quote array expansions to avoid re-splitting elements.
# shellcheck disable=SC2030 # Modification of IPSET_NAME is local (to subshell caused by pipeline).
####################################################################################################
# Script: x3mRouting.sh
# VERSION=2.0.0
# Author: Xentrk
# Date: 5-May-2020
#
# Grateful:
#   Thank you to @Martineau on snbforums.com for sharing his Selective Routing expertise,
#   on-going support and collaboration on this project!
#
#   Chk_Entware function and code to process the passing of parms written by Martineau
#
####################################################################################################
#_____________________________________________________________________________________________________________
#
# Required parameters are listed inside the braces: { }
# Optional parameters are listed inside of the brackets [ ]
# Valid parameter values are listed in parenthesis ( )
#
# Create IPSET List with Routing Rules:
#
# x3mRouting.sh {src iface} (ALL|1|2|3|4|5)
#               {dst iface} (0|1|2|3|4|5)
#               ** src/dst NOTES Start **
#                 Valid SRC and DST Combinations
#                 1) VPN Client Routing
#                    - Use this SRC and DST combination to route all IPSET list traffic to a VPN Client:
#                      ALL 1, ALL 2, ALL 3, ALL 4, ALL 5
#                 2) VPN Bypass Routing
#                    - Use this SRC and DST combination to bypass the VPN Client for an IPSET list and
#                      route to the WAN interface:
#                      1 0, 2 0, 3 0, 4 0, 5 0
#               ** src/dst NOTES End **
#               {ipset_name}
#               ['autoscan='keyword1[,keyword2]...] # Scans for keywords and creates IPSET list using
# 	                                            # the dnsmasq method
#               ['asnum='asnum[,asnum]...] # ASN method
#               ['aws_region='US[,EU]...]  # Amazon method
#               ['dnsmasq='domain[,domain]...] # dnsmasq method
#               ['ip='ip[,ip][,cidr]...] # Equivalent to manual method
#               ['src='src_ip]
#               ['src_range='from_ip-to_ip]
#               ['dir='save_restore_location] # if 'dir' not specified, defaults to /opt/tmp
#               ['del']
#_____________________________________________________________________________________________________________
#
# Create IPSET List with no Routing Rules:
#
# x3mRouting.sh	{ipset_name=}
#               ['autoscan='keyword1[,keyword2]...] # Scans for keywords and creates IPSET list using
# 	                                            # the dnsmasq method
#               ['asnum='asnum[,asnum]...] # ASN method
#               ['aws_region='US[,EU]...]  # Amazon method
#               ['dnsmasq='domain[,domain]...] # dnsmasq method
#               ['ip='ip[,ip][,cidr]...] # Equivalent to manual method
#               ['dir='save_restore_location] # if 'dir' not specified, defaults to /opt/tmp
#               ['del']
#_____________________________________________________________________________________________________________
#
# VPN Server to VPN Client Routing:
#
# x3mRouting.sh	{'server='1|2|both} {'client='1|2|3|4|5} ['del']
#_____________________________________________________________________________________________________________
#
# VPN Server to existing LAN routing rules for an IPSET list
#
# x3mRouting.sh {'server='1|2|both} {'ipset_name='} ['del']
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

Chk_Entware() {

  # ARGS [wait attempts] [specific_entware_utility]

  READY=1          # Assume Entware Utilities are NOT available
  ENTWARE_UTILITY= # Specific Entware utility to search for
  MAX_TRIES=30

  if [ -n "$2" ] && [ "$2" -eq "$2" ] 2>/dev/null; then
    MAX_TRIES="$2"
  elif [ -z "$2" ] && [ "$1" -eq "$1" ] 2>/dev/null; then
    MAX_TRIES="$1"
  fi

  if [ -n "$1" ] && ! [ "$1" -eq "$1" ] 2>/dev/null; then
    ENTWARE_UTILITY="$1"
  fi

  # Wait up to (default) 30 seconds to see if Entware utilities available.....
  TRIES="0"

  while [ "$TRIES" -lt "$MAX_TRIES" ]; do
    if [ -f "/opt/bin/opkg" ]; then
      if [ -n "$ENTWARE_UTILITY" ]; then # Specific Entware utility installed?
        if [ -n "$(opkg list-installed "$ENTWARE_UTILITY")" ]; then
          READY="0" # Specific Entware utility found
        else
          # Not all Entware utilities exists as a stand-alone package e.g. 'find' is in package 'findutils'
          if [ -d /opt ] && [ -n "$(find /opt/ -name "$ENTWARE_UTILITY")" ]; then
            READY="0" # Specific Entware utility found
          fi
        fi
      else
        READY="0" # Entware utilities ready
      fi
      break
    fi
    sleep 1
    logger -st "($(basename "$0"))" "$$ Entware $ENTWARE_UTILITY not available - wait time $((MAX_TRIES - TRIES - 1)) secs left"
    TRIES=$((TRIES + 1))
  done
  return "$READY"
}

### Define interface/bitmask to route traffic to below
Set_Fwmark_Parms() {

  FWMARK_WAN="0x8000/0x8000"
  FWMARK_OVPNC1="0x1000/0x1000"
  FWMARK_OVPNC2="0x2000/0x2000"
  FWMARK_OVPNC3="0x4000/0x4000"
  FWMARK_OVPNC4="0x7000/0x7000"
  FWMARK_OVPNC5="0x3000/0x3000"
}

Set_IP_Rule() {

  VPN_ID="$1"

  case "$VPN_ID" in
  0)
    ip rule del fwmark "$TAG_MARK" 2>/dev/null
    ip rule add from 0/0 fwmark "$TAG_MARK" table 254 prio 9990
    ip route flush cache
    ;;
  1)
    ip rule del fwmark "$TAG_MARK" 2>/dev/null
    ip rule add from 0/0 fwmark "$TAG_MARK" table 111 prio 9995
    ip route flush cache
    ;;
  2)
    ip rule del fwmark "$TAG_MARK" 2>/dev/null
    ip rule add from 0/0 fwmark "$TAG_MARK" table 112 prio 9994
    ip route flush cache
    ;;
  3)
    ip rule del fwmark "$TAG_MARK" 2>/dev/null
    ip rule add from 0/0 fwmark "$TAG_MARK" table 113 prio 9993
    ip route flush cache
    ;;
  4)
    ip rule del fwmark "$TAG_MARK" 2>/dev/null
    ip rule add from 0/0 fwmark "$TAG_MARK" table 114 prio 9992
    ip route flush cache
    ;;
  5)
    ip rule del fwmark "$TAG_MARK" 2>/dev/null
    ip rule add from 0/0 fwmark "$TAG_MARK" table 115 prio 9991
    ip route flush cache
    ;;
  *)
    Error_Exit "ERROR $1 should be 0-WAN or 1-5=VPN"
    ;;
  esac
}

# check if /jffs/configs/dnsmasq.conf.add contains 'ipset=' entry for the domains
Check_Dnsmasq() {

  DNSMASQ_ENTRY=$1

  if [ -s "/jffs/configs/dnsmasq.conf.add" ]; then # dnsmasq.conf.add file exists
    if [ "$(grep -c "$DNSMASQ_ENTRY" "/jffs/configs/dnsmasq.conf.add")" -eq "0" ]; then # only add if entry does not exist
      echo "ipset=$DNSMASQ_ENTRY" >>/jffs/configs/dnsmasq.conf.add # add 'ipset=' domains entry to dnsmasq.conf.add
      service restart_dnsmasq 2>/dev/null
    fi
  else
    printf 'ipset=%s\n' "$DNSMASQ_ENTRY" >/jffs/configs/dnsmasq.conf.add # dnsmasq.conf.add does not exist, create dnsmasq.conf.add
    logger -st "($(basename "$0"))" $$ "ipset=$DNSMASQ_ENTRY" added to "/jffs/configs/dnsmasq.conf.add"
    service restart_dnsmasq 2>/dev/null
  fi
}

Create_Ipset_List() {

  IPSET_NAME=$1
  METHOD=$2

  Chk_Entware 120
  if [ "$READY" -eq 1 ]; then Error_Exit "Entware not ready. Unable to access ipset save/restore location"; fi
  if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" != "$IPSET_NAME" ]; then #does ipset list exist?
    if [ -s "$DIR/$IPSET_NAME" ]; then # does ipset restore file exist?
      if [ "$METHOD" = "DNSMASQ" ]; then
        ipset restore -! <"$DIR/$IPSET_NAME" # Restore ipset list if restore file exists at $DIR/$1
        logger -st "($(basename "$0"))" $$ IPSET restored: "$IPSET_NAME" from "$DIR/$IPSET_NAME"
      else
        ipset create "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536
        logger -st "($(basename "$0"))" $$ IPSET restored: "$IPSET_NAME" from "$DIR/$IPSET_NAME"
      fi
    else # method = ASN, MANUAL or AWS
      ipset create "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536 # No restore file, so create $1 ipset list from scratch
      logger -st "($(basename "$0"))" $$ IPSET created: "$IPSET_NAME" hash:net family inet hashsize 1024 maxelem 65536
    fi
  fi

}

# if IPSET is older than 24 hours, save the current IPSET list to disk
Check_Restore_File_Age() {

  IPSET_NAME=$1
  DIR=$2

  if [ -d "$DIR" ]; then
    if [ "$(find "$DIR" -name "$IPSET_NAME" -mtime +1 -print 2>/dev/null)" = "$DIR/$IPSET_NAME" ]; then
      ipset save "$IPSET_NAME" >"$DIR/$IPSET_NAME"
    fi
  fi
}

# If cronjob to back up the DOMAINS ipset list every 24 hours @ 2:00 AM does not exist, then create it
Check_Cron_Job() {

  IPSET_NAME=$1

  cru l | grep "$IPSET_NAME" || cru a "$IPSET_NAME" "0 2 * * * ipset save $IPSET_NAME > $DIR/$IPSET_NAME" >/dev/null 2>&1 && logger -st "($(basename "$0"))" $$ CRON schedule created: "#$IPSET_NAME#" "'0 2 * * * ipset save $IPSET_NAME'"

}

# Route IPSET to target WAN or VPN
Create_Routing_Rules() {

  IPSET_NAME=$1

  iptables -t mangle -D PREROUTING -i br0 -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK" 2>/dev/null && logger -st "($(basename "$0"))" $$ Selective Routing Rule via "$TARGET_DESC" deleted for "$IPSET_NAME" fwmark "$TAG_MARK"
  iptables -t mangle -A PREROUTING -i br0 -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK" && logger -st "($(basename "$0"))" $$ Selective Routing Rule via "$TARGET_DESC" created for "$IPSET_NAME" fwmark "$TAG_MARK"

}

Exit_Routine() {

  logger -st "($(basename "$0"))" $$ Completed Script Execution
  exit 0
}

Error_Exit() {

  error_str="$*"
  logger -st "($(basename "$0"))" $$ "$error_str"
  exit 1
}

Check_For_Shebang() {

  CLIENTX_FILE=$1
  SHEBANG_COUNT=0
  EMPTY_LINE_COUNT=0
  NOT_EMPTY_LINE_COUNT=0

  if [ -f "$CLIENTX_FILE" ]; then # file exists
    while read -r LINE || [ -n "$LINE" ]; do
      if [ "$LINE" = "#!/bin/sh" ]; then
        SHEBANG_COUNT=$((SHEBANG_COUNT + 1))
        continue
      fi

      if [ -z "$LINE" ]; then
        EMPTY_LINE_COUNT=$((EMPTY_LINE_COUNT + 1))
      fi

      if [ -n "$LINE" ]; then
        NOT_EMPTY_LINE_COUNT=$((NOT_EMPTY_LINE_COUNT + 1))
      fi

    done <"$CLIENTX_FILE"
  else
    return
  fi

  if [ "$NOT_EMPTY_LINE_COUNT" -eq 0 ]; then
    printf '\n\n%s\n' "$CLIENTX_FILE has $SHEBANG_COUNT shebang entry and $EMPTY_LINE_COUNT empty lines."
    printf '%s\n' "Would you like to remove $TESTMYFILE?"
    printf '%b[1]%b  --> Yes\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[2]%b  --> No\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    echo
    printf '[1-2]: '
    read -r "OPTION"
    case "$OPTION" in
    1)
      rm "$CLIENTX_FILE"
      echo "file deleted"
      return
      ;;
    2)
      return
      ;;
    *)
      echo "[*] $OPTION Isn't An Option!"
      ;;
    esac
  fi

}

Check_Files_For_Entries() {

  SRC_IFACE=$1
  DST_IFACE=$2
  IPSET_NAME=$3
  OPT1=$4

  if [ -z "$OPT1" ]; then # 3 parms passed
    SCRIPT_ENTRY="sh /jffs/scripts/x3mRouting/$(basename "$0") $SRC_IFACE $DST_IFACE $IPSET_NAME"
  elif [ -n "$OPT1" ]; then # OPT1 parm passed e.g. dnsmasq=, aws_region=, asnum=, ip=
    SCRIPT_ENTRY="sh /jffs/scripts/x3mRouting/$(basename "$0") $SRC_IFACE $DST_IFACE $IPSET_NAME $OPT1"
  fi

  if [ "$SRC_IFACE" = "ALL" ]; then
    VPNID=$DST_IFACE
  else
    VPNID=$SRC_IFACE
  fi

  IPTABLES_DEL_ENTRY="iptables -t mangle -D PREROUTING -i br0 -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK 2>/dev/null"
  IPTABLES_ADD_ENTRY="iptables -t mangle -A PREROUTING -i br0 -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK"
  VPNC_UP_FILE="/jffs/scripts/x3mRouting/vpnclient${VPNID}-route-up"
  VPNC_DOWN_FILE="/jffs/scripts/x3mRouting/vpnclient${VPNID}-route-pre-down"
  NAT_START="/jffs/scripts/nat-start"

  # VPN Client route-up File
  for IPTABLES_ENTRY in "$IPTABLES_DEL_ENTRY" "$IPTABLES_ADD_ENTRY"; do
    if [ -s "$VPNC_UP_FILE" ]; then
      if [ "$(grep -c "$IPTABLES_ENTRY" "$VPNC_UP_FILE")" -eq "0" ]; then # if true, then no lines exist
        echo "$IPTABLES_ENTRY" >>"$VPNC_UP_FILE" # add $SCRIPT_ENTRY to $VPNC_UP_FILE
        logger -st "($(basename "$0"))" $$ "$IPTABLES_ENTRY added to $VPNC_UP_FILE"
      fi
    else # file does not exist, create VPNC_UP_FILE
      true >"$VPNC_UP_FILE"
      {
        printf '%s\n' "#!/bin/sh"
        printf '%s\n' "$IPTABLES_ENTRY"
      } >"$VPNC_UP_FILE"
      logger -st "($(basename "$0"))" $$ "$IPTABLES_ENTRY added to $VPNC_UP_FILE"
    fi
  done

  # VPN Client route-pre-down File
  if [ -s "$VPNC_DOWN_FILE" ]; then
    if [ "$(grep -c "$IPTABLES_DEL_ENTRY" "$VPNC_DOWN_FILE")" -eq "0" ]; then # if true, then no lines exist
      echo "$IPTABLES_DEL_ENTRY" >>"$VPNC_DOWN_FILE" # add $SCRIPT_ENTRY to $VPNC_UP_FILE
      logger -st "($(basename "$0"))" $$ "$IPTABLES_DEL_ENTRY added to $VPNC_DOWN_FILE"
    fi
  else # file does not exist, create VPNC_UP_FILE
    true >"$VPNC_DOWN_FILE"
    {
      printf '%s\n' "#!/bin/sh"
      printf '%s\n' "$IPTABLES_DEL_ENTRY"
    } >"$VPNC_DOWN_FILE"
    logger -st "($(basename "$0"))" $$ "$IPTABLES_DEL_ENTRY added to $VPNC_DOWN_FILE"
  fi

  # nat-start File
  if [ -s "$NAT_START" ]; then
    if [ "$(grep -c "$SCRIPT_ENTRY" "$NAT_START")" -eq "0" ]; then # if true, then no lines exist
      echo "$SCRIPT_ENTRY" >>"$NAT_START" # add $SCRIPT_ENTRY to $VPNC_UP_FILE
      logger -st "($(basename "$0"))" $$ "$SCRIPT_ENTRY added to $NAT_START"
    fi
  else # file does not exist, create VPNC_UP_FILE
    true >"$NAT_START"
    {
      printf '%s\n' "#!/bin/sh"
      printf '%s\n' "$SCRIPT_ENTRY"
    } >"$NAT_START"
    logger -st "($(basename "$0"))" $$ "$SCRIPT_ENTRY added to $NAT_START"
  fi

  #set permissions for each file
  [ -s "$VPNC_UP_FILE" ] && chmod 755 "$VPNC_UP_FILE"
  [ -s "$VPNC_DOWN_FILE" ] && chmod 755 "$VPNC_DOWN_FILE"
  [ -s "$NAT_START" ] && chmod 755 "$NAT_START"

}

Process_Src_Option() {

  SRC_IFACE=$1
  DST_IFACE=$2
  IPSET_NAME=$3
  OPT1=$4
  OPT2=$5
  SRC=$(echo "$@" | sed -n "s/^.*src=//p" | awk '{print $1}')
  SRC_RANGE=$(echo "$@" | sed -n "s/^.*src_range=//p" | awk '{print $1}')

  # Process when OPT1 contains 'src=' or 'src_range='
  if [ "$(echo "$OPT1" | grep -c 'src=')" -gt 0 ] || [ "$(echo "$OPT1" | grep -c 'src_range=')" -gt 0 ]; then # must be manual method
    SCRIPT_ENTRY="sh /jffs/scripts/x3mRouting/$(basename "$0") $SRC_IFACE $DST_IFACE ipset_name=$IPSET_NAME $OPT1"
    Manual_Method $@
    if [ "$(echo "$OPT1" | grep -c 'src=')" -gt 0 ]; then
      IPTABLES_DEL_ENTRY="iptables -t mangle -D PREROUTING -i br0 --src $SRC -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK 2>/dev/null"
      IPTABLES_ADD_ENTRY="iptables -t mangle -A PREROUTING -i br0 --src $SRC -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK"
      # Create routing rules
      eval "$IPTABLES_DEL_ENTRY"
      eval "$IPTABLES_ADD_ENTRY"
    else # default to src_range
      IPTABLES_DEL_ENTRY="iptables -t mangle -D PREROUTING -i br0 -m iprange --src-range $SRC_RANGE -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK 2>/dev/null"
      IPTABLES_ADD_ENTRY="iptables -t mangle -A PREROUTING -i br0 -m iprange --src-range $SRC_RANGE -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK"
      # Create routing rules
      eval "$IPTABLES_DEL_ENTRY"
      eval "$IPTABLES_ADD_ENTRY"
    fi
  fi

  # Process when OPT2 contains 'src=' or 'src_range='
  if [ "$(echo "$OPT2" | grep -c 'src=')" -gt 0 ] || [ "$(echo "$OPT2" | grep -c 'src_range=')" -gt 0 ]; then #must be asnum, amazon or dnsmasq method
    SCRIPT_ENTRY="sh /jffs/scripts/x3mRouting/$(basename "$0") $SRC_IFACE $DST_IFACE ipset_name=$IPSET_NAME $OPT1 $OPT2"
    # HANDLE Better?
    cp /jffs/scripts/x3mRouting/x3mRouting.sh /tmp/tmp_x3mRouting.sh
    sh /tmp/tmp_x3mRouting.sh ipset_name="$IPSET_NAME" "$OPT1" #this creates ipset list and gets around lock issue on current script
    rm /tmp/tmp_x3mRouting.sh
    if [ "$(echo "$OPT2" | grep -c 'src=')" -gt 0 ]; then
      IPTABLES_DEL_ENTRY="iptables -t mangle -D PREROUTING -i br0 --src $SRC -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK 2>/dev/null"
      IPTABLES_ADD_ENTRY="iptables -t mangle -A PREROUTING -i br0 --src $SRC -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK"
      # Create routing rules
      eval "$IPTABLES_DEL_ENTRY"
      eval "$IPTABLES_ADD_ENTRY"
    else # default to 'src-range'
      IPTABLES_DEL_ENTRY="iptables -t mangle -D PREROUTING -i br0 -m iprange  --src-range $SRC_RANGE -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK 2>/dev/null"
      IPTABLES_ADD_ENTRY="iptables -t mangle -A PREROUTING -i br0 -m iprange  --src-range $SRC_RANGE -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK"
      # Create routing rules
      eval "$IPTABLES_DEL_ENTRY"
      eval "$IPTABLES_ADD_ENTRY"
    fi
  fi

  if [ "$SRC_IFACE" = "ALL" ]; then
    VPNID=$DST_IFACE
  else
    VPNID=$SRC_IFACE
  fi

  VPNC_UP_FILE="/jffs/scripts/x3mRouting/vpnclient${VPNID}-route-up"
  VPNC_DOWN_FILE="/jffs/scripts/x3mRouting/vpnclient${VPNID}-route-pre-down"
  NAT_START="/jffs/scripts/nat-start"

  # nat-start File
  if [ -s "$NAT_START" ]; then
    if [ "$(grep -c "$SCRIPT_ENTRY" "$NAT_START")" -eq "0" ]; then # if true, then no lines exist
      echo "$SCRIPT_ENTRY" >>"$NAT_START" # add $SCRIPT_ENTRY to $VPNC_UP_FILE
      logger -st "($(basename "$0"))" $$ "$SCRIPT_ENTRY added to $NAT_START"
    fi
  else # file does not exist, create VPNC_UP_FILE
    true >"$NAT_START"
    {
      printf '%s\n' "#!/bin/sh"
      printf '%s\n' "$SCRIPT_ENTRY"
    } >"$NAT_START"
    logger -st "($(basename "$0"))" $$ "$SCRIPT_ENTRY added to $NAT_START"
  fi

  # VPN Client route-up File
  for IPTABLES_ENTRY in "$IPTABLES_DEL_ENTRY" "$IPTABLES_ADD_ENTRY"; do
    if [ -s "$VPNC_UP_FILE" ]; then
      if [ "$(grep -c "$IPTABLES_ENTRY" "$VPNC_UP_FILE")" -eq "0" ]; then # if true, then no lines exist
        echo "$IPTABLES_ENTRY" >>"$VPNC_UP_FILE" # add $SCRIPT_ENTRY to $VPNC_UP_FILE
        logger -st "($(basename "$0"))" $$ "$IPTABLES_ENTRY added to $VPNC_UP_FILE"
      fi
    else # file does not exist, create VPNC_UP_FILE
      true >"$VPNC_UP_FILE"
      {
        printf '%s\n' "#!/bin/sh"
        printf '%s\n' "$IPTABLES_ENTRY"
      } >"$VPNC_UP_FILE"
      logger -st "($(basename "$0"))" $$ "$IPTABLES_ENTRY added to $VPNC_UP_FILE"
    fi
  done

  # VPN Client route-pre-down File
  if [ -s "$VPNC_DOWN_FILE" ]; then # file exists
    if [ "$(grep -c "$IPTABLES_DEL_ENTRY" "$VPNC_DOWN_FILE")" -eq "0" ]; then # if true, then no lines exist
      echo "$IPTABLES_DEL_ENTRY" >>"$VPNC_DOWN_FILE" # add $SCRIPT_ENTRY to $VPNC_UP_FILE
      logger -st "($(basename "$0"))" $$ "$IPTABLES_DEL_ENTRY added to $VPNC_DOWN_FILE"
    fi
  else # file does not exist, create VPNC_UP_FILE
    true >"$VPNC_DOWN_FILE"
    {
      printf '%s\n' "#!/bin/sh"
      printf '%s\n' "$IPTABLES_DEL_ENTRY"
    } >"$VPNC_DOWN_FILE"
    logger -st "($(basename "$0"))" $$ "$IPTABLES_DEL_ENTRY added to $VPNC_DOWN_FILE"
  fi

  #set permissions for each file
  [ -s "$VPNC_UP_FILE" ] && chmod 755 "$VPNC_UP_FILE"
  [ -s "$VPNC_DOWN_FILE" ] && chmod 755 "$VPNC_DOWN_FILE"
  [ -s "$NAT_START" ] && chmod 755 "$NAT_START"

}

Process_DNSMASQ() {

  IPSET_NAME=$1
  DNSMASQ_ENTRY=$2
  DIR=$3

  Check_Dnsmasq "$DNSMASQ_ENTRY"
  Create_Ipset_List "$IPSET_NAME" "DNSMASQ"
  Check_Restore_File_Age "$IPSET_NAME" "$DIR"
  Check_Cron_Job "$IPSET_NAME"
}

Download_ASN_Ipset_List() {

  IPSET_NAME=$1
  ASN=$2
  NUMBER=$3
  DIR=$4

  if [ ! -s "$DIR/$IPSET_NAME" ]; then
    true >"$DIR/$IPSET_NAME"
  fi

  STATUS=$(curl --retry 3 -sL -o "$DIR/${IPSET_NAME}_tmp" -w '%{http_code}' https://ipinfo.io/"${ASN}")

  if [ "$STATUS" -eq 200 ]; then # curl succedded
    grep -E "a href.*$NUMBER\/" "$DIR/${IPSET_NAME}_tmp" | grep -v ":" | sed 's|^.*<a href="/'"$ASN"'/||' | sed 's|" >||' >>"$DIR/$IPSET_NAME"
    sort -gt '/' -k 1 "$DIR/$IPSET_NAME" | sort -ut '.' -k 1,1n -k 2,2n -k 3,3n -k 4,4n >"$DIR/${IPSET_NAME}_tmp"
    mv "$DIR/${IPSET_NAME}_tmp" "$DIR/$IPSET_NAME"
    awk '{print "add '"$IPSET_NAME"' " $1}' "$DIR/$IPSET_NAME" | ipset restore -!
  else
    STATUS=$(curl --retry 3 -sL -o "$DIR/${IPSET_NAME}_tmp" -w '%{http_code}' https://api.hackertarget.com/aslookup/?q="$ASN")
    if [ "$STATUS" -eq 200 ]; then
      # Curl succeded
      awk '{ print $1 }' "$DIR/${IPSET_NAME}_tmp" | grep -v "$NUMBER" >>"$DIR/$IPSET_NAME"
      sort -gt '/' -k 1 "$DIR/$IPSET_NAME" | sort -ut '.' -k 1,1n -k 2,2n -k 3,3n -k 4,4n >"$DIR/${IPSET_NAME}_tmp"
      mv "$DIR/${IPSET_NAME}_tmp" "$DIR/$IPSET_NAME"
      awk '{print "add '"$IPSET_NAME"' " $1}' "$DIR/$IPSET_NAME" | ipset restore -!
    elif [ -s "$DIR/$IPSET_NAME" ]; then
      logger -st "($(basename "$0"))" $$ "Download of ASN IPv4 addresses failed. Defaulting to current file."
      awk '{print "add '"$IPSET_NAME"' " $1}' "$DIR/$IPSET_NAME" | ipset restore -!
    else
      Error_Exit "Download of ASN IPv4 addresses failed with curl error code: $STATUS"
    fi
  fi

}

Load_MANUAL_Ipset_List() {

  IPSET_NAME=$1
  DIR=$2
  if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" = "$IPSET_NAME" ]; then #does ipset list exist?
    awk '{print "add '"$IPSET_NAME"' " $1}' "$DIR/$IPSET_NAME" | ipset restore -!
  fi
}

# Download Amazon AWS json file
Download_AMAZON() {

  DIR="$1"

  if [ -s "$DIR/ip-ranges.json" ]; then
    if [ "$(find "$DIR" -name "ip-ranges.json" -mtime +7 -print)" = "$DIR/ip-ranges.json" ]; then
      STATUS=$(curl --retry 3 -sL -o "$DIR/ip-ranges.json" -w '%{http_code}' "https://ip-ranges.amazonaws.com/ip-ranges.json")
      if [ "$STATUS" -eq 200 ]; then
        logger -st "($(basename "$0"))" $$ "Download of https://ip-ranges.amazonaws.com/ip-ranges.json successful."
      else
        logger -st "($(basename "$0"))" $$ "Download of https://ip-ranges.amazonaws.com/ip-ranges.json failed. Using existing file."
      fi
    fi
  else
    STATUS=$(curl --retry 3 -sL -o "$DIR/ip-ranges.json" -w '%{http_code}' "https://ip-ranges.amazonaws.com/ip-ranges.json")
    if [ "$STATUS" -eq 200 ]; then
      logger -st "($(basename "$0"))" $$ "Download of https://ip-ranges.amazonaws.com/ip-ranges.json successful."
    else
      Error_Exit "Download of https://ip-ranges.amazonaws.com/ip-ranges.json failed."
    fi
  fi
}

Load_AWS_Ipset_List() {
  IPSET_NAME=$1
  REGION=$2
  DIR=$3

  Download_AMAZON "$DIR"

  if [ ! -s "$DIR/$IPSET_NAME" ]; then
    true >"$DIR/$IPSET_NAME"
  fi

  # don't quote the parameter so it is treated like an array!
  for REGION in $REGION; do
    jq '.prefixes[] | select(.region=='\""$REGION"\"') | .ip_prefix' <"$DIR/ip-ranges.json" | sed 's/"//g' >>"$DIR/$IPSET_NAME"
  done
  sort -gt '/' -k 1 "$DIR/$IPSET_NAME" | sort -ut '.' -k 1,1n -k 2,2n -k 3,3n -k 4,4n >"$DIR/${IPSET_NAME}_tmp"
  mv "$DIR/${IPSET_NAME}_tmp" "$DIR/$IPSET_NAME"
  awk '{print "add '"$IPSET_NAME"' " $1}' "$DIR/$IPSET_NAME" | ipset restore -!
}

Delete_Ipset_List() {

  IPSET_NAME=$1

  # Check /jffs/configs/dnsmasq.conf.add for IPSET entry and remove if found
  if [ -s /jffs/configs/dnsmasq.conf.add ]; then
    if [ "$(grep -c "$IPSET_NAME" "/jffs/configs/dnsmasq.conf.add")" -ge "1" ]; then # if true, then one or more lines exist
      sed -i "/^ipset.*${IPSET_NAME}$/d" /jffs/configs/dnsmasq.conf.add
      logger -st "($(basename "$0"))" $$ IPSET "$IPSET_NAME deleted from /jffs/configs/dnsmasq.conf.add"
      service restart_dnsmasq 2>/dev/null
    fi
  fi

  # Check for IPSET entry in /jffs/scripts/nat-start and remove if found
  NAT_START="/jffs/scripts/nat-start"
  if [ -s "$NAT_START" ]; then
    if [ "$(grep -c "$IPSET_NAME" "$NAT_START")" -ge "1" ]; then # if true, then one or more lines exist
      sed -i "/$IPSET_NAME/d" "$NAT_START"
      logger -st "($(basename "$0"))" $$ "Script entry for $IPSET_NAME deleted from $NAT_START"
      Check_For_Shebang "$NAT_START"
    fi
  fi

  # Check_Files_For_Entriess for any entries related to IPSET_NAME
  for VPNID in 1 2 3 4 5; do
    VPNC_UP_FILE="/jffs/scripts/x3mRouting/vpnclient${VPNID}-route-up"
    VPNC_DOWN_FILE="/jffs/scripts/x3mRouting/vpnclient${VPNID}-route-pre-down"
    if [ -s "$VPNC_DOWN_FILE" ]; then # file exists
      # Note: not passing del entry
      if [ "$(grep -c "$IPSET_NAME" "$VPNC_UP_FILE")" -ge "1" ]; then # if true, then one or more lines exist
        sed -i "/$IPSET_NAME/d" "$VPNC_UP_FILE"
        logger -st "($(basename "$0"))" $$ "ipset $IPSET_NAME entry deleted from $VPNC_DOWN_FILE"
        Check_For_Shebang "$VPNC_UP_FILE"
      fi
    fi
    if [ -s "$VPNC_DOWN_FILE" ]; then # file exists
      if [ "$(grep -c "$IPSET_NAME" "$VPNC_DOWN_FILE")" -ge "1" ]; then # if true, then one or more lines exist
        sed -i "/$IPSET_NAME/d" "$VPNC_DOWN_FILE"
        logger -st "($(basename "$0"))" $$ "ipset $IPSET_NAME entry deleted from $VPNC_DOWN_FILE"
        Check_For_Shebang "$VPNC_DOWN_FILE"
      fi
    fi
  done

  #Check_Cron_Job
  if cru l | grep "$IPSET_NAME" 2>/dev/null; then
    cru d "$IPSET_NAME" "0 2 * * * ipset save $IPSET_NAME" 2>/dev/null
    logger -st "($(basename "$0"))" $$ CRON schedule deleted: "#$IPSET_NAME#" "'0 2 * * * ipset save $IPSET_NAME'"
  fi

  iptables -nvL PREROUTING -t mangle --line | grep "$IPSET_NAME" | grep "match-set" | awk '{print $1, $12}' | sort -nr | while read -r CHAIN_NUM IPSET_NAME; do
    logger -t "($(basename "$0"))" $$ "Deleting PREROUTING Chain $CHAIN_NUM for IPSET List $IPSET_NAME"
    iptables -t mangle -D PREROUTING "$CHAIN_NUM"
  done

  # Destroy the IPSET list
  if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" = "$IPSET_NAME" ]; then
    ipset destroy "$IPSET_NAME" && logger -st "($(basename "$0"))" $$ "IPSET $IPSET_NAME deleted!" || $$ "IPSET $IPSET_NAME deleted!" || Error_Exit "Error attempting to delete IPSET $IPSET_NAME!"
  fi

}

DNSMASQ_Parm() {

  DOMAINS=$(echo "$@" | sed -n "s/^.*dnsmasq=//p" | awk '{print $1}')
  DOMAINS_LIST=$(echo "$DOMAINS" | sed 's/,$//' | tr ',' '/')
  DNSMASQ_ENTRY="/$DOMAINS_LIST/$IPSET_NAME"
  Process_DNSMASQ "$IPSET_NAME" "$DNSMASQ_ENTRY" "$DIR"

}

ASNUM_Parm() {

  ASN=$(echo "$@" | sed -n "s/^.*asnum=//p" | awk '{print $1}' | tr ',' '\n')
  true >"/opt/tmp/${SCR_NAME}"
  for ASN in $ASN; do
    awk -v A="$ASN" 'BEGIN {print A}' >>"/opt/tmp/${SCR_NAME}"
    while read -r ASN; do
      PREFIX=$(printf '%-.2s' "$ASN")
      NUMBER="$(echo "$ASN" | sed 's/^AS//')"
      if [ "$PREFIX" = "AS" ]; then
        # Check for valid Number and skip if bad
        A=$(echo "$NUMBER" | grep -oE '^\-?[0-9]+$')
        if [ -z "$A" ]; then
          echo "Skipping invalid ASN: $NUMBER"
        else
          Chk_Entware 60
          Create_Ipset_List "$IPSET_NAME" "ASN"
          Download_ASN_Ipset_List "$IPSET_NAME" "$ASN" "$NUMBER" "$DIR"
        fi
      else
        Error_Exit "Invalid Prefix specified: $PREFIX. Valid value is 'AS'"
      fi
    done <"/opt/tmp/${SCR_NAME}"
  done
  rm "/opt/tmp/${SCR_NAME}"
}

AWS_Region_Parm() {

  AWS_REGION=$(echo "$@" | sed -n "s/^.*aws_region=//p" | awk '{print $1}' | tr ',' '\n')
  true >"/opt/tmp/${SCR_NAME}" # create tmp file for loop processing
  for AWS_REGION in $AWS_REGION; do
    awk -v A="$AWS_REGION" 'BEGIN {print A}' >>"/opt/tmp/${SCR_NAME}"
    while read -r AWS_REGION; do
      case "$AWS_REGION" in
      AP)
        REGION="ap-east-1 ap-northeast-1 ap-northeast-2 ap-northeast-3 ap-south-1 ap-southeast-1 ap-southeast-2"
        ;;
      CA)
        REGION="ca-central-1"
        ;;
      CN)
        REGION="cn-north-1 cn-northwest-1"
        ;;
      EU)
        REGION="eu-central-1 eu-north-1 eu-west-1 eu-west-2 eu-west-3"
        ;;
      SA)
        REGION="sa-east-1"
        ;;
      US)
        REGION="us-east-1 us-east-2 us-west-1 us-west-2"
        ;;
      GV)
        REGION="us-gov-east-1 us-gov-west-1"
        ;;
      GLOBAL)
        REGION="GLOBAL"
        ;;
      *)
        Error_Exit "Invalid AMAZON region specified: $AWS_REGION. Valid values are: AP CA CN EU SA US GV GLOBAL"
        ;;
      esac
      Create_Ipset_List "$IPSET_NAME" "AWS"
      Load_AWS_Ipset_List "$IPSET_NAME" "$REGION" "$DIR"
    done <"/opt/tmp/${SCR_NAME}"
    rm "/opt/tmp/${SCR_NAME}"
  done
}

Manual_Method() {

  Chk_Entware 60
  if [ "$READY" -eq 1 ]; then Error_Exit "Entware not ready. Unable to access ipset save/restore location"; fi
  ############## Special Processing for 'ip=' parmameter
  if [ "$(echo "$@" | grep -c 'ip=')" -gt 0 ]; then
    IP=$(echo "$@" | sed -n "s/^.*ip=//p" | awk '{print $1}')
    [ -s "$DIR/$IPSET_NAME" ] || true >"/opt/opt/tmp/$IPSET_NAME"
    true >"/opt/tmp/${SCR_NAME}" # create tmp file for loop processing
    for IPv4 in $(echo "$IP" | tr ',' '\n'); do
      awk -v A="$IPv4" 'BEGIN {print A}' >>"/opt/tmp/${SCR_NAME}"
      while read -r IPv4; do
        # check for IPv4 format
        A=$(echo "$IPv4" | grep -oE "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$")
        if [ -z "$A" ]; then # If null, then didn't pass check for IPv4 Format.
          # Check for IPv4 CIDR Format https://unix.stackexchange.com/questions/505115/regex-expression-for-ip-address-cidr-in-bash
          A=$(echo "$IPv4" | grep -oE "^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}/([0-9]|[12][0-9]|3[012])$")
          if [ -z "$A" ]; then
            printf '"%s" is not a valid CIDR address. Skipping entry.\n' "$IPv4"
          else
            printf '"%s" is a valid CIDR\n' "$IPv4"
            printf '%s\n' "$IPv4" >>"$DIR/$IPSET_NAME" #&& echo "Added IP address $IPv4"
          fi
        else
          printf '"%s" is a valid IPv4 address\n' "$IPv4"
          printf '%s\n' "$IPv4" >>"$DIR/$IPSET_NAME" #&& echo "Added IP address $IPv4"
        fi
      done <"/opt/tmp/${SCR_NAME}"
      rm "/opt/tmp/${SCR_NAME}"
      # remove any duplicate entries that may have gotten added
      sort -gt '/' -k 1 "$DIR/$IPSET_NAME" | sort -ut '.' -k 1,1n -k 2,2n -k 3,3n -k 4,4n >"$DIR/${IPSET_NAME}_tmp"
      mv "$DIR/${IPSET_NAME}_tmp" "$DIR/$IPSET_NAME"
    done
  fi
  ############## End of Special Processing for 'ip=' parameter

  Create_Ipset_List "$IPSET_NAME" "MANUAL"
  Load_MANUAL_Ipset_List "$IPSET_NAME" "$DIR"
}

VPN_Server_to_VPN_Client() {

  VPN_SERVER_INSTANCE=$1
  IFACE=$2
  VPN_CLIENT_INSTANCE=$3
  DEL_FLAG=$4
  SERVER="server=$VPN_SERVER_INSTANCE"
  CLIENT="client=$VPN_CLIENT_INSTANCE"
  SCRIPT_ENTRY="sh /jffs/scripts/x3mRouting/$(basename "$0") $SERVER $CLIENT"
  VPN_SERVER_SUBNET="$(nvram get vpn_server"${VPN_SERVER_INSTANCE}"_sn)/24"
  IPTABLES_DEL_ENTRY="iptables -t nat -D POSTROUTING -s \"\$(nvram get vpn_server${VPN_SERVER_INSTANCE}_sn)\"/24 -o $IFACE -j MASQUERADE 2>/dev/null"
  IPTABLES_ADD_ENTRY="iptables -t nat -A POSTROUTING -s \"\$(nvram get vpn_server${VPN_SERVER_INSTANCE}_sn)\"/24 -o $IFACE -j MASQUERADE"
  VPNC_UP_FILE="/jffs/scripts/x3mRouting/vpnclient${VPN_CLIENT_INSTANCE}-route-up"
  VPNC_DOWN_FILE="/jffs/scripts/x3mRouting/vpnclient${VPN_CLIENT_INSTANCE}-route-pre-down"
  NAT_START="/jffs/scripts/nat-start"
  POLICY_RULE_WITHOUT_NAME="${VPN_SERVER_SUBNET}>0.0.0.0>VPN"
  POLICY_RULE="<VPN Server ${VPN_SERVER_INSTANCE}>${VPN_SERVER_SUBNET}>0.0.0.0>VPN"

  VPN_IP_LIST=""
  for n in "" 1 2 3 4 5; do
	  VPN_IP_LIST="$VPN_IP_LIST""$(nvram get vpn_client"$VPN_CLIENT_INSTANCE"_clientlist$n)"
  done

  if [ "$DEL_FLAG" != "del" ]; then # add entry
    eval "$IPTABLES_DEL_ENTRY"
    eval "$IPTABLES_ADD_ENTRY"
    # vpnclientX-route-up File
    if [ -s "$VPNC_UP_FILE" ]; then
      #Check if an existing entry exists
      for IPTABLES_ENTRY in "$IPTABLES_DEL_ENTRY" "$IPTABLES_ADD_ENTRY"; do
        if [ "$(grep -c "$IPTABLES_ENTRY" "$VPNC_UP_FILE")" -eq "0" ]; then # if true, add entry
          echo "$IPTABLES_ENTRY" >>"$VPNC_UP_FILE"
          # Implement routing rules
          iptables -t nat -D POSTROUTING -s "$VPN_SERVER_SUBNET" -o "$IFACE" -j MASQUERADE 2>/dev/null
          iptables -t nat -A POSTROUTING -s "$VPN_SERVER_SUBNET" -o "$IFACE" -j MASQUERADE
        fi
      done
    else # vpnclientX-route-up file does not exist
      true >"$VPNC_UP_FILE"
      {
        echo "#!/bin/sh"
        echo "$IPTABLES_DEL_ENTRY"
        echo "$IPTABLES_ADD_ENTRY"
      } >>"$VPNC_UP_FILE"
      # Implement routing rules
      iptables -t nat -D POSTROUTING -s "$VPN_SERVER_SUBNET" -o "$IFACE" -j MASQUERADE 2>/dev/null
      iptables -t nat -A POSTROUTING -s "$VPN_SERVER_SUBNET" -o "$IFACE" -j MASQUERADE
    fi
    # vpnclientX-route-pre-down File
    if [ -s "$VPNC_DOWN_FILE" ]; then
      #Check if an existing entry exists
      if [ "$(grep -c "$IPTABLES_DEL_ENTRY" "$VPNC_DOWN_FILE")" -eq "0" ]; then # entry does not exist, add entry
        echo "$IPTABLES_DEL_ENTRY" >>"$VPNC_DOWN_FILE"
      fi
    else # # vpnclientX-route-pre-down file does not exist, add entry
      echo "#!/bin/sh" >"$VPNC_DOWN_FILE"
      echo "$IPTABLES_DEL_ENTRY" >>"$VPNC_DOWN_FILE"
    fi

    # nat-start File
    if [ -s "$NAT_START" ]; then
      if [ "$(grep -c "$SCRIPT_ENTRY" "$NAT_START")" -eq "0" ]; then # if true, then no lines exist, add entry
        echo "$SCRIPT_ENTRY" >>"$NAT_START"
        logger -st "($(basename "$0"))" $$ "$SCRIPT_ENTRY added to $NAT_START"
      fi
    else # nat-start file does not exist,create it
      true >"$NAT_START"
      {
        printf '%s\n' "#!/bin/sh"
        printf '%s\n' "$SCRIPT_ENTRY" # file does not exist, create VPNC_UP_FILE
      } >"$NAT_START"
      logger -st "($(basename "$0"))" $$ "$SCRIPT_ENTRY added to $NAT_START"
    fi

    # Add nvram entry to vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist
    if [ "$(echo "$VPN_IP_LIST" | grep -c "$POLICY_RULE_WITHOUT_NAME")" -eq "0" ]; then
      VPN_IP_LIST="${VPN_IP_LIST}${POLICY_RULE}"	  
	    nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist="$(echo "$VPN_IP_LIST" | cut -b1-255)"
	    nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist1="$(echo "$VPN_IP_LIST" | cut -b256-511)"
	    nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist2="$(echo "$VPN_IP_LIST" | cut -b512-767)"
	    nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist3="$(echo "$VPN_IP_LIST" | cut -b768-1023)"
	    nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist4="$(echo "$VPN_IP_LIST" | cut -b1024-1279)"
	    nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist5="$(echo "$VPN_IP_LIST" | cut -b1280-1535)"	  
      nvram commit
      logger -st "($(basename "$0"))" $$ "Restarting VPN Client ${VPN_CLIENT_INSTANCE} to add policy rule for VPN Server ${VPN_SERVER_INSTANCE}"
      service restart_vpnclient"${VPN_CLIENT_INSTANCE}"
    else #if the VPN Server entry exists in nvram using the 'vpnserverX' name created by the prior version, convert it to the new name
      if [ "$(echo "$VPN_IP_LIST" | grep -c "vpnserver${VPN_SERVER_INSTANCE}")" -ge "1" ]; then
        VPN_IP_LIST="$(echo "$VPN_IP_LIST" | sed "s/<vpnserver${VPN_SERVER_INSTANCE}>/<VPN Server ${VPN_SERVER_INSTANCE}>/")"
	      nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist="$(echo "$VPN_IP_LIST" | cut -b1-255)"
	      nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist1="$(echo "$VPN_IP_LIST" | cut -b256-511)"
	      nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist2="$(echo "$VPN_IP_LIST" | cut -b512-767)"
	      nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist3="$(echo "$VPN_IP_LIST" | cut -b768-1023)"
	      nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist4="$(echo "$VPN_IP_LIST" | cut -b1024-1279)"
	      nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist5="$(echo "$VPN_IP_LIST" | cut -b1280-1535)"	  
	      nvram commit
        logger -st "($(basename "$0"))" $$ "Restarting vpnclient ${VPN_CLIENT_INSTANCE} for policy rule for VPN Server ${VPN_SERVER_INSTANCE} to take effect"
        service restart_vpnclient"${VPN_CLIENT_INSTANCE}"
      fi
    fi
  else # del parmater passed. Delete routing and routing rules in vpn server up down scripts.
    iptables -t nat -D POSTROUTING -s "$VPN_SERVER_SUBNET" -o "$IFACE" -j MASQUERADE 2>/dev/null

    # vpnserverX-up file
    if [ -s "$VPNC_UP_FILE" ]; then #file exists
      # POSTROUTING
      CMD="awk '\$5 == \"POSTROUTING\" && \$11 == \"$IFACE\" && \$13 == \"MASQUERADE\" {next} {print \$0}' \"$VPNC_UP_FILE\" > \"$VPNC_UP_FILE.tmp\" && mv \"$VPNC_UP_FILE.tmp\" \"$VPNC_UP_FILE\""
      eval "$CMD"
      logger -st "($(basename "$0"))" $$ "iptables entry for VPN Client ${VPN_CLIENT_INSTANCE} deleted from $VPNC_UP_FILE"
      Check_For_Shebang "$VPNC_UP_FILE"
    fi

    # vpnserverX-down file
    if [ -s "$VPNC_DOWN_FILE" ]; then #file exists
      # POSTROUTING
      CMD="awk '\$5 == \"POSTROUTING\" && \$11 == \"$IFACE\" && \$13 == \"MASQUERADE\" {next} {print \$0}' \"$VPNC_DOWN_FILE\" > \"$VPNC_DOWN_FILE.tmp\" && mv \"$VPNC_DOWN_FILE.tmp\" \"$VPNC_DOWN_FILE\""
      eval "$CMD"
      logger -st "($(basename "$0"))" $$ "iptables entry deleted VPN Client ${VPN_CLIENT_INSTANCE} from $VPNC_DOWN_FILE"
      Check_For_Shebang "$VPNC_DOWN_FILE"
    fi

    # nat-start File
    if [ -s "$NAT_START" ]; then
      sed "/$SERVER $CLIENT/d" "$NAT_START" >"$NAT_START.tmp" && mv "$NAT_START.tmp" "$NAT_START"
      logger -t "($(basename "$0"))" $$ "$SCRIPT_ENTRY entry deleted from $NAT_START"
      Check_For_Shebang "$NAT_START"
    fi

    # nvram get vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist
    if [ "$(echo "$VPN_IP_LIST" | grep -c "$POLICY_RULE")" -eq "1" ]; then
      VPN_IP_LIST=$(echo "$VPN_IP_LIST" | sed "s,<VPN Server ${VPN_SERVER_INSTANCE}>${VPN_SERVER_SUBNET}>0.0.0.0>VPN,,")
	    nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist="$(echo "$VPN_IP_LIST" | cut -b1-255)"
	    nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist1="$(echo "$VPN_IP_LIST" | cut -b256-511)"
	    nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist2="$(echo "$VPN_IP_LIST" | cut -b512-767)"
	    nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist3="$(echo "$VPN_IP_LIST" | cut -b768-1023)"
	    nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist4="$(echo "$VPN_IP_LIST" | cut -b1024-1279)"
	    nvram set vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist5="$(echo "$VPN_IP_LIST" | cut -b1280-1535)"	  
      nvram commit
      logger -st "($(basename "$0"))" $$ "Restarting vpnclient ${VPN_CLIENT_INSTANCE} to remove policy rule for VPN Server ${VPN_SERVER_INSTANCE}"
      service restart_vpnclient"${VPN_CLIENT_INSTANCE}"
    fi
  fi

  #set permissions for each file
  [ -s "$VPNC_UP_FILE" ] && chmod 755 "$VPNC_UP_FILE"
  [ -s "$VPNC_DOWN_FILE" ] && chmod 755 "$VPNC_DOWN_FILE"
  [ -s "$NAT_START" ] && chmod 755 "$NAT_START"

}

VPN_Server_to_IPSET() {

  VPN_SERVER_INSTANCE=$1
  VPN_CLIENT_INSTANCE=$2
  IFACE=$3
  IPSET_NAME=$4
  TAG_MARK=$5
  DEL_FLAG=$6
  SERVER="server=$VPN_SERVER_INSTANCE"
  IPSET="ipset_name=$IPSET_NAME"
  SCRIPT_ENTRY="sh /jffs/scripts/x3mRouting/$(basename "$0") $SERVER $IPSET"

  case "$VPN_SERVER_INSTANCE" in
  1) VPN_SERVER_TUN="tun21" ;;
  2) VPN_SERVER_TUN="tun22" ;;
  *) Error_Exit "ERROR VPN Server instance $VPN_SERVER_INSTANCE should be a 1 or 2" ;;
  esac
  # Get VPN Server IP
  VPN_SERVER_IP=$(nvram get vpn_server"${VPN_SERVER_INSTANCE}"_sn)

  # POSTROUTING CHAIN
  IPTABLES_POSTROUTING_DEL_ENTRY="iptables -t nat -D POSTROUTING -s \"\$(nvram get vpn_server${VPN_SERVER_INSTANCE}_sn)\"/24 -o $IFACE -j MASQUERADE 2>/dev/null"
  IPTABLES_POSTROUTING_ADD_ENTRY="iptables -t nat -A POSTROUTING -s \"\$(nvram get vpn_server${VPN_SERVER_INSTANCE}_sn)\"/24 -o $IFACE -j MASQUERADE"

  # PREROUTING CHAIN
  IPTABLES_PREROUTING_DEL_ENTRY="iptables -t mangle -D PREROUTING -i $VPN_SERVER_TUN -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK 2>/dev/null"
  IPTABLES_PREROUTING_ADD_ENTRY="iptables -t mangle -A PREROUTING -i $VPN_SERVER_TUN -m set --match-set $IPSET_NAME dst -j MARK --set-mark $TAG_MARK"

  # VPN Client Up/Down files
  VPNC_UP_FILE="/jffs/scripts/x3mRouting/vpnclient${VPN_CLIENT_INSTANCE}-route-up"
  VPNC_DOWN_FILE="/jffs/scripts/x3mRouting/vpnclient${VPN_CLIENT_INSTANCE}-route-pre-down"
  NAT_START="/jffs/scripts/nat-start"

  if [ "$DEL_FLAG" != "del" ]; then #add entry
    if [ -s "$VPNC_UP_FILE" ]; then #file exists
      #Check if an existing entry exists
      for IPTABLES_ENTRY in "$IPTABLES_POSTROUTING_DEL_ENTRY" "$IPTABLES_POSTROUTING_ADD_ENTRY" "$IPTABLES_PREROUTING_DEL_ENTRY" "$IPTABLES_PREROUTING_ADD_ENTRY"; do
        if [ "$(grep -c "$IPTABLES_ENTRY" "$VPNC_UP_FILE")" -eq "0" ]; then # if true, add entry
          echo "$IPTABLES_ENTRY" >>"$VPNC_UP_FILE" && logger -t "($(basename "$0"))" $$ "iptables entry added to $VPNC_UP_FILE"
        fi
      done
      iptables -t nat -D POSTROUTING -s "$VPN_SERVER_IP"/24 -o "$IFACE" -j MASQUERADE 2>/dev/null
      iptables -t nat -A POSTROUTING -s "$VPN_SERVER_IP"/24 -o "$IFACE" -j MASQUERADE
      iptables -t mangle -D PREROUTING -i "$VPN_SERVER_TUN" -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK" 2>/dev/null
      iptables -t mangle -A PREROUTING -i "$VPN_SERVER_TUN" -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK"
    else #file does not exist
      true >"$VPNC_UP_FILE"
      {
        echo "#!/bin/sh"
        echo "$IPTABLES_POSTROUTING_DEL_ENTRY"
        echo "$IPTABLES_POSTROUTING_ADD_ENTRY"
        echo "$IPTABLES_PREROUTING_DEL_ENTRY"
        echo "$IPTABLES_PREROUTING_ADD_ENTRY"
      } >>"$VPNC_UP_FILE"
      iptables -t nat -D POSTROUTING -s "$VPN_SERVER_IP"/24 -o "$IFACE" -j MASQUERADE 2>/dev/null
      iptables -t nat -A POSTROUTING -s "$VPN_SERVER_IP"/24 -o "$IFACE" -j MASQUERADE
      iptables -t mangle -D PREROUTING -i "$VPN_SERVER_TUN" -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK" 2>/dev/null
      iptables -t mangle -A PREROUTING -i "$VPN_SERVER_TUN" -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK"
    fi

    if [ -s "$VPNC_DOWN_FILE" ]; then
      #Check if an existing entry exists
      for IPTABLES_ENTRY in "$IPTABLES_POSTROUTING_DEL_ENTRY" "$IPTABLES_PREROUTING_DEL_ENTRY"; do
        if [ "$(grep -c "$IPTABLES_ENTRY" "$VPNC_DOWN_FILE")" -eq "0" ]; then # if true, then add entry
          echo "$IPTABLES_ENTRY" >>"$VPNC_DOWN_FILE" && logger -t "($(basename "$0"))" $$ "iptables entry added to $VPNC_DOWN_FILE"
        fi
      done
    else #file does not exist
      true >"$VPNC_DOWN_FILE"
      {
        echo "#!/bin/sh"
        echo "$IPTABLES_POSTROUTING_DEL_ENTRY"
        echo "$IPTABLES_PREROUTING_DEL_ENTRY"
      } >>"$VPNC_DOWN_FILE"
      logger -t "($(basename "$0"))" $$ "iptables entry added to $VPNC_DOWN_FILE"
    fi

    # nat-start File
    if [ -s "$NAT_START" ]; then # file exists
      if [ "$(grep -c "$SCRIPT_ENTRY" "$NAT_START")" -eq "0" ]; then # if true, then no lines exist
        echo "$SCRIPT_ENTRY" >>"$NAT_START" # add $SCRIPT_ENTRY to $VPNC_UP_FILE
        logger -st "($(basename "$0"))" $$ "$SCRIPT_ENTRY added to $NAT_START"
      fi
    else # nat-start does not exist
      true >"$NAT_START"
      {
        printf '%s\n' "#!/bin/sh"
        printf '%s\n' "$SCRIPT_ENTRY" # file does not exist, create VPNC_UP_FILE
      } >"$NAT_START"
      logger -st "($(basename "$0"))" $$ "$SCRIPT_ENTRY added to $NAT_START"
    fi

  else # 'del' option specified.
    iptables -t mangle -D PREROUTING -i "$VPN_SERVER_TUN" -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK" 2>/dev/null
    iptables -t nat -D POSTROUTING -s "$VPN_SERVER_IP"/24 -o "$IFACE" -j MASQUERADE 2>/dev/null

    # VPN Client route-up File
    if [ -s "$VPNC_UP_FILE" ]; then
      # POSTROUTING
      CMD="awk '\$5 == \"POSTROUTING\" && \$11 == \"$IFACE\" && \$13 == \"MASQUERADE\" {next} {print \$0}' \"$VPNC_UP_FILE\" > \"$VPNC_UP_FILE.tmp\" && mv \"$VPNC_UP_FILE.tmp\" \"$VPNC_UP_FILE\""
      eval "$CMD"
      # PREROUTING
      CMD="awk '\$5 == \"PREROUTING\" && \$7 == \"$VPN_SERVER_TUN\" && \$11 == \"$IPSET_NAME\" {next} {print \$0}' \"$VPNC_UP_FILE\" >  \"$VPNC_UP_FILE.tmp\" && mv \"$VPNC_UP_FILE.tmp\" \"$VPNC_UP_FILE\""
      eval "$CMD"
      logger -t "($(basename "$0"))" $$ "iptables entry deleted from $VPNC_UP_FILE"
      Check_For_Shebang "$VPNC_UP_FILE"
    fi

    # VPN Client route-pre-down File
    if [ -s "$VPNC_DOWN_FILE" ]; then
      # POSTROUTING
      CMD="awk '\$5 == \"POSTROUTING\" && \$11 == \"$IFACE\" && \$13 == \"MASQUERADE\" {next} {print \$0}' \"$VPNC_DOWN_FILE\" > \"$VPNC_DOWN_FILE.tmp\" && mv \"$VPNC_DOWN_FILE.tmp\" \"$VPNC_DOWN_FILE\""
      eval "$CMD"
      # PREROUTING
      CMD="awk '\$5 == \"PREROUTING\" && \$7 == \"$VPN_SERVER_TUN\" && \$11 == \"$IPSET_NAME\" {next} {print \$0}' \"$VPNC_DOWN_FILE\" >  \"$VPNC_DOWN_FILE.tmp\" && mv \"$VPNC_DOWN_FILE.tmp\" \"$VPNC_DOWN_FILE\""
      eval "$CMD"
      logger -t "($(basename "$0"))" $$ "iptables entry deleted from $VPNC_DOWN_FILE"
      Check_For_Shebang "$VPNC_DOWN_FILE"
    fi

    # nat-start File
    if [ -s "$NAT_START" ]; then
      sed "/$SERVER $IPSET/d" "$NAT_START" >"$NAT_START.tmp" && mv "$NAT_START.tmp" "$NAT_START"
      logger -t "($(basename "$0"))" $$ "$SCRIPT_ENTRY entry deleted from $NAT_START"
      Check_For_Shebang "$NAT_START"
    fi
  fi

  #set permissions for each file
  [ -s "$VPNC_UP_FILE" ] && chmod 755 "$VPNC_UP_FILE"
  [ -s "$VPNC_DOWN_FILE" ] && chmod 755 "$VPNC_DOWN_FILE"
  [ -s "$NAT_START" ] && chmod 755 "$NAT_START"

}

Harvest_Domains() {

  SCAN_SPACE_LIST=$(echo "$@" | sed -n "s/^.*autoscan=//p" | awk '{print $1}' | tr ',' ' ')

  true >/opt/tmp/DOMAIN_LIST

  for TOP_LEVEL_DOMAIN in $SCAN_SPACE_LIST; do
    SCAN_LIST=$(grep "$TOP_LEVEL_DOMAIN" "/opt/var/log/dnsmasq.log" | grep query | awk '{print $(NF-2)}' | awk -F\. '{print $(NF-1) FS $NF}' | sort | uniq)
    [ -n "$SCAN_LIST" ] && echo "$SCAN_LIST" >>/opt/tmp/DOMAIN_LIST && logger -t "($(basename "$0"))" $$ "Added $SCAN_LIST during autoscan"
  done

  DOMAIN_LIST=$(awk '{ print $1 }' "/opt/tmp/DOMAIN_LIST" | sort -u | tr '\n' '/' | sed -n 's/\/$/\n/p')

  rm /opt/tmp/DOMAIN_LIST

  if [ -z "$DOMAIN_LIST" ]; then
    Error_Exit "No domain names were harvested from $DNSMASQ_LOG_FILE"
  else
    DNSMASQ_ENTRY="/$DOMAIN_LIST/$IPSET_NAME"
    Process_DNSMASQ "$IPSET_NAME" "$DNSMASQ_ENTRY" "$DIR"
  fi
}

Dnsmasq_Log_File() {

  if [ -s "/opt/var/log/dnsmasq.log" ]; then
    DNSMASQ_LOG_FILE="/opt/var/log/dnsmasq.log"
  elif [ -s "/tmp/var/log/dnsmasq.log" ]; then
    DNSMASQ_LOG_FILE="/tmp/var/log/dnsmasq.log"
  elif [ -n "$(find / -name "dnsmasq.log")" ]; then
    DNSMASQ_LOG_FILE=$(find / -name "dnsmasq.log")
  else
    Error_Exit "ERROR dnsmasq.log file NOT found!"
  fi
}

Check_Second_Parm() {

  if [ "$(echo "$2" | grep -c 'client=')" -eq 0 ] || [ "$(echo "$2" | grep -c 'ipset_name=')" -eq 0 ]; then
    Error_Exit "ERROR Expecting first parameter to be 'server='"
  fi
}

#==================== End of Functions  =====================================
SCR_NAME=$(basename "$0" | sed 's/.sh//')
# Uncomment the line below for debugging
#set -x
## Begin ##

# Prevent duplicate processing
exec 9>"/tmp/${SCR_NAME}.lock" || exit 1
flock 9 || exit 1
trap 'rm -f /tmp/${SCR_NAME}.lock' EXIT

logger -st "($(basename "$0"))" $$ Starting Script Execution $@

# Check if user specified 'dir=' parameter
if [ "$(echo "$@" | grep -c 'dir=')" -gt 0 ]; then
  DIR=$(echo "$@" | sed -n "s/^.*dir=//p" | awk '{print $1}') # v1.2 Mount point/directory for backups
else
  DIR="/opt/tmp"
fi

#######################################################################
# Check if 'server=' parameter specified
#######################################################################

if [ "$(echo "$@" | grep -c 'server=')" -gt 0 ]; then
  SERVER=$(echo "$@" | sed -n "s/^.*server=//p" | awk '{print $1}')
  case "$SERVER" in
  1 | 2 | both) ;;
  *) Error_Exit "ERROR: Invalid Server '$SERVER' specified." ;;
  esac

  if [ "$(echo "$@" | grep -c 'client=')" -eq 0 ] && [ "$(echo "$@" | grep -c 'ipset_name=')" -eq 0 ]; then
    Error_Exit "ERROR Expecting second parameter to be either 'client=' or 'ipset_name='"
  fi

  ### Process server when 'client=' specified
  if [ "$(echo "$@" | grep -c 'client=')" -gt 0 ]; then
    VPN_CLIENT_INSTANCE=$(echo "$@" | sed -n "s/^.*client=//p" | awk '{print $1}')
    case "$VPN_CLIENT_INSTANCE" in
    1) IFACE="tun11" ;;
    2) IFACE="tun12" ;;
    3) IFACE="tun13" ;;
    4) IFACE="tun14" ;;
    5) IFACE="tun15" ;;
    *) Error_Exit "ERROR 'client=$VPN_CLIENT_INSTANCE' reference should be a 1-5" ;;
    esac

    if [ "$(echo $@ | grep -cw 'del')" -ge "1" ]; then
      if [ "$SERVER" = "both" ]; then
        for SERVER in 1 2; do
          VPN_Server_to_VPN_Client "$SERVER" "$IFACE" "$VPN_CLIENT_INSTANCE" "del"
        done
      else
        VPN_Server_to_VPN_Client "$SERVER" "$IFACE" "$VPN_CLIENT_INSTANCE" "del"
      fi
    else
      if [ "$SERVER" = "both" ]; then
        for SERVER in 1 2; do
          VPN_Server_to_VPN_Client "$SERVER" "$IFACE" "$VPN_CLIENT_INSTANCE"
        done
      else
        VPN_Server_to_VPN_Client "$SERVER" "$IFACE" "$VPN_CLIENT_INSTANCE"
      fi
    fi
    Exit_Routine
  fi

  #### Process server when 'ipset_name=' specified
  if [ "$(echo "$@" | grep -c 'ipset_name=')" -ge "1" ]; then
    IPSET_NAME=$(echo "$@" | sed -n "s/^.*ipset_name=//p" | awk '{print $1}') # ipset name
    # Check if IPSET list exists
    if [ -n "$IPSET_NAME" ]; then
      if [ "$(ipset list -n "$IPSET_NAME" 2>/dev/null)" != "$IPSET_NAME" ]; then
        Error_Exit "IPSET name $IPSET_NAME does not exist."
      fi
    fi

    ### Define interface/bitmask to route traffic to. Use existing PREROUTING rule for IPSET to determine FWMARK.
    FWMARK=$(iptables -nvL PREROUTING -t mangle --line | grep "br0" | grep "$IPSET_NAME" | awk '{print $16}')

    [ -n "$FWMARK" ] || Error_Exit "Error! Mandatory PREROUTING rule for IPSET name $IPSET_NAME does not exist."

    TAG_MARK="$FWMARK/$FWMARK"
    FWMARK_SUBSTR=$(echo "$FWMARK" | awk '{ string=substr($0, 3, 6); print string; }')

    case "$FWMARK_SUBSTR" in
    8000) IFACE="br0" ;;
    1000) IFACE="tun11" ;;
    2000) IFACE="tun12" ;;
    4000) IFACE="tun13" ;;
    7000) IFACE="tun14" ;;
    3000) IFACE="tun15" ;;
    *) Error_Exit "ERROR $1 should be a 1-5=VPN" ;;
    esac

    case "$IFACE" in
    tun11) VPN_CLIENT_INSTANCE=1 ;;
    tun12) VPN_CLIENT_INSTANCE=2 ;;
    tun13) VPN_CLIENT_INSTANCE=3 ;;
    tun14) VPN_CLIENT_INSTANCE=4 ;;
    tun15) VPN_CLIENT_INSTANCE=5 ;;
    esac

    if [ "$(echo $@ | grep -cw 'del')" -ge "1" ]; then
      if [ "$SERVER" = "both" ]; then
        for SERVER in 1 2; do
          VPN_Server_to_IPSET "$SERVER" "$VPN_CLIENT_INSTANCE" "$IFACE" "$IPSET_NAME" "$TAG_MARK" "del"
        done
      else
        VPN_Server_to_IPSET "$SERVER" "$VPN_CLIENT_INSTANCE" "$IFACE" "$IPSET_NAME" "$TAG_MARK" "del"
      fi
    else
      if [ "$SERVER" = "both" ]; then
        for SERVER in 1 2; do
          VPN_Server_to_IPSET "$SERVER" "$VPN_CLIENT_INSTANCE" "$IFACE" "$IPSET_NAME" "$TAG_MARK"
        done
      else
        VPN_Server_to_IPSET "$SERVER" "$VPN_CLIENT_INSTANCE" "$IFACE" "$IPSET_NAME" "$TAG_MARK"
      fi
    fi
    Exit_Routine
  fi
  Exit_Routine
fi
######################################################################
# End of special processing for VPN Server
######################################################################

#######################################################################
# Check if 'ipset_name=' parameter specified
# This section creates IPSET list with no routing rules
#######################################################################
if [ "$(echo "$@" | grep -c 'ipset_name=')" -gt 0 ]; then
  IPSET_NAME=$(echo "$@" | sed -n "s/^.*ipset_name=//p" | awk '{print $1}') # ipset name

  if [ "$(echo "$@" | grep -cw 'del')" -gt 0 ]; then
    Delete_Ipset_List "$IPSET_NAME"
    Exit_Routine
  fi

  # Check for 'dnsmasq=' parm
  if [ "$(echo "$@" | grep -c 'dnsmasq=')" -gt 0 ]; then
    DNSMASQ_Parm $@
    Exit_Routine
  fi

  # Check for 'autoscan=' parm
  if [ "$(echo "$@" | grep -c 'autoscan=')" -gt 0 ]; then
    Dnsmasq_Log_File
    Harvest_Domains $@
    Exit_Routine
  fi

  # check if 'asnum=' parm
  if [ "$(echo "$@" | grep -c 'asnum=')" -gt 0 ]; then
    ASNUM_Parm $@
    Exit_Routine
  fi

  # check if 'aws_region=' parm
  if [ "$(echo "$@" | grep -c 'aws_region=')" -gt 0 ]; then
    AWS_Region_Parm $@
    Exit_Routine
  fi

  # default to manual method
  if [ -z "$2" ]; then
    Manual_Method $@
    Exit_Routine
  else
    # If I reached this point, I have encountered a value I don't expect
    Error_Exit "Encountered an invalid parameter: " $@
  fi
fi
##############################################################################################
# End of Special Processing for 'ipset_name=' parm
##############################################################################################

##############################################################################################
# Start of Processing for Routing Rules
##############################################################################################

# Validate SRC_IFACE
SRC_IFACE="$1"
case "$SRC_IFACE" in
ALL | 1 | 2 | 3 | 4 | 5) ;;
*) Check_Second_Parm $@ ;;
esac

# Check for DST_IFACE
if [ -n "$2" ]; then
  DST_IFACE=$2
  if [ "$SRC_IFACE" = "ALL" ]; then
    case "$DST_IFACE" in
    1 | 2 | 3 | 4 | 5) ;;
    *) Error_Exit "ERROR: Invalid Source '$SRC_IFACE' and Destination ($DST_IFACE) combination." ;;
    esac
  fi
  if [ "$SRC_IFACE" = "1" ] || [ "$SRC_IFACE" = "2" ] || [ "$SRC_IFACE" = "3" ] || [ "$SRC_IFACE" = "4" ] || [ "$SRC_IFACE" = "5" ]; then
    case "$DST_IFACE" in
    0) ;;
    *) Error_Exit "ERROR: Invalid Source '$SRC_IFACE' and Destination ($DST_IFACE) combination." ;;
    esac
  fi
  Set_Fwmark_Parms
else
  Error_Exit "ERROR missing arg2 'dst_iface'"
fi

# Check for IPSET list name parm
if [ -n "$3" ]; then
  IPSET_NAME=$3
else
  Error_Exit "ERROR missing arg3 'ipset_name'"
fi

# Validate DST_IFACE and set destination TAG_MARK
case "$DST_IFACE" in
0)
  TAG_MARK="$FWMARK_WAN" # Which Target WAN or VPN? Martineau Hack
  TARGET_DESC="WAN"
  ;;
1)
  TAG_MARK="$FWMARK_OVPNC1"
  TARGET_DESC="VPN Client 1"
  ;;
2)
  TAG_MARK="$FWMARK_OVPNC2"
  TARGET_DESC="VPN Client 2"
  ;;
3)
  TAG_MARK="$FWMARK_OVPNC3"
  TARGET_DESC="VPN Client 3"
  ;;
4)
  TAG_MARK="$FWMARK_OVPNC4"
  TARGET_DESC="VPN Client 4"
  ;;
5)
  TAG_MARK="$FWMARK_OVPNC5"
  TARGET_DESC="VPN Client 5"
  ;;
*)
  Error_Exit "ERROR $DST_IFACE should be 0-WAN or 1,2,3,4,5 VPN Client number"
  ;;
esac

Set_IP_Rule "$DST_IFACE"

# Check if delete option specified
if [ "$(echo "$@" | grep -cw 'del')" -gt 0 ]; then
  Delete_Ipset_List "$IPSET_NAME"
  Exit_Routine
fi

# 'src=' or 'src_range=' parms require exception processing
if [ "$(echo "$@" | grep -c 'src=')" -gt 0 ] || [ "$(echo "$@" | grep -c 'src_range=')" -gt 0 ]; then
  Process_Src_Option "$@"
  Exit_Routine
fi

# Check for 'dnsmasq' parm which indicates DNSMASQ method & make sure 'autoscan' parm is not passed!
if [ "$(echo "$@" | grep -c 'dnsmasq=')" -gt 0 ]; then
  DNSMASQ_Parm $@
  Create_Routing_Rules "$IPSET_NAME"
  Check_Files_For_Entries "$SRC_IFACE" "$DST_IFACE" "$IPSET_NAME" "dnsmasq=$DOMAINS"
  Exit_Routine
fi

# autoscan method
if [ "$(echo "$@" | grep -c 'autoscan')" -gt 0 ]; then
  Dnsmasq_Log_File $@
  Harvest_Domains $@
  Create_Routing_Rules "$IPSET_NAME"
  Check_Files_For_Entries "$SRC_IFACE" "$DST_IFACE" "$IPSET_NAME" "dnsmasq=$DOMAIN_LIST"
  Exit_Routine
fi

# ASN Method
if [ "$(echo "$@" | grep -c 'asnum=')" -gt 0 ]; then
  ASNUM_Parm $@
  Create_Routing_Rules "$IPSET_NAME"
  ASN=$(echo "$@" | sed -n "s/^.*asnum=//p" | awk '{print $1}')
  Check_Files_For_Entries "$SRC_IFACE" "$DST_IFACE" "$IPSET_NAME" "asnum=$ASN"
  Exit_Routine
fi

# Amazon Method
if [ "$(echo "$@" | grep -c 'aws_region=')" -gt 0 ]; then
  AWS_Region_Parm $@
  Create_Routing_Rules "$IPSET_NAME"
  AWS_REGION=$(echo "$@" | sed -n "s/^.*aws_region=//p" | awk '{print $1}')
  Check_Files_For_Entries "$SRC_IFACE" "$DST_IFACE" "$IPSET_NAME" "aws_region=$AWS_REGION"
  Exit_Routine
fi

# Manual Method to create ipset list if IP address specified
if [ -z "$4" ] || [ "$(echo "$@" | grep -c 'ip=')" -gt 0 ]; then
  Manual_Method $@
  Create_Routing_Rules "$IPSET_NAME"
  Check_Files_For_Entries "$SRC_IFACE" "$DST_IFACE" "$IPSET_NAME"
  Exit_Routine
fi

# If I reached this point, I have encountered a value I don't expect
Error_Exit "Encountered an invalid parameter: " $@
##############################################################################################
# End of Processing for Routing Rules
##############################################################################################
