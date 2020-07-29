#!/bin/sh

buildno=$(nvram get buildno | sed 's/\.//')
if [ "$buildno" -lt 38419 ]; then
  branch="master"
  echo "Installing old x3mRouting version"
else
  branch="x3mRouting-384.19"
  echo "Installing NG x3mRouting version"
fi
while true; do
  echo "Downloading, please wait patiently..."
  mkdir -p /jffs/addons/x3mRouting
  /usr/sbin/curl -s --retry 3 https://raw.githubusercontent.com/Xentrk/x3mRouting/$branch/x3mRouting_Menu.sh -o /jffs/addons/x3mRouting/x3mRouting_Menu.sh
  chmod 755 /jffs/addons/x3mRouting/x3mRouting_Menu.sh
  # Remove old link or alias if exist
  if [ "$(/opt/bin/find /opt/bin/ -maxdepth 1 -type l -ls | grep -c "/opt/bin/x3mRouting -> /jffs/scripts/x3mRouting/x3mRouting.sh")" -eq 0 ]; then
    if [ -d "/opt/bin" ] && [ "$(/opt/bin/find /opt/bin/ -maxdepth 1 -type l -ls | grep -c "/opt/bin/x3mRouting -> /jffs/addons/x3mRouting/x3mRouting_Menu.sh")" -eq 0 ]; then
      if [ -s "/opt/bin/x3mRouting" ]; then # old alias situation
        rm -rf /opt/bin/x3mRouting 2>/dev/null
      fi
    else
      rm -rf /opt/bin/x3mRouting 2>/dev/null
    fi
  fi
  rm -rf /opt/bin/x3mMenu 2>/dev/null
  ln -s "/jffs/addons/x3mRouting/x3mRouting_Menu.sh" "/opt/bin/x3mMenu"
  x3mMenu
  exit 0
done
