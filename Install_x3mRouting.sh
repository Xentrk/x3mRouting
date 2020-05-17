#!/bin/sh
while true; do
  echo "Downloading, please wait patiently..."
  mkdir -p /jffs/addons/x3mRouting
  /usr/sbin/curl -s --retry 3 https://raw.githubusercontent.com/Xentrk/x3mRouting/x3mRouting-NG/x3mRouting_Menu.sh -o /jffs/addons/x3mRouting/x3mRouting_Menu.sh
  chmod 755 /jffs/addons/x3mRouting/x3mRouting_Menu.sh
  # x3mRouting.sh Script
  if [ -d "/opt/bin" ] && [ "$(find /opt/bin/ -maxdepth 1 -type l -ls | grep -c "/opt/bin/x3mRouting -> /jffs/addons/x3mRouting/x3mRouting_Menu.sh")" -eq 0 ]; then
    if [ -s "/opt/bin/x3mRouting" ]; then # old alias situation
      rm /opt/bin/x3mRouting 2>/dev/null
    fi
  fi
  rm /opt/bin/x3mMenu 2>/dev/null
  ln -s "/jffs/addons/x3mRouting/x3mRouting_Menu.sh" "/opt/bin/x3mMenu"
  x3mMenu
  exit 0
done
