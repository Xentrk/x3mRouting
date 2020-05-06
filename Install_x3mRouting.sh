#!/bin/sh
while true; do
mkdir -p /jffs/addons/x3mRouting && /usr/sbin/curl --retry 3 https://raw.githubusercontent.com/Xentrk/x3mRouting/x3mRouting-NG/x3mRouting_Menu.sh -o /jffs/addons/x3mRouting/x3mRouting_Menu.sh && chmod 755 /jffs/addons/x3mRouting/x3mRouting_Menu.sh && rm /opt/bin/x3mRouting 2>/dev/null && ln -s /jffs/addons/x3mRouting/x3mRouting_Menu.sh /opt/bin/x3mRouting && x3mRouting || ln -s /jffs/addons/x3mRouting/x3mRouting_Menu.sh /opt/bin/x3mRouting && x3mRouting && exit
done
