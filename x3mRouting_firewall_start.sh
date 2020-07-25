#!/bin/sh
####################################################################################################
# Script: x3mRouting_firewall_start.sh
# VERSION=1.0.0
# Author: Xentrk
# 25-July-2020
#
#####################################################################################################
# Description:
#
# Applies to those who use the modified x3mRouting OpenVPN Client Screen. This script is called from
# /jffs/scipts/firewall-start.
#
# A firewall restart will wipe the Accept DNS configuration = Exclusive rules and the PREROUTING rules
# for IPSET lists. Bouncing the active VPN Clients after a firewalll restart will result in
# vpnrouting.sh and updown-client.sh to reinstate the rules.
#
#####################################################################################################

if [ -s "/jffs/addons/x3mRouting/Advanced_OpenVPNClient_Content.asp" ]; then
  for VPN_CLIENT in 1 2 3 4 5; do
    CLIENT_STATE=$(nvram get vpn_client${VPN_CLIENT}_state)
    case "$CLIENT_STATE" in
    2)
      service restart_vpnclient${VPN_CLIENT}
      logger -st "($(basename "$0"))" $$ Restarted VPN Client "$VPN_CLIENT"
      ;;
    esac
  done
else
  for VPN_CLIENT in 1 2 3 4 5; do
    [ -s "/tmp/etc/openvpn/client${VPN_CLIENT}/dns.sh" ] && sh "/tmp/etc/openvpn/client${VPN_CLIENT}/dns.sh"
  done
fi
