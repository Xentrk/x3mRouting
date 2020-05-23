#!/bin/sh
####################################################################################################
# Script: x3mRouting_Menu.sh
# Author: Xentrk
# Last Updated Date: 23-May-2020
#
# Description:
#  Install, Update or Remove the x3mRouting repository
#
# Acknowledgement:
#  This project would never have been made possible if not for @Martineau on snbfourms.com
#  providing his Selective Routing knowledge and expertise. I am extemely GRATEFUL!
#
# Code for update code functions inspired by https://github.com/Adamm00 - credit to @Adamm
# and https://github.com/jackyaz/spdMerlin - credit to Jack Yaz
####################################################################################################
# shellcheck disable=SC2028
# shellcheck disable=SC2010 # need to us ls with a grep
export PATH=/sbin:/bin:/usr/sbin:/usr/bin$PATH
VERSION="2.0.0"
GIT_REPO="x3mRouting"
#GITHUB_DIR="https://raw.githubusercontent.com/Xentrk/$GIT_REPO/master"
GITHUB_DIR=https://raw.githubusercontent.com/Xentrk/$GIT_REPO/x3mRouting-NG
LOCAL_REPO=/jffs/scripts/x3mRouting
ADDONS=/jffs/addons/x3mRouting
NAT_START=/jffs/scripts/nat-start

# Uncomment the line below for debugging
#set -x

COLOR_RED='\033[0;31m'
COLOR_WHITE='\033[0m'
COLOR_GREEN='\e[0;32m'

Welcome_Message() {
  clear
  printf '\n_______________________________________________________________________\n'
  printf '|                                                                     |\n'
  printf '|  Welcome to the %bx3mRouting%b Installation Menu                        |\n' "$COLOR_GREEN" "$COLOR_WHITE"
  printf '|  Version %s by Xentrk                                            |\n' "$VERSION"
  printf '|         ____        _         _                                     |\n'
  printf '|        |__  |      | |       | |                                    |\n'
  printf '|  __  __  _| |_ _ _ | |_  ___ | | __    ____ ____  _ _ _             |\n'
  printf '|  \ \/ / |_  | %b %b \  __|/ _ \| |/ /   /  _//    \| %b %b \            |\n' "\`" "\`" "\`" "\`"
  printf '|   /  /  __| | | | |  |_ | __/|   <   (  (_ | [] || | | |            |\n'
  printf '|  /_/\_\|___ |_|_|_|\___|\___||_|\_\[] \___\\\____/|_|_|_|            |\n'
  printf '|_____________________________________________________________________|\n'
  printf '|                                                                     |\n'
  printf '| Requirements: jffs partition and USB drive with entware installed   |\n'
  printf '|                                                                     |\n'
  printf '| See the project repository at                                       |\n'
  printf '| %bhttps://github.com/Xentrk/x3mRouting%b                                |\n' "$COLOR_GREEN" "$COLOR_WHITE"
  printf '| for helpful tips.                                                   |\n'
  printf '|_____________________________________________________________________|\n\n'
  Main_Menu
}

Main_Menu() {
  while true; do
    printf '%b[1]%b  Install LAN Client Routing\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[2]%b  Install OpenVPN Client GUI, OpenVPN Event & x3mRouting.sh Script\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[3]%b  Install OpenVPN Event & x3mRouting.sh Script\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[4]%b  Install getdomainnames.sh Script\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[5]%b  Check for updates to existing x3mRouting installation\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[6]%b  Remove x3mRouting Repository\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    localmd5="$(md5sum "$ADDONS/x3mRouting_Menu.sh" | awk '{print $1}')"
    remotemd5="$(curl -fsL --retry 3 "${GITHUB_DIR}/x3mRouting_Menu.sh" | md5sum | awk '{print $1}')"
    if [ "$localmd5" != "$remotemd5" ]; then
      printf '%b[7]%b  Update x3mRouting Menu\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    fi
    if [ -d "$LOCAL_REPO" ]; then
      if [ ! -f "$LOCAL_REPO/x3mRouting_client_config.sh" ] && [ ! -f "$LOCAL_REPO/x3mRouting_client_nvram.sh" ] && [ ! -f "$LOCAL_REPO/x3mRouting.sh" ]; then
        if [ ! -f "$LOCAL_REPO/x3mRouting.sh" ] || [ "$(ls /jffs/configs/* | grep -c ".nvram")" -ge "1" ]; then
          printf '%b[u]%b  Update x3mRouting to Version 2.0.0\n' "${COLOR_RED}" "${COLOR_WHITE}"
        fi
      fi
    fi
    printf '\n%b[e]%b  Exit Script\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '\n%bOption ==>%b ' "${COLOR_GREEN}" "${COLOR_WHITE}"
    read -r "menu1"

    case "$menu1" in
      1)
        mkdir -p "$LOCAL_REPO"
        echo
        Install_x3mRouting_LAN_Clients
        Install_Done "x3mRouting for LAN Clients"
        return 1
        ;;
      "1 del")
        Confirm_Remove_LAN_Clients
        return 1
        ;;
      2)
        mkdir -p "$LOCAL_REPO"
        Install_x3mRouting_GUI
        Install_x3mRouting_OpenVPN_Event
        Install_x3mRouting_Shell_Scripts
        Install_Done "GUI, OpenVPN Event and Shell Scripts"
        return 1
        ;;
      "2 del")
        Confirm_Remove_OPT2_Clients
        return 1
        ;;
      3)
        mkdir -p "$LOCAL_REPO"
        Install_x3mRouting_OpenVPN_Event
        Install_x3mRouting_Shell_Scripts
        Install_Done "OpenVPN Event and Shell Scripts"
        return 1
        ;;
      4)
        mkdir -p "$LOCAL_REPO"
        Download_File "$LOCAL_REPO" "getdomainnames.sh"
        Install_Done "getdomainnames.sh"
        return 1
        ;;
      5)
        Confirm_Update
        Welcome_Message
        return 1
        ;;
      6)
        Validate_Removal
        return 1
        ;;
      7)
        Update_Installer
        return 1
        ;;
      u)
        Pre_Install_OpenVPN_Event_x3mRouting
        Update_NewVersion
        Migrate_Util_Files
        Update_Repo_Files
        Update_Addons_Files
        Welcome_Message
        return 1
        ;;
      e)
        Exit_Message
        ;;
      o)
        Install_x3mRouting_OpenVPN_Event
        return 1
        ;;
      *)
        printf '\n%bInvalid Option%b %s%b Please enter a valid option\n\n' "$COLOR_RED" "$COLOR_GREEN" "$menu1" "$COLOR_WHITE"
        ;;
    esac
  done
}

Install_Done() {
  echo
  printf '%s%b%s%b%s\n\n' "Installation of " "$COLOR_GREEN" "$1" "$COLOR_WHITE" " completed"
  echo "Press enter to continue"
  read -r
  Welcome_Message
}

Remove_LAN_Clients() {

  for VPN_ID in 1 2 3 4 5; do
    [ -s "$ADDONS/ovpnc${VPN_ID}.nvram" ] && rm -rf "$ADDONS/ovpnc${VPN_ID}.nvram" && service restart_vpnclient"$VPN_ID" && echo "Retarting VPN Client $VPN_ID to remove x3mRouting LAN Client Rules"
  done

  for FILE in x3mRouting_client_nvram.sh x3mRouting_client_config.sh x3mRouting_client_rules; do
    [ -s "$LOCAL_REPO/$FILE" ] && rm -f "$LOCAL_REPO/$FILE" && printf '\n%s%b%s%b%s\n' "Removal of " "$COLOR_GREEN" "$LOCAL_REPO/$FILE" "$COLOR_WHITE" " completed"
  done

  [ -s "$ADDONS/mount_files_lan.sh" ] && rm -f "$ADDONS/mount_files_lan.sh" && printf '\n%s%b%s%b%s\n' "Removal of " "$COLOR_GREEN" "$ADDONS/mount_files_lan.sh" "$COLOR_WHITE" " completed"

  if [ ! -s "$ADDONS/Advanced_OpenVPNClient_Content.asp" ]; then
    for FILE in vpnrouting.sh updown-client.sh; do
      if [ -s "$ADDONS/$FILE" ]; then
        case $FILE in
          vpnrouting.sh) [ "$(df | grep -c "/usr/sbin/vpnrouting.sh")" -eq 1 ] && umount /usr/sbin/vpnrouting.sh ;;
          updown-client.sh) [ "$(df | grep -c "/usr/sbin/updown-client.sh")" -eq 1 ] && umount /usr/sbin/updown-client.sh ;;
        esac
        rm -f "$ADDONS/$FILE" && printf '\n%s%b%s%b%s\n' "Removal of " "$COLOR_GREEN" "$LOCAL_REPO/$FILE" "$COLOR_WHITE" " completed"
      fi
    done
  fi
  printf "\nPress enter to continue"
  read -r
  Welcome_Message
}


Confirm_Remove_LAN_Clients() {
  while true; do
    printf '\nAre you sure you want to uninstall LAN Client Routing files?\n\n'
    printf '%b[1]%b --> Yes \n' "$COLOR_GREEN" "$COLOR_WHITE"
    printf '%b[2]%b --> Cancel\n' "$COLOR_GREEN" "$COLOR_WHITE"
    printf '\n%b[1-2]%b: ' "$COLOR_GREEN" "$COLOR_WHITE"
    read -r "menu_Validate_Removal"
    case "$menu_Validate_Removal" in
    1)
      Remove_LAN_Clients
      break
      ;;
    2)
      Welcome_Message
      break
      ;;
    *)
      printf '%bInvalid Option%b %s%b Please enter a valid option\n' "$COLOR_RED" "$COLOR_GREEN" "$menu_Validate_Removal" "$COLOR_WHITE"
      ;;
    esac
  done
}

Remove_OPT2() {

  if [ -s "$LOCAL_REPO/x3mRouting.sh" ] && [ -s "$LOCAL_REPO/openvpn-event" ]; then
    while true; do
      printf '\n%s%b%s%b%s%b%s%b%s\n\n' "Are you sure you want to uninstall" "$COLOR_GREEN" " x3mRouting.sh" "$COLOR_WHITE" " and " "$COLOR_GREEN" "openvpn-event" "$COLOR_WHITE" " files?"
      printf '%b[1]%b --> Yes \n' "$COLOR_GREEN" "$COLOR_WHITE"
      printf '%b[2]%b --> Cancel\n' "$COLOR_GREEN" "$COLOR_WHITE"
      printf '\n%b[1-2]%b: ' "$COLOR_GREEN" "$COLOR_WHITE"
      read -r "menu_Validate_Removal"
      case "$menu_Validate_Removal" in
      1)
        # Remove the jq package
        Chk_Entware jq 1
        if [ "$READY" -eq "0" ]; then
          echo "Existing jq package found. Removing jq"
          opkg remove jq && echo "jq successfully removed" || echo "Error occurred when removing jq"
        fi
        [ -s "$LOCAL_REPO/x3mRouting.sh" ] && rm -f "$LOCAL_REPO/x3mRouting.sh" && printf '\n%s%b%s%b%s\n' "Removal of " "$COLOR_GREEN" "$LOCAL_REPO/mount_files_lan.sh" "$COLOR_WHITE" " completed"
        [ -s "$LOCAL_REPO/openvpn-event.sh" ] && rm -f "$LOCAL_REPO/openvpn-event" && printf '\n%s%b%s%b%s\n' "Removal of " "$COLOR_GREEN" "$LOCAL_REPO/mount_files_lan.sh" "$COLOR_WHITE" " completed"
        break
        ;;
      2)
        Welcome_Message
        break
        ;;
      *)
        printf '%bInvalid Option%b %s%b Please enter a valid option\n' "$COLOR_RED" "$COLOR_GREEN" "$menu_Validate_Removal" "$COLOR_WHITE"
        ;;
      esac
    done
  fi

  [ -s "$ADDONS/mount_files_gui.sh" ] && rm -f "$ADDONS/mount_files_gui.sh" && printf '\n%s%b%s%b%s\n' "Removal of " "$COLOR_GREEN" "$ADDONS/mount_files_gui.sh" "$COLOR_WHITE" " completed"

  [ -s "$ADDONS/Advanced_OpenVPNClient_Content" ] && rm -f "$ADDONS/Advanced_OpenVPNClient_Content" && printf '\n%s%b%s%b%s\n' "Removal of " "$COLOR_GREEN" "$ADDONS/Advanced_OpenVPNClient_Content" "$COLOR_WHITE" " completed"

  if [ ! -s "$LOCAL_REPO/x3mRouting_client_nvram.sh" ] && [ ! -s "$LOCAL_REPO/x3mRouting_client_config.sh" ]; then
    for FILE in vpnrouting.sh updown-client.sh; do
      if [ -s "$ADDONS/$FILE" ]; then
        case $FILE in
          vpnrouting.sh) [ "$(df | grep -c "/usr/sbin/vpnrouting.sh")" -eq 1 ] && umount /usr/sbin/vpnrouting.sh ;;
          updown-client.sh) [ "$(df | grep -c "/usr/sbin/updown-client.sh")" -eq 1 ] && umount /usr/sbin/updown-client.sh ;;
        esac
        rm -f "$ADDONS/$FILE" && printf '\n%s%b%s%b%s\n' "Removal of " "$COLOR_GREEN" "$LOCAL_REPO/$FILE" "$COLOR_WHITE" " completed"
      fi
    done
  fi
  printf "\nPress enter to continue"
  read -r
  Welcome_Message
}

Confirm_Remove_OPT2_Clients() {
  while true; do
    printf '\nAre you sure you want to uninstall Option 2 files?\n\n'
    printf '%b[1]%b --> Yes \n' "$COLOR_GREEN" "$COLOR_WHITE"
    printf '%b[2]%b --> Cancel\n' "$COLOR_GREEN" "$COLOR_WHITE"
    printf '\n%b[1-2]%b: ' "$COLOR_GREEN" "$COLOR_WHITE"
    read -r "menu_Validate_Removal"
    case "$menu_Validate_Removal" in
    1)
      Remove_OPT2
      break
      ;;
    2)
      Welcome_Message
      break
      ;;
    *)
      printf '%bInvalid Option%b %s%b Please enter a valid option\n' "$COLOR_RED" "$COLOR_GREEN" "$menu_Validate_Removal" "$COLOR_WHITE"
      ;;
    esac
  done
}

Validate_Removal() {
  while true; do
    printf '\nAre you sure you want to uninstall the %bx3mRouting%b repository\n\n' "$COLOR_GREEN" "$COLOR_WHITE"
    printf 'and all changes made by the installer?\n'
    printf '%b[1]%b --> Yes \n' "$COLOR_GREEN" "$COLOR_WHITE"
    printf '%b[2]%b --> Cancel\n' "$COLOR_GREEN}" "$COLOR_WHITE"
    printf '\n%b[1-2]%b: ' "$COLOR_GREEN" "$COLOR_WHITE"
    read -r "menu_Validate_Removal"
    case "$menu_Validate_Removal" in
    1)
      Remove_Existing_Installation
      break
      ;;
    2)
      Welcome_Message
      break
      ;;
    *)
      printf '%bInvalid Option%b %s%b Please enter a valid option\n' "$COLOR_RED" "$COLOR_GREEN" "$menu_Validate_Removal" "$COLOR_WHITE"
      ;;
    esac
  done
}

Confirm_Update() {

  while true; do
    printf '\n\nThis option will check your current installation and update any files that have changed\n'
    printf 'since you last installed the repository.  Updating is highly recommended to get the most recent.\n'
    printf 'files. Chosing this option will not update missing files. Select the install option from the\n'
    printf 'menu to reinstall missing files\n\n'
    printf 'Would you like to check and download any files that have been updated?\n\n'
    printf '%b[1]%b  --> Yes\n' "$COLOR_GREEN" "$COLOR_WHITE"
    printf '%b[2]%b  --> No\n' "$COLOR_GREEN" "$COLOR_WHITE"
    echo
    printf '[1-2]: '
    read -r "Confirm_Update_Option"
    case "$Confirm_Update_Option" in
    1)
      echo
      Update_Repo_Files
      Update_Addons_Files
      break
      ;;
    2)
      Welcome_Message
      break
      ;;
    *)
      echo "[*] $Confirm_Update_Option Isn't An Option!"
      ;;
    esac
  done
}

Remove_Mounts () {

  [ "$(df | grep -c "/usr/sbin/vpnrouting.sh")" -eq 1 ] && umount /usr/sbin/vpnrouting.sh
  [ "$(df | grep -c "/usr/sbin/updown-client.sh")" -eq 1 ] && umount /usr/sbin/updown-client.sh
  [ "$(df | grep -c "/www/Advanced_OpenVPNClient_Content.asp")" -eq 1 ] && umount /www/Advanced_OpenVPNClient_Content.asp

}

Migrate_Util_Files () {

  for FILE in vpnrouting.sh updown-client.sh Advanced_OpenVPNClient_Content.asp mount_files_lan.sh mount_files_gui.sh; do
    if [ -s "$LOCAL_REPO/$FILE" ]; then
      case "$FILE" in
        vpnrouting.sh) [ "$(df | grep -c "/usr/sbin/vpnrouting.sh")" -eq 1 ] && umount /usr/sbin/vpnrouting.sh && [ -s "$LOCAL_REPO/$FILE" ] && mv "$LOCAL_REPO/$FILE" "$ADDONS/$FILE" ;;
        updown-client.sh) [ "$(df | grep -c "/usr/sbin/updown-client.sh")" -eq 1 ] && umount /usr/sbin/updown-client.sh && [ -s "$LOCAL_REPO/$FILE" ] && mv "$LOCAL_REPO/$FILE" "$ADDONS/$FILE" ;;
        Advanced_OpenVPNClient_Content.asp) [ "$(df | grep -c "/www/Advanced_OpenVPNClient_Content.asp")" -eq 1 ] && umount /www/Advanced_OpenVPNClient_Content.asp && [ -s "$LOCAL_REPO/$FILE" ] && mv "$LOCAL_REPO/$FILE" "$ADDONS/$FILE" ;;
        mount_files_lan.sh | mount_files_gui.sh) [ -s "$LOCAL_REPO/$FILE" ] && mv "$LOCAL_REPO/$FILE" "$ADDONS/$FILE" && sed 's/scripts/addons/' "$ADDONS/$FILE" > "/tmp/$FILE" && mv "/tmp/$FILE" "$ADDONS/$FILE" && chmod 755 "$ADDONS/$FILE" ;;
      esac
    fi
  done

  if [ -s "/jffs/scripts/init-start" ]; then
    for FILE in mount_files_lan.sh mount_files_gui.sh; do
      if grep -q "$LOCAL_REPO/$FILE" "/jffs/scripts/init-start"; then
        OLD_ENTRY="$LOCAL_REPO/$FILE"
        NEW_ENTRY="$ADDONS/$FILE"
        sed "s|$OLD_ENTRY|$NEW_ENTRY|" "/jffs/scripts/init-start" > "/tmp/init-start" && mv "/tmp/init-start" "/jffs/scripts/init-start" && chmod 755 "/jffs/scripts/init-start"
        sh /jffs/scripts/init-start
      fi
    done
  fi

}

### Code for update code functions inspired by https://github.com/Adamm00 - credit to @Adamm
### and https://github.com/jackyaz/spdMerlin - credit to Jack Yaz
Update_Addons_Files() {

    for FILE in mount_files_lan.sh mount_files_gui.sh; do
      if [ -s "$ADDONS/$FILE" ]; then
        localver=$(grep "VERSION=" "$ADDONS/$FILE" | grep -m1 -oE '[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
        serverver=$(/usr/sbin/curl -fsL --retry 3 "$GITHUB_DIR/$FILE" | grep "VERSION=" | grep -m1 -oE '[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
        if [ "$localver" != "$serverver" ]; then
          printf 'New version of %b%s%b available - updating to %s\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$serverver"
          Download_File "$ADDONS" "$FILE"
        else
          printf 'No new version of %b%s%b to update - latest is %s\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$serverver"
        fi
      fi
    done

  Remove_Mounts
  for FILE in vpnrouting.sh updown-client.sh Advanced_OpenVPNClient_Content.asp mount_files_lan.sh mount_files_gui.sh; do
    if [ -s "$ADDONS/$FILE" ]; then
      localmd5="$(md5sum "$ADDONS/$FILE" | awk '{print $1}')"
      remotemd5="$(curl -fsL --retry 3 "$GITHUB_DIR/$FILE" | md5sum | awk '{print $1}')"
      if [ "$localmd5" != "$remotemd5" ]; then
        printf '%s%b%s%b%s\n' "MD5 hash of " "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" " does not match - downloading"
        Download_File "$ADDONS" "$FILE"
      fi
    fi
  done

  sh /jffs/scripts/init-start
  echo
  echo "Update of x3mRouting completed"
  echo
  echo "Press enter to continue"
  read -r

}

Update_Repo_Files() {

  if [ -d "$LOCAL_REPO" ]; then
    for FILE in x3mRouting.sh x3mRouting_client_nvram.sh x3mRouting_client_config.sh openvpn-event getdomainnames.sh; do
      if [ -s "$LOCAL_REPO/$FILE" ]; then
        localver=$(grep "VERSION=" "$LOCAL_REPO/$FILE" | grep -m1 -oE '[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
        serverver=$(/usr/sbin/curl -fsL --retry 3 "$GITHUB_DIR/$FILE" | grep "VERSION=" | grep -m1 -oE '[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
        if [ "$localver" != "$serverver" ]; then
          printf 'New version of %b%s%b available - updating to %s\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$serverver"
          Download_File "$LOCAL_REPO" "$FILE"
        else
          printf 'No new version of %b%s%b to update - latest is %s\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$serverver"
        fi

        localmd5="$(md5sum "$LOCAL_REPO/$FILE" | awk '{print $1}')"
        remotemd5="$(curl -fsL --retry 3 "$GITHUB_DIR/$FILE" | md5sum | awk '{print $1}')"
        if [ "$localmd5" != "$remotemd5" ]; then
          printf '%s%b%s%b%s\n' "MD5 hash of " "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" " does not match - downloading"
          Download_File "$LOCAL_REPO" "$FILE"
        fi
      fi
    done
  else
    printf '\n%s%b%s%b%s\n' "Project Repository directory " "$COLOR_GREEN" "$DIR" "$COLOR_WHITE" " not found"
    echo "Select one of the the install options from the main menu to install the respository"
    echo
    echo "Press enter to continue"
    read -r
    return
  fi

}

Pre_Install_OpenVPN_Event_x3mRouting () {
  # checking for existance of any "load" scripts. Their presence indicates x3mRouting.sh & openvpn need to be first installed
  # before removing the "load" scripts
  if [ "$(ls "$LOCAL_REPO" | grep -c "load_")" -ge "1" ]; then
    Download_File "$LOCAL_REPO" "x3mRouting.sh" && rm -rf "/opt/bin/x3mRouting" 2>/dev/null && ln -s "$LOCAL_REPO/x3mRouting.sh" "/opt/bin/x3mRouting"
    Download_File "$LOCAL_REPO" "openvpn-event"
  fi
}

Update_NewVersion() {
  # This script will clean-up old files and create a conversion file

  CONV_FILE=/jffs/scripts/x3mRouting/x3mRouting_Conversion.sh

  # START: Functions
  Conversion_Msg() {
    {
      echo "# Source File====> $FILE"
      echo "# Original Entry=> $LINE"
      echo "$LINE4"
      echo
    } >> "$CONV_FILE"
  }

  Warning_Msg() {
    {
      echo "# If the source VPN Client you want to bypass is '1', then no changes are required."
      echo "# Otherwise, edit the '1' to be a valid VPN Client number '1-5'"
    }>> "$CONV_FILE"
  }

  Process_File() {

    FILE=$1

    if [ "$(grep -c x3mRouting "$FILE")" -gt 0 ]; then
      grep x3mRouting "$FILE" | while read -r LINE; do

      # Skip comment lines
        LINETYPE=$(echo "$LINE" | awk  '{ string=substr($0, 1, 1); print string;}')
        if [ "$LINETYPE" = "#" ]; then
          continue
        fi

      # AMAZON
        if [ "$(echo "$LINE" | grep  -c load_AMAZON_ipset_iface.sh)" -ge 1 ]; then
          LINE2=$(echo "$LINE" | sed 's/load_AMAZON_ipset_iface.sh/x3mRouting.sh/' | sed 's/ 1/ ALL 1/' | sed 's/ 2/ ALL 2/' | sed 's/ 3/ ALL 3/' | sed 's/ 4/ ALL 4/'| sed 's/ 5/ ALL 5/' | sed 's/ 0/ 1 0/')
          AWS_REGION=$(echo "$LINE2" | awk '{ print substr( $0, length($0) - 1, length($0) ) }')
          LINE3=$(echo "$LINE2" | awk '{print $1, $2, $3, $4, $5}')
          LINE4="$LINE3 aws_region=$AWS_REGION"
          if [ "$(echo "$LINE4" | grep  -c "1 0")" -ge 1 ]; then
            Warning_Msg
          fi
          Conversion_Msg
          continue
        fi

        if [ "$(echo "$LINE" | grep  -c load_AMAZON_ipset.sh)" -ge 1 ]; then
          LINE2=$(echo "$LINE" | sed 's/load_AMAZON_ipset.sh/x3mRouting.sh/')
          IPSET=$(echo "$LINE2" | awk '{print $3}' )
          AWS_REGION=$(echo "$LINE2" | awk '{ print substr( $0, length($0) - 1, length($0) ) }')
          LINE3=$(echo "$LINE2" | awk '{print $1, $2}')
          LINE4="$LINE3 ipset_name=$IPSET aws_region=$AWS_REGION"
          Conversion_Msg
          continue
        fi

        # ASN
        if [ "$(echo "$LINE" | grep  -c load_ASN_ipset_iface.sh)" -ge 1 ]; then
          LINE2=$(echo "$LINE" | sed 's/load_ASN_ipset_iface.sh/x3mRouting.sh/' | sed 's/ 1/ ALL 1/' | sed 's/ 2/ ALL 2/' | sed 's/ 3/ ALL 3/' | sed 's/ 4/ ALL 4/'| sed 's/ 5/ ALL 5/' | sed 's/ 0/ 1 0/')
          ASNUM=$(echo "$LINE2" | sed -ne 's/^.*AS//p')
          ASN="AS${ASNUM}"
          LINE3=$(echo "$LINE2" | awk '{print $1, $2, $3, $4, $5}')
          LINE4="$LINE3 asnum=$ASN"
          if [ "$(echo "$LINE4" | grep  -c "1 0")" -ge 1 ]; then
            Warning_Msg
          fi
          Conversion_Msg
          continue
        fi
        if [ "$(echo "$LINE" | grep  -c load_ASN_ipset.sh)" -ge 1 ]; then
          LINE2=$(echo "$LINE" | sed 's/load_ASN_ipset.sh/x3mRouting.sh/')
          IPSET=$(echo "$LINE2" | awk '{print $3}')
          ASNUM=$(echo "$LINE2" | sed -ne 's/^.*AS//p')
          ASN="AS${ASNUM}"
          LINE3=$(echo "$LINE2" | awk '{print $1, $2}')
          LINE4="$LINE3 ipset_name=$IPSET asnum=$ASN"
          Conversion_Msg
          continue
        fi

        # DNSMASQ
        if [ "$(echo "$LINE" | grep  -c load_DNSMASQ_ipset_iface.sh)" -ge 1 ]; then
          LINE2=$(echo "$LINE" | sed 's/load_DNSMASQ_ipset_iface.sh/x3mRouting.sh/' | sed 's/ 1/ ALL 1/' | sed 's/ 2/ ALL 2/' | sed 's/ 3/ ALL 3/' | sed 's/ 4/ ALL 4/'| sed 's/ 5/ ALL 5/' | sed 's/ 0/ 1 0/')
          IPSET=$(echo "$LINE2" | awk '{print $5}' )
          DNSMASQ=$(echo "$LINE2" | awk '{print $6}' )
          LINE3=$(echo "$LINE2" | awk '{print $1, $2, $3, $4, $5}')
          LINE4="$LINE3 dnsmasq=$DNSMASQ"
          if [ "$(echo "$LINE4" | grep  -c "1 0")" -ge 1 ]; then
            Warning_Msg
          fi
          Conversion_Msg
          continue
        fi
        if [ "$(echo "$LINE" | grep  -c load_DNSMASQ_ipset.sh)" -ge 1 ]; then
          LINE2=$(echo "$LINE" | sed 's/load_DNSMASQ_ipset.sh/x3mRouting.sh/')
          IPSET=$(echo "$LINE2" | awk '{print $3}' )
          DNSMASQ=$(echo "$LINE2" | awk '{print $4}' )
          LINE3=$(echo "$LINE2" | awk '{print $1, $2}')
          LINE4="$LINE3 ipset_name=$IPSET dnsmasq=$DNSMASQ"
          Conversion_Msg
          continue
        fi

        # MANUAL
        if [ "$(echo "$LINE" | grep  -c load_MANUAL_ipset_iface.sh)" -ge 1 ]; then
          LINE2=$(echo "$LINE" | sed 's/load_MANUAL_ipset_iface.sh/x3mRouting.sh/' | sed 's/ 1/ ALL 1/' | sed 's/ 2/ ALL 2/' | sed 's/ 3/ ALL 3/' | sed 's/ 4/ ALL 4/'| sed 's/ 5/ ALL 5/' | sed 's/ 0/ 1 0/')
          LINE3=$(echo "$LINE2" | awk '{print $1, $2, $3, $4, $5}')
          LINE4="$LINE3"
          if [ "$(echo "$LINE4" | grep  -c "1 0")" -ge 1 ]; then
            Warning_Msg
          fi
          Conversion_Msg
          continue
        fi
        if [ "$(echo "$LINE" | grep  -c load_MANUAL_ipset.sh)" -ge 1 ]; then
          LINE2=$(echo "$LINE" | sed 's/load_MANUAL_ipset.sh/x3mRouting.sh/')
          IPSET=$(echo "$LINE2" | awk '{print $3}')
          LINE3=$(echo "$LINE2" | awk '{print $1, $2}')
          LINE4="$LINE3 ipset_name=$IPSET"
          Conversion_Msg
          continue
        fi

      done
    fi

  }

  Check_For_Shebang() {

    CLIENTX_FILE=$1
    SHEBANG_COUNT=0
    EMPTY_LINE_COUNT=0
    NOT_EMPTY_LINE_COUNT=0
    COMMENT_LINE_COUNT=0

    if [ -f "$CLIENTX_FILE" ]; then # file exists
      while read -r LINE || [ -n "$LINE" ]; do
        if [ "$LINE" = "#!/bin/sh" ]; then
          SHEBANG_COUNT=$((SHEBANG_COUNT + 1))
          continue
        fi

        linetype=$(echo "$LINE" | awk '{ string=substr($0, 1, 1); print string; }')
        if [ "$linetype" = "#" ]; then
          COMMENT_LINE_COUNT=$((COMMENT_LINE_COUNT + 1))
          continue
        fi

        if [ -z "$LINE" ]; then
	       EMPTY_LINE_COUNT=$((EMPTY_LINE_COUNT + 1))
          continue
        fi

        if [ -n "$LINE" ]; then
	        NOT_EMPTY_LINE_COUNT=$((NOT_EMPTY_LINE_COUNT + 1))
          continue
        fi
      done < "$CLIENTX_FILE"
    else
      return
    fi

    if [ "$NOT_EMPTY_LINE_COUNT" -eq 0 ]; then

      printf '\n%b%s%b%s\n' "$COLOR_GREEN" "$CLIENTX_FILE" "$COLOR_WHITE" " has been analyzed for entries"
      printf '%b%s%b%s\n\n' "$COLOR_GREEN" "$CLIENTX_FILE" "$COLOR_WHITE" " has $SHEBANG_COUNT shebang entry, $NOT_EMPTY_LINE_COUNT valid lines, $COMMENT_LINE_COUNT comment lines and $EMPTY_LINE_COUNT empty lines."
      printf '%s%b%s%b%b%s\n' "Would you like to remove " "$COLOR_GREEN" "$CLIENTX_FILE"  "$COLOR_WHITE" "? " "(Yes is recommended)"
      printf '[1]  --> Yes\n'
      printf '[2]  --> No\n'
      echo
      while true; do
        printf '[1-2]: '
        read -r "OPTION"
        case "$OPTION" in
          1)
            rm "$CLIENTX_FILE"
            printf '%b%s%b%s\n' "$COLOR_GREEN" "$CLIENTX_FILE" "$COLOR_WHITE" " file deleted"
            break
            ;;
          2)
            break
            ;;
          *)
            echo "[*] $OPTION Isn't An Option!"
            ;;
        esac
      done
    else
      printf '\n%b%s%b%s\n' "$COLOR_GREEN" "$CLIENTX_FILE" "$COLOR_WHITE" " has been analyzed for entries"
      printf '%b%s%b%s\n' "$COLOR_GREEN" "$CLIENTX_FILE" "$COLOR_WHITE" " has $SHEBANG_COUNT shebang entry, $NOT_EMPTY_LINE_COUNT valid lines, $COMMENT_LINE_COUNT comment lines and $EMPTY_LINE_COUNT empty lines."
      printf '%s%b%s%b%s\n' "Skipping removal of " "$COLOR_GREEN" "$CLIENTX_FILE" "$COLOR_WHITE" "."
    fi

  }

  # Remove old version entries from nat-start
  Remove_From_nat_start() {

    if [ -s "$NAT_START" ]; then
      TIMESTAMP=$(date +"%Y-%m-%d-%H.%M.%S")
      if ! cp "$NAT_START" "$NAT_START"."$TIMESTAMP"; then
        printf '\nBackup of the prior %s file could not be made.\n' "$NAT_START"
        printf 'Exiting...\n'
        return
      else
        echo
        printf '%s%b%s%b%s\n' "Existing " "$COLOR_GREEN" "$NAT_START" "$COLOR_WHITE" " file found."
        printf '%s%b%s%b%s\n' "Backup file saved to " "$COLOR_GREEN" "$NAT_START.$TIMESTAMP" "$COLOR_WHITE" "."
      fi
      # remove obsolete entries in nat-start
      echo
      printf '%s%b%s%b%s\n\n' "Checking " "$COLOR_GREEN" "$NAT_START" "$COLOR_WHITE" " for obsolete x3mRouting scripts."
      for OLD_FILE in load_MANUAL_ipset.sh load_ASN_ipset.sh load_DNSMASQ_ipset.sh load_AMAZON_ipset.sh load_MANUAL_ipset_iface.sh load_ASN_ipset_iface.sh load_DNSMASQ_ipset_iface.sh load_AMAZON_ipset_iface.sh route_all_vpnserver.sh route_ipset_vpnserver.sh; do
        if [ "$(grep -c "$OLD_FILE" "$NAT_START")" -ge "1" ]; then # if true, then lines exist
          sed -i "/$OLD_FILE/d" "$NAT_START" && printf '%s%b%s%b%s%b%s%b\n' "Obsolete " "$COLOR_GREEN" "$OLD_FILE" "$COLOR_WHITE" " file deleted from " "$COLOR_GREEN" "$NAT_START" "$COLOR_WHITE"
        fi
      done
      Check_For_Shebang "$NAT_START"
    fi

  }

  # Remove old version entries from vpnclienX-route-up file
  Remove_From_UP_File() {

    for VPNID in 1 2 3 4 5; do
      UP_FILE=/jffs/scripts/x3mRouting/vpnclient${VPNID}-route-up
      if [ -s "$UP_FILE" ]; then # file exists
        echo
        echo "Check for and removing any obsolete files references in the vpnclient${VPNID}-route-up files"
        echo
        for OLD_FILE in load_MANUAL_ipset.sh load_ASN_ipset.sh load_DNSMASQ_ipset.sh load_AMAZON_ipset.sh load_MANUAL_ipset_iface.sh load_ASN_ipset_iface.sh load_DNSMASQ_ipset_iface.sh load_AMAZON_ipset_iface.sh route_all_vpnserver.sh route_ipset_vpnserver.sh; do
          if [ "$(grep -c "$OLD_FILE" "$UP_FILE")" -ge "1" ]; then # if true, then lines exist
            sed -i "/$OLD_FILE/d" "$UP_FILE"
          fi
        done
      Check_For_Shebang "$UP_FILE"
      fi
    done

  }

  Remove_Old_Files_Repo() {

    echo
    echo "Check for and remove any obsolete files..."
    echo
    for OLD_FILE in load_MANUAL_ipset.sh load_ASN_ipset.sh load_DNSMASQ_ipset.sh load_AMAZON_ipset.sh load_MANUAL_ipset_iface.sh load_ASN_ipset_iface.sh load_DNSMASQ_ipset_iface.sh load_AMAZON_ipset_iface.sh route_all_vpnserver.sh route_ipset_vpnserver.sh; do
      [ -f "$LOCAL_REPO/$OLD_FILE" ] && rm "$LOCAL_REPO/$OLD_FILE" && printf '%s%b%s%b%s\n' "Obsolete " "$COLOR_GREEN" "$LOCAL_REPO/$OLD_FILE" "$COLOR_WHITE" " file deleted" || printf '%s%b%s%b%s' "Obsolete " "$COLOR_GREEN" "$LOCAL_REPO/$OLD_FILE" "$COLOR_WHITE" "  file does not exist"
    done

  }

  Remove_Prerouting_Rules () {

    echo
    echo "Delete any existing PREROUTING rules for IPSET lists"
    echo
    iptables -nvL PREROUTING -t mangle --line | grep "match-set" | awk '{print $1, $12}' | sort -nr | while read -r CHAIN_NUM IPSET_NAME; do
      echo "Deleting PREROUTING Chain $CHAIN_NUM for IPSET List $IPSET_NAME"
      iptables -t mangle -D PREROUTING "$CHAIN_NUM"
    done

  }

  Remove_IPSET_dnsmasqconfadd () {

    if [ -s "/jffs/configs/dnsmasq.conf.add" ]; then
      cp "/jffs/configs/dnsmasq.conf.add" "/jffs/configs/dnsmasq.conf.add.$TIMESTAMP"
      sed -i "\\~ipset~d" "/jffs/configs/dnsmasq.conf.add"
      Check_For_Shebang "/jffs/configs/dnsmasq.conf.add"
    fi
  }

  Convert_Server_Routing_Entries() {

    for VPNSERVER in 1 2; do
      VPN_SERVER_SN=$(nvram get vpn_server${VPNSERVER}_sn)/24
      for SERVER_FILE in "$LOCAL_REPO/vpnserver${VPNSERVER}-up" "$LOCAL_REPO/vpnserver${VPNSERVER}-down"; do
        while [ -s "$SERVER_FILE" ]; do
          while [ "$(grep -c "$VPN_SERVER_SN" "$SERVER_FILE")" -ge "1" ]; do
            #if [ "$(grep -c "$VPN_SERVER_SN" "$SERVER_FILE")" -ge "1" ]; then
            TUN=$(grep -m 1 "$VPN_SERVER_SN" "$SERVER_FILE" | awk '{print $9}')
            case "$TUN" in
              tun11) VPN_CLIENT_INSTANCE=1 ;;
              tun12) VPN_CLIENT_INSTANCE=2 ;;
              tun13) VPN_CLIENT_INSTANCE=3 ;;
              tun14) VPN_CLIENT_INSTANCE=4 ;;
              tun15) VPN_CLIENT_INSTANCE=5 ;;
            esac
            # Determine if iptables rule is a VPN Server to VPN Client or VPN Server to IPSET List
            # Test for VPN Server to VPN Client
            VPN_IP_LIST=$(nvram get vpn_client"${VPN_CLIENT_INSTANCE}"_clientlist)
            POLICY_RULE_WITHOUT_NAME="${VPN_SERVER_SN}>0.0.0.0>VPN"
            if [ "$(echo "$VPN_IP_LIST" | grep -c "$POLICY_RULE_WITHOUT_NAME")" -ge "1" ]; then
              # Confirmed VPN Server to VPN Client
              if [ "$(echo "$SERVER_FILE" | grep -c "up")" -gt "0" ]; then # only create script for vpnserverX-up file
                SCRIPT_ENTRY="sh /jffs/scripts/x3mRouting/x3mRouting.sh server=$VPNSERVER client=$VPN_CLIENT_INSTANCE"
                {
                  echo
                  echo "# Found VPN Server to VPN Client iptables entries in $SERVER_FILE"
                  echo "$SCRIPT_ENTRY"
                } >> "$CONV_FILE"
                # Delete POSTROUTING Entry
                iptables -t nat -D POSTROUTING -s "$VPN_SERVER_SN" -o "$TUN" -j MASQUERADE 2>/dev/null
              fi
              CMD="awk '\$5 == \"POSTROUTING\" && \$7 == \"$VPN_SERVER_SN\" && \$9 == \"$TUN\" && \$11 == \"MASQUERADE\" {next} {print \$0}' \"$SERVER_FILE\" #> \"$SERVER_FILE.tmp\" && mv \"$SERVER_FILE.tmp\" \"$SERVER_FILE\""
              eval "$CMD" > "$SERVER_FILE.tmp" && mv "$SERVER_FILE.tmp" "$SERVER_FILE"
            else # Default to VPN Server to IPSET List
              IPSET_NAME=$(grep -m 1 "tun2${VPNSERVER}" "$SERVER_FILE" | awk '{print $11}')
              TAG_MARK=$(grep -m 1 "tun2${VPNSERVER}" "$SERVER_FILE" | awk '{print $16}')
              if [ "$(echo "$SERVER_FILE" | grep -c "up")" -gt "0" ]; then # only create script for vpnserverX-up file
                SCRIPT_ENTRY="sh /jffs/scripts/x3mRouting/x3mRouting.sh server=$VPNSERVER ipset_name=$IPSET_NAME" >> "$CONV_FILE"
                {
                  echo
                  echo "# Found VPN Server to IPSET list iptables entries in $SERVER_FILE"
                  echo "$SCRIPT_ENTRY"
                } >> "$CONV_FILE"
                iptables -t nat -D POSTROUTING -s "$VPN_SERVER_SN" -o "$TUN" -j MASQUERADE 2>/dev/null
                iptables -t mangle -D PREROUTING -i tun2"$VPNSERVER" -m set --match-set "$IPSET_NAME" dst -j MARK --set-mark "$TAG_MARK" 2>/dev/null
              fi

              # Delete POSTROUTING Entry
              CMD="awk '\$5 == \"POSTROUTING\" && \$7 == \"$VPN_SERVER_SN\" && \$9 == \"$TUN\" && \$11 == \"MASQUERADE\" {next} {print \$0}' \"$SERVER_FILE\" #> \"$SERVER_FILE.tmp\" && mv \"$SERVER_FILE.tmp\" \"$SERVER_FILE\""
              eval "$CMD" > "$SERVER_FILE.tmp" && mv "$SERVER_FILE.tmp" "$SERVER_FILE"
              # Delete PREROUTING Entry
              CMD="awk '\$5 == \"PREROUTING\" && \$7 == \"tun2$VPNSERVER\" && \$11 == \"$IPSET_NAME\" {next} {print \$0}' \"$SERVER_FILE"\" #> \"$SERVER_FILE.tmp\" && mv \"$SERVER_FILE.tmp\" \"$SERVER_FILE"\""
              eval "$CMD" > "$SERVER_FILE.tmp" && mv "$SERVER_FILE.tmp" "$SERVER_FILE"
            fi
          done #fi
          Check_For_Shebang "$SERVER_FILE"
        done
      done
    done

  }
  # END: Conversion Functions

  # START: Process Conversion

  # Only Backup the Project Repo Directory during the first run to prevent potential corruption
  if [ -d "$LOCAL_REPO" ]; then
    if [ ! -d "$LOCAL_REPO/backup" ]; then
      mkdir "$LOCAL_REPO/backup"
      cp -a "$LOCAL_REPO/." "$LOCAL_REPO/backup/" >/dev/null 2>&1
    else
      echo
      echo "Existing backup directory found. Skipping backup step."
    fi
  fi

  # If a previous version of the conversion file exists, back it up to prevent overwrite as a second run may corrupt it
  if [ -s "$LOCAL_REPO/x3mRouting_Conversion.sh" ]; then
    TIMESTAMP=$(date +"%Y-%m-%d-%H.%M.%S")
    if ! cp "$LOCAL_REPO/x3mRouting_Conversion.sh" "$LOCAL_REPO/x3mRouting_Conversion.sh.$TIMESTAMP"; then
      echo
      printf '\nBackup of the prior %s file could not be made.\n' "$LOCAL_REPO/x3mRouting_Conversion.sh"
      printf 'Exiting...\n'
      exit 0
    else
      echo
      printf '%s%b%s%b%s\n' "Existing " "$COLOR_GREEN" "$LOCAL_REPO/x3mRouting_Conversion.sh" "$COLOR_WHITE" " file found."
      printf '%s%b%s%b\n' "Backup file saved to " "$COLOR_GREEN" "$LOCAL_REPO/x3mRouting_Conversion.sh.$TIMESTAMP" "$COLOR_WHITE"
      true > "$CONV_FILE" && chmod 755 "$CONV_FILE"
    fi
  else
    true > "$CONV_FILE" && chmod 755 "$CONV_FILE"
  fi

  # Migrate any ovpncX.nvram files in /jffs/configs
  for VPNID in 1 2 3 4 5; do
    CFG_FILE=/jffs/configs/ovpnc${VPNID}.nvram
    if [ -s "$CFG_FILE" ]; then # file exists
      mv "$CFG_FILE" "$ADDONS/ovpnc${VPNID}.nvram" && printf '%s\n' "$CFG_FILE moved to $ADDONS/ovpnc${VPNID}.nvram"
    fi
  done

  # Migrate /jffs/configs/x3mRouting_client_rules
  if [ -s "/jffs/configs/x3mRouting_client_rules" ]; then # file exists
    mv /jffs/configs/x3mRouting_client_rules /jffs/scripts/x3mRouting/x3mRouting_client_rules && printf '%s\n' "$/jffs/configs/x3mRouting_client_rules moved to /jffs/scripts/x3mRouting/x3mRouting_client_rules"
  fi

  # Process any vpnclientX-route-up files in x3mRouting directory
  for VPNID in 1 2 3 4 5; do
    UP_FILE=/jffs/scripts/x3mRouting/vpnclient${VPNID}-route-up
    if [ -s "$UP_FILE" ]; then # file exists
      Process_File "$UP_FILE"
    fi
  done

  # Process nat-start
  if [ -s "$NAT_START" ]; then
    Process_File "$NAT_START"
  fi

  # Process any VPN Server to VPN Client or VPN Server to VPN IPSET rules
  Convert_Server_Routing_Entries

  # add shebang to the first line before exiting
  if [ -s "$CONV_FILE" ]; then
    sed -i '1s~^~#!/bin/sh\n~' "$CONV_FILE"
    echo
    printf '%s%b%s%b%s\n' "Created " "$COLOR_GREEN" "$CONV_FILE" "$COLOR_WHITE" " script to assist with the conversion."
    printf '%s%b%s%b%s\n' "Please review the "  "$COLOR_GREEN" "$CONV_FILE" "$COLOR_WHITE" " script before running"
  else
    printf '%b%s%b%s%b%s%b%s\n' "$COLOR_GREEN" "$CONV_FILE" "$COLOR_WHITE" " script not created. No valid x3mRouting entries found in" "$COLOR_GREEN" "$NAT_START"  "$COLOR_WHITE" " or vpnclientX- route-up files."
    rm "$CONV_FILE"
  fi

  # DO NOT Give user the option to remove the prior verson of any x3mRouting entries found in $NAT_START or vpnclientX-route-up files"
  Remove_Old_Files_Repo
  Remove_From_nat_start
  Remove_From_UP_File
  Remove_Prerouting_Rules
  Remove_IPSET_dnsmasqconfadd

}
### End of Conversion Function

Remove_Existing_Installation() {
  echo "Starting removal of x3mRouting Repository"

  Check_For_Shebang() {

    CLIENTX_FILE=$1
    SHEBANG_COUNT=0
    EMPTY_LINE_COUNT=0
    NOT_EMPTY_LINE_COUNT=0
    COMMENT_LINE_COUNT=0

    if [ -f "$CLIENTX_FILE" ]; then # file exists
      while read -r LINE || [ -n "$LINE" ]; do
        if [ "$LINE" = "#!/bin/sh" ]; then
          SHEBANG_COUNT=$((SHEBANG_COUNT + 1))
          continue
        fi

        linetype=$(echo "$LINE" | awk '{ string=substr($0, 1, 1); print string; }')
        if [ "$linetype" = "#" ]; then
          COMMENT_LINE_COUNT=$((COMMENT_LINE_COUNT + 1))
          continue
        fi

        if [ -z "$LINE" ]; then
	       EMPTY_LINE_COUNT=$((EMPTY_LINE_COUNT + 1))
          continue
        fi

        if [ -n "$LINE" ]; then
	        NOT_EMPTY_LINE_COUNT=$((NOT_EMPTY_LINE_COUNT + 1))
          continue
        fi
      done < "$CLIENTX_FILE"
    else
      return
    fi

    if [ "$NOT_EMPTY_LINE_COUNT" -eq 0 ]; then

      printf '\n%b%s%b%s\n' "$COLOR_GREEN" "$CLIENTX_FILE" "$COLOR_WHITE" " has been analyzed for entries"
      printf '%b%s%b%s\n\n' "$COLOR_GREEN" "$CLIENTX_FILE" "$COLOR_WHITE" " has $SHEBANG_COUNT shebang entry, $NOT_EMPTY_LINE_COUNT valid lines, $COMMENT_LINE_COUNT comment lines and $EMPTY_LINE_COUNT empty lines."
      printf '%s%b%s%b%b%s\n' "Would you like to remove " "$COLOR_GREEN" "$CLIENTX_FILE"  "$COLOR_WHITE" "? " "(Yes is recommended)"
      printf '[1]  --> Yes\n'
      printf '[2]  --> No\n'
      echo
      while true; do
        printf '[1-2]: '
        read -r "OPTION"
        case "$OPTION" in
          1)
            rm "$CLIENTX_FILE"
            printf '%b%s%b%s\n' "$COLOR_GREEN" "$CLIENTX_FILE" "$COLOR_WHITE" " file deleted"
            break
            ;;
          2)
            break
            ;;
          *)
            echo "[*] $OPTION Isn't An Option!"
            ;;
        esac
      done
    else
      printf '\n%b%s%b%s\n' "$COLOR_GREEN" "$CLIENTX_FILE" "$COLOR_WHITE" " has been analyzed for entries"
      printf '%b%s%b%s\n' "$COLOR_GREEN" "$CLIENTX_FILE" "$COLOR_WHITE" " has $SHEBANG_COUNT shebang entry, $NOT_EMPTY_LINE_COUNT valid lines, $COMMENT_LINE_COUNT comment lines and $EMPTY_LINE_COUNT empty lines."
      printf '%s%b%s%b%s\n' "Skipping removal of " "$COLOR_GREEN" "$CLIENTX_FILE" "$COLOR_WHITE" "."
    fi

  }

  # Remove the jq package
  Chk_Entware jq 1
  if [ "$READY" -eq "0" ]; then
    echo "Existing jq package found. Removing jq"
    if opkg remove jq; then
      echo "jq successfully removed"
    else
      echo "Error occurred when removing jq"
    fi
  fi

  # Remove entries from /jffs/scripts/init-start
  if [ -s "/jffs/scripts/init-start" ]; then # file exists
    for PARM in "sh $ADDONS/mount_files_lan.sh" "sh $ADDONS/mount_files_gui.sh"; do
      if grep -q "$PARM" "/jffs/scripts/init-start"; then # see if line exists
        sed -i "\\~$PARM~d" "/jffs/scripts/init-start"
        printf '%b%s%b%s%b%s%b\n' "$COLOR_GREEN" "$PARM" "$COLOR_WHITE" " entry removed from " "$COLOR_GREEN" "/jffs/scripts/init-start" "$COLOR_WHITE"
      fi
    done
    Check_For_Shebang /jffs/scripts/init-start
  fi

  # Remove entries from /jffs/scripts/nat-start
  if [ -s "$NAT_START" ]; then
    TIMESTAMP=$(date +"%Y-%m-%d-%H.%M.%S")
    if ! cp "$NAT_START" "$NAT_START"."$TIMESTAMP"; then
      printf '\nBackup of the prior %s file could not be made.\n' "$NAT_START"
      printf 'Exiting...\n'
      return
    else
      echo
      printf '%s%b%s%b%s\n' "Existing " "$COLOR_GREEN" "$NAT_START" "$COLOR_WHITE" " file found."
      printf '%s%b%s%b%s\n' "Backup file saved to " "$COLOR_GREEN" "$NAT_START.$TIMESTAMP" "$COLOR_WHITE" "."
    fi
    # remove x3mRouting entries in nat-start
    echo
    printf '%s%b%s%b%s\n\n' "Checking " "$COLOR_GREEN" "$NAT_START" "$COLOR_WHITE" " for x3mRouting scripts."
    if grep -q "x3mRouting" "$NAT_START"; then # see if line exists
      sed -i "\\~x3mRouting~d" "$NAT_START"
      printf '%b%s%b%s%b%s%b\n' "$COLOR_GREEN" "$PARM" "$COLOR_WHITE" " entry removed from " "$COLOR_GREEN" "$NAT_START" "$COLOR_WHITE"
    fi
    Check_For_Shebang "$NAT_START"
  fi

  # unmount vpnrouting, vpn gui and updown-client
  Remove_Mounts

  # Remove symlinks
  if [ -s "/opt/bin/x3mRouting" ]; then
    if ! rm "/opt/bin/x3mRouting" >/dev/null 2>&1; then
      printf '\nError trying to remove %b"/opt/bin/x3mRouting"%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
    else
      printf '\n%b"/opt/bin/x3mRouting"%b x3mRouting symbolic link file removed\n' "$COLOR_GREEN" "$COLOR_WHITE"
    fi
  fi

  if [ -s "/opt/bin/x3mMenu" ]; then
    if ! rm "/opt/bin/x3mMenu" >/dev/null 2>&1; then
      printf '\nError trying to remove %b"/opt/bin/x3mMenu"%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
    else
      printf '\n%b"/opt/bin/x3mMenu"%b x3mMenu symbolic link file removed\n' "$COLOR_GREEN" "$COLOR_WHITE"
    fi
  fi

  # Purge /jffs/scripts/x3mRouting directory
  for DIR in $LOCAL_REPO $ADDONS; do
    if [ -d "$DIR" ]; then
      if ! rm -rf "${DIR:?}/"* >/dev/null 2>&1; then
        printf '\nNo files found to remove in %b%s%b\n' "$COLOR_GREEN" "$DIR" "$COLOR_WHITE"
      fi
      if ! rmdir "$DIR" >/dev/null 2>&1; then
        printf '\nError trying to remove %b%s%b\n' "$COLOR_GREEN" "$DIR" "$COLOR_WHITE"
      else
        printf '\n%b%s%b folder and all files removed\n' "$COLOR_GREEN" "$DIR" "$COLOR_WHITE"
      fi
    else
      printf '\n%b%s%b folder does not exist. No directory to remove\n' "$COLOR_GREEN" "$DIR" "$COLOR_WHITE"
    fi
  done

  Exit_Message

}

Chk_Entware() {

  # ARGS [wait attempts] [specific_entware_utility]
  READY="1"          # Assume Entware Utilities are NOT available
  ENTWARE_UTILITY="" # Specific Entware utility to search for
  MAX_TRIES="30"

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

Download_File() {

  DIR="$1"
  FILE="$2"

  STATUS="$(curl --retry 3 -sL -w '%{http_code}' "$GITHUB_DIR/$FILE" -o "$DIR/$FILE")"
  if [ "$STATUS" -eq "200" ]; then
    printf '\n%b%s%b downloaded successfully\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE"
    [ "$(echo "$FILE" | grep -c '.sh')" -gt 0 ] && chmod 0755 "$DIR/$FILE"
  else
    printf '\n%b%s%b download failed with curl error %s\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$STATUS"
    printf 'Rerun the install %bx3mRouting for LAN Clients%b option\n' "$COLOR_GREEN" "$COLOR_WHITE" "$COLOR_GREEN" "$COLOR_WHITE"
    exit 1
  fi
}

Exit_Message() {

  printf '\n              %bhttps://github.com/Xentrk/x3mRouting%b\n' "$COLOR_GREEN" "$COLOR_WHITE\\n"
  printf '                      Have a Grateful Day!\n\n'
  printf '           ____        _         _                           \n'
  printf '          |__  |      | |       | |                          \n'
  printf '    __  __  _| |_ _ _ | |_  ___ | | __    ____ ____  _ _ _   \n'
  printf '    \ \/ / |_  | %b %b \  __|/ _ \| |/ /   /  _//    \| %b %b \ \n' "\`" "\`" "\`" "\`"
  printf '     /  /  __| | | | |  |_ | __/|   <   (  (_ | [] || | | |  \n'
  printf '    /_/\_\|___ |_|_|_|\___|\___||_|\_\[] \___\\\____/|_|_|_| \n\n\n'
  exit 0
}

Init_Start_Update() {

  PARM=$1

  # checking for condition that user previously installed LAN clients. if so, remove mount_files_lan.sh entry
  if [ -s "/jffs/scripts/init-start" ] && [ "$PARM" = "mount_files_gui.sh" ]; then
    if grep -q "sh $ADDONS/mount_files_lan.sh" "/jffs/scripts/init-start"; then
      sed -i "\\~$ADDONS/mount_files_lan.sh~d" "/jffs/scripts/init-start"
    fi
  fi

  if [ -s "/jffs/scripts/init-start" ]; then # file exists
    if ! grep -q "$PARM" "/jffs/scripts/init-start"; then
      echo "sh $ADDONS/$PARM    # x3mRouting" >>/jffs/scripts/init-start
      printf '\nUpdated %b/jffs/scripts/init-start%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
    else
      printf '\nRequired entry already exists in %b/jffs/scripts/init-start%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
      printf '\nSkipping update of %b/jffs/scripts/init-start%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
    fi
  else
    echo "#!/bin/sh" >/jffs/scripts/init-start
    echo "sh $ADDONS/$PARM    # x3mRouting" >>/jffs/scripts/init-start
    chmod 0755 /jffs/scripts/init-start
    printf 'Created %b/jffs/scripts/init-start%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
  fi
}

Install_x3mRouting_LAN_Clients() {

  Download_File "$LOCAL_REPO" "x3mRouting_client_nvram.sh"
  Download_File "$LOCAL_REPO" "x3mRouting_client_config.sh"
  Download_File "$ADDONS" "vpnrouting.sh"
  Download_File "$ADDONS" "updown-client.sh"
  Download_File "$ADDONS" "mount_files_lan.sh"
  Init_Start_Update "mount_files_lan.sh"
  sh /jffs/scripts/init-start
}

Install_x3mRouting_OpenVPN_Event() {

  Download_File "$LOCAL_REPO" "openvpn-event"
  chmod 0755 "$LOCAL_REPO/openvpn-event"
  if [ -s /jffs/scripts/openvpn-event ]; then
    if [ "$(grep -cw "sh /jffs/scripts/x3mRouting/openvpn-event" "/jffs/scripts/openvpn-event")" -eq 0 ]; then # see if line exists
      printf 'sh /jffs/scripts/x3mRouting/openvpn-event $@\n' >>/jffs/scripts/openvpn-event
    fi
  else
    echo "#!/bin/sh" >/jffs/scripts/openvpn-event
    printf 'sh /jffs/scripts/x3mRouting/openvpn-event $@\n' >>/jffs/scripts/openvpn-event
    chmod 0755 /jffs/scripts/openvpn-event
  fi
}

Check_Requirements() {

  Chk_Entware 30
  if [ "$READY" -eq 0 ]; then
    Chk_Entware jq 1
    if [ "$READY" -eq 0 ]; then
      if opkg update >/dev/null 2>&1; then
        echo "Entware package list successfully updated"
      fi
      # load_AMAZON_ipset.sh requires the jq package to extract the Amazon json file
    else
      if opkg install jq; then
        echo "jq successfully installed"
      else
        echo "An error occurred installing jq"
        exit 1
      fi
    fi
  else
    echo "You must first install Entware before proceeding"
    printf 'Exiting %s\n' "$(basename "$0")"
    exit 1
  fi
}

Update_Profile_Add() {

  CONFIG_DIR="$1"
  PROFILE_FILE="$2"

  {
    echo "liststats () {"
    echo "  GREEN='\033[0;32m'"
    echo "  RED='\033[0;31m'"
    echo "  NC='\033[0m'"
    echo "  true > /tmp/liststats"
    echo "  for SETLIST in \$(ipset -L -n); do"
    echo "   printf '%s - %b%s%b\n' \"\$SETLIST\" \"\$GREEN\" \"\$((\$(ipset -L \"\$SETLIST\" | wc -l) - 8))\" \"\$NC\" >> /tmp/liststats"
    echo "  done"
    echo "  cat /tmp/liststats | sort"
    echo "  rm /tmp/liststats"
    echo "}"
  } >>"$CONFIG_DIR/$PROFILE_FILE"
}

Check_Profile_Add() {

  CONFIG_DIR="/jffs/configs"
  PROFILE_FILE="profile.add"
  PARM="liststats"

  if [ -d "$CONFIG_DIR" ]; then
    if [ -s "$CONFIG_DIR/$PROFILE_FILE" ]; then
      if [ "$(grep -cw "$PARM" "$CONFIG_DIR/$PROFILE_FILE")" -gt 0 ]; then # see if line exists
        return
      else
        Update_Profile_Add "$CONFIG_DIR" "$PROFILE_FILE"
      fi
    else
      true >"$CONFIG_DIR/$PROFILE_FILE"
      Update_Profile_Add "$CONFIG_DIR" "$PROFILE_FILE"
    fi
  else
    mkdir "$CONFIG_DIR"
    true >"$CONFIG_DIR/$PROFILE_FILE"
    Update_Profile_Add "$CONFIG_DIR" "$PROFILE_FILE"
  fi

}

Install_x3mRouting_GUI() {

  Check_Requirements
  Download_File "$ADDONS" "vpnrouting.sh"
  Download_File "$ADDONS" "updown-client.sh"
  Download_File "$ADDONS" "Advanced_OpenVPNClient_Content.asp"
  Download_File "$ADDONS" "mount_files_gui.sh"
  Download_File "$LOCAL_REPO" "x3mRouting.sh"
  Init_Start_Update "mount_files_gui.sh"
  sh /jffs/scripts/init-start
  Check_Profile_Add
  echo

}

Install_x3mRouting_Shell_Scripts() {

  Check_Requirements
  Download_File "$LOCAL_REPO" "x3mRouting.sh"
  # x3mRouting.sh Script
  if [ -d "/opt/bin" ] && [ "$(/opt/bin/find /opt/bin/ -maxdepth 1 -type l -ls | grep -c "/opt/bin/x3mRouting -> /jffs/addons/x3mRouting/x3mRouting_Menu.sh")" -eq 0 ]; then
     ln -s "/jffs/scripts/x3mRouting/x3mRouting.sh" "/opt/bin/x3mRouting"
  fi
  Check_Profile_Add

}

Update_Installer() {

  while true; do
    printf '\n\nAn updated version of the x3mRouting menu as been detected\n'
    printf 'Updating the x3mRouting menu is highly recommended.\n\n'
    printf 'Would you like to download the new version now?\n\n'
    printf '%b[1]%b  --> Yes\n' "$COLOR_GREEN" "$COLOR_WHITE"
    printf '%b[2]%b  --> No\n' "$COLOR_GREEN" "$COLOR_WHITE"
    echo
    printf '[1-2]: '
    read -r "menu_Update_Installer"
    echo
    case "$menu_Update_Installer" in
    1)
      Download_File "$ADDONS" x3mRouting_Menu.sh
      chmod 755 "$ADDONS/x3mRouting_Menu.sh"
      rm -rf "/opt/bin/x3mMenu" 2>/dev/null
      if [ -d "/opt/bin" ] && [ "$(/opt/bin/find /opt/bin/ -maxdepth 1 -type l -ls | grep -c "/opt/bin/x3mRouting -> /jffs/addons/x3mRouting/x3mRouting_Menu.sh")" -eq 1 ]; then # remove prior version alias if it exists.
          rm -rf "/opt/bin/x3mRouting" 2>/dev/null
      fi
      if [ "$(/opt/bin/find /opt/bin/ -maxdepth 1 -type l -ls | grep -c "/opt/bin/x3mMenu-> /jffs/addons/x3mRouting/x3mRouting_Menu.sh")" -eq 0 ]; then
          ln -s "$ADDONS/x3mRouting_Menu.sh" /opt/bin/x3mMenu 2>&1
      fi
      printf '\n%s\n\n' "x3mRouting Installation Menu update completed $remotemd5"
      echo "Press enter to continue"
      read -r
      sh "$ADDONS/x3mRouting_Menu.sh"
      # chg from break to exit 0 to fix sub shell error code dumps
      exit 0
      #break
      ;;
    2)
      Main_Menu
      break
      ;;
    *)
      echo "[*] $menu_Update_Installer Is Not An Option!"
      ;;
    esac
  done
}

Migrate_Util_Files  # If necessary, automatically move utility files to /jffs/addons/x3mRouting, remove from here after test group converts
Welcome_Message
