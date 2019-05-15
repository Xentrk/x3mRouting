#!/bin/sh
####################################################################################################
# Script: install_x3mRouting.sh
# Author: Xentrk
# Last Updated Date: 9-May-2019
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
export PATH=/sbin:/bin:/usr/sbin:/usr/bin$PATH
logger -t "($(basename "$0"))" "$$ Starting Script Execution ($(if [ -n "$1" ]; then echo "$1"; else echo "menu"; fi))"
VERSION="1.0.0"
GIT_REPO="x3mRouting"
GITHUB_DIR="https://raw.githubusercontent.com/Xentrk/$GIT_REPO/master"
LOCAL_REPO="/jffs/scripts/x3mRouting"

# Uncomment the line below for debugging
#set -x

COLOR_RED='\033[0;31m'
COLOR_WHITE='\033[0m'
COLOR_GREEN='\e[0;32m'

Welcome_Message() {
  clear
  printf '\n_______________________________________________________________________\n'
  printf '|                                                                     |\n'
  printf '|  Welcome to the %bx3mRouting%b installation script                      |\n' "$COLOR_GREEN" "$COLOR_WHITE"
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
  printf '%b[1]%b = Install x3mRouting for LAN Clients Shell Scripts\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
  printf '%b[2]%b = Install x3mRouting OpenVPN Client GUI & IPSET Shell Scripts\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
  printf '%b[3]%b = Install x3mRouting IPSET Shell Scripts\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
  printf '%b[4]%b = Check for updates to existing x3mRouting installation\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
  printf '%b[5]%b = Force update existing x3mRouting installation\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
  printf '%b[6]%b = Remove x3mRouting Repository\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
  localmd5="$(md5sum "$0" | awk '{print $1}')"
  remotemd5="$(curl -fsL --retry 3 "${GITHUB_DIR}/install_x3mRouting.sh" | md5sum | awk '{print $1}')"
  if [ "$localmd5" != "$remotemd5" ]; then
    printf '%b[7]%b = Update install_x3mRouting.sh\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
  fi
  printf '\n%b[e]%b = Exit Script\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
  printf '\n%bOption ==>%b ' "${COLOR_GREEN}" "${COLOR_WHITE}"
  read -r "menu1"

  case "$menu1" in
  1)
    Install_x3mRouting_LAN_Clients
    break
    ;;
  2)
    Install_x3mRouting_GUI
    break
    ;;
  3)
    Install_x3mRouting_Shell_Scripts
    break
    ;;
  4)
    Confirm_Update
    break
    ;;
  5)
    Confirm_Update force
    break
    ;;
  6)
    Validate_Removal
    break
    ;;
  7)
    Update_Installer
    break
    ;;
  e)
    Exit_Message
    break
    ;;
  *)
    printf '%bInvalid Option%b %s%b Please enter a valid option\n' "$COLOR_RED" "$COLOR_GREEN" "$menu1" "$COLOR_WHITE"
    ;;
  esac
}

Validate_Removal() {
  while true; do
    printf 'Are you sure you want to uninstall the %bx3mRouting%b repository\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf 'and all changes made by the installer?\n'
    printf '%b[1]%b --> Yes \n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[2]%b --> Cancel\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '\n%b[1-2]%b: ' "${COLOR_GREEN}" "${COLOR_WHITE}"
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
    if [ -z "$1" ]; then
      printf '\n\nThis option will check your current installation and update any files that have changed\n'
      printf 'since you last installed the repository.  Updating is highly recommended to get the most recent.\n'
      printf 'files. Chosing this option will not update missing files. Select the install option from the\n'
      printf 'menu to reinstall missing files\n\n'
      printf 'Would you like to check and download any files that have been updated?\n'
      printf '%b[1]%b  --> Yes\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
      printf '%b[2]%b  --> No\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
      echo
      printf '[1-2]: '
      read -r "Confirm_Update_Option"
      case "$Confirm_Update_Option" in
      1)
        Update_Version
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
    else
      printf '\n\nThis option will check your current installation and force update any files\n'
      printf 'found installed in the x3mRouting repository.\n'
      printf 'Chosing this option will not update missing files. Select the install option from the\n'
      printf 'menu to reinstall missing files\n\n'
      printf 'Would you like to check and download any files that have been updated?\n'
      printf '%b[1]%b  --> Yes\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
      printf '%b[2]%b  --> No\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
      echo
      printf '[1-2]: '
      read -r "Confirm_Update_Option"
      case "$Confirm_Update_Option" in
      1)
        Update_Version force
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
    fi
  done
}

### Code for update code functions inspired by https://github.com/Adamm00 - credit to @Adamm
### and https://github.com/jackyaz/spdMerlin - credit to Jack Yaz
Update_Version() {

  DIR="$LOCAL_REPO"

  if [ -d "$DIR" ]; then
    for FILE in vpnrouting.sh \
      updown.sh \
      Advanced_OpenVPNClient_Content.asp \
      x3mRouting_client_nvram.sh \
      x3mRouting_client_config.sh \
      mount_files_lan.sh \
      mount_files_gui.sh \
      load_MANUAL_ipset.sh \
      load_ASN_ipset.sh \
      load_DNSMASQ_ipset.sh \
      load_AMAZON_ipset.sh \
      load_MANUAL_ipset_iface.sh \
      load_ASN_ipset_iface.sh \
      load_DNSMASQ_ipset_iface.sh \
      load_AMAZON_ipset_iface.sh; do
      if [ -s "$DIR/$FILE" ]; then
        if [ -z "$1" ]; then
          if [ "$FILE" != "vpnrouting.sh" ]; then
            if [ "$FILE" != "updown.sh" ]; then
              if [ "$FILE" != "Advanced_OpenVPNClient_Content.asp" ]; then
                # force_update="false"
                localver=$(grep "VERSION=" "$DIR/$FILE" | grep -m1 -oE '[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
                #	/usr/sbin/curl -fsL --retry 3 "$SPD_REPO/$SPD_NAME_LOWER.sh" | grep -qF "jackyaz" || { Print_Output "true" "404 error detected - stopping update" "$ERR"; return 1; }
                serverver=$(/usr/sbin/curl -fsL --retry 3 "$GITHUB_DIR/$FILE" | grep "VERSION=" | grep -m1 -oE '[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
                if [ "$localver" != "$serverver" ]; then
                  printf 'New version of %b%s%b available - updating to %s\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$serverver"
                  Download_File "$DIR" "$FILE"
                else
                  printf 'No new version of %b%s%b to update - latest is %s\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$serverver"
                fi
              fi
            fi
          fi
          localmd5="$(md5sum "$DIR/$FILE" | awk '{print $1}')"
          remotemd5="$(curl -fsL --retry 3 "$GITHUB_DIR/$FILE" | md5sum | awk '{print $1}')"
          if [ "$localmd5" != "$remotemd5" ]; then
            printf 'MD5 hash of %b%s%b does not match - downloading %b%s%b\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$COLOR_GREEN" "$FILE" "$COLOR_WHITE"
            Download_File "$DIR" "$FILE"
          fi
        fi

        case "$1" in
        force)
          serverver=$(/usr/sbin/curl -fsL --retry 3 "$GITHUB_DIR/$FILE" | grep "VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
          printf 'Downloading latest version ($serverver) of $FILE\n'
          Download_File "$DIR" "$FILE"
          ;;
        esac

        #    else
        #	    echo "Project Repository directory $DIR not found"
        #	    echo "Select the install option from the main menu to install the respository"
      fi
    done
  else
    echo "Project Repository directory $DIR not found"
    echo "Select the install option from the main menu to install the respository"
  fi

  echo 
  echo "Update of x3mRouting completed"
  echo "Press enter to continue"
  read -r "enter"
  Welcome_Message
}

Remove_Existing_Installation() {
  echo "Starting removal of x3mRouting Repository"

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
    for PARM in "sh $LOCAL_REPO/mount_files_lan.sh" "sh $LOCAL_REPO/mount_files_gui.sh"; do
      if grep -q "$PARM" "/jffs/scripts/init-start"; then # see if line exists
        sed -i "\\~$PARM~d" "/jffs/scripts/init-start"
        echo "$PARM entry removed from /jffs/scripts/init-start"
        echo "You can manaully delete /jffs/scripts/init-start if you no longer require it"
      fi
    done
  fi
  # TBD - ckeck if only the she-bang exists and del file it it does

  if [ "$(df | grep -c "/usr/sbin/vpnrouting.sh")" -eq 1 ]; then
    umount /usr/sbin/vpnrouting.sh
  fi
  if [ "$(df | grep -c "/usr/sbin/updown.sh")" -eq 1 ]; then
    umount /usr/sbin/updown.sh
  fi
  if [ "$(df | grep -c "/www/Advanced_OpenVPNClient_Content.asp")" -eq 1 ]; then
    umount /www/Advanced_OpenVPNClient_Content.asp
  fi

  # Purge /jffs/scripts/x3mRouting directory
  for DIR in $LOCAL_REPO; do
    if [ -d "$DIR" ]; then
      if ! rm -rf "$DIR"/* >/dev/null 2>&1; then
        printf '\nNo files found to remove in %b%s%b\n' "$COLOR_GREEN" "$DIR" "$COLOR_WHITE"
      fi
      if ! rmdir "$DIR" >/dev/null 2>&1; then
        printf '\nError trying to remove %b%s%b\n' "$COLOR_GREEN" "$DIR" "$COLOR_WHITE"
      else
        #rm -rf /jffs/scripts/install_x3mRouting.sh
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

Create_Project_Directory() {

  for DIR in $LOCAL_REPO; do
    if [ ! -d "$DIR" ]; then
      if mkdir -p "$DIR" >/dev/null 2>&1; then
        printf "Created project directory %b%s%b\\n" "${COLOR_GREEN}" "${DIR}" "${COLOR_WHITE}"
      else
        printf "Error creating directory %b%s%b. Exiting $(basename "$0")\\n" "${COLOR_GREEN}" "${DIR}" "${COLOR_WHITE}"
        exit 1
      fi
    fi
  done
}

Download_File() {

  DIR="$1"
  FILE="$2"

  STATUS="$(curl --retry 3 -sL -w '%{http_code}' "$GITHUB_DIR/$FILE" -o "$DIR/$FILE")"
  if [ "$STATUS" -eq "200" ]; then
    printf '%b%s%b downloaded successfully\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE"
    if [ "$(echo "$FILE" | grep -c '.sh')" -gt 0 ]; then
      chmod 755 "$DIR/$FILE"
    fi
  else
    printf '%b%s%b download failed with curl error %s\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$STATUS"
    printf 'Rerun the install %bx3mRouting for LAN Clients%b option\n' "$COLOR_GREEN" "$COLOR_WHITE" "$COLOR_GREEN" "$COLOR_WHITE"
    exit 1
  fi
}

Exit_Message() {

  printf '\n   %bhttps://github.com/Xentrk/Stubby-Installer-Asuswrt-Merlin%b\n' "$COLOR_GREEN" "$COLOR_WHITE\\n"
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

  PARM="$1"

  # checking for condition that user previously installed LAN clients. if so, remove mount_files_lan.sh entry
  if [ -s "/jffs/scripts/init-start" ] && [ "$PARM" = "mount_files_gui.sh" ]; then
    if grep -q "sh $LOCAL_REPO/mount_files_lan.sh" "/jffs/scripts/init-start"; then
      sed -i "\\~$LOCAL_REPO/mount_files_lan.sh~d" "/jffs/scripts/init-start"
    fi
  fi

  if [ -s "/jffs/scripts/init-start" ]; then # file exists
    if ! grep -q "$PARM" "/jffs/scripts/init-start"; then
      echo "sh $LOCAL_REPO/$PARM" >>/jffs/scripts/init-start
      printf 'Updated %b/jffs/scripts/init-start%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
    else
      printf 'Required entry already exists in %b/jffs/scripts/init-start%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
      printf 'Skipping update of %b/jffs/scripts/init-start%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
    fi
  else
    echo "#!/bin/sh" >/jffs/scripts/init-start
    echo "sh $LOCAL_REPO/$PARM" >>/jffs/scripts/init-start
    chmod 755 /jffs/scripts/init-start
    printf 'Created %b/jffs/scripts/init-start%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
  fi
}

Install_x3mRouting_LAN_Clients() {

  Create_Project_Directory
  Download_File "$LOCAL_REPO" "x3mRouting_client_nvram.sh"
  Download_File "$LOCAL_REPO" "x3mRouting_client_config.sh"
  Download_File "$LOCAL_REPO" "vpnrouting.sh"
  Download_File "$LOCAL_REPO" "updown.sh"
  Download_File "$LOCAL_REPO" "mount_files_lan.sh"
  Init_Start_Update "mount_files_lan.sh"
  sh /jffs/scripts/init-start
  echo
  echo "Installation of x3mRouting for LAN Clients completed"
  echo "Press enter to continue"
  read -r "enter"
  Welcome_Message
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

  echo "liststats () {" >>"$CONFIG_DIR/$PROFILE_FILE"
  echo "  GREEN='\033[0;32m'" >>"$CONFIG_DIR/$PROFILE_FILE"
  echo "  RED='\033[0;31m'" >>"$CONFIG_DIR/$PROFILE_FILE"
  echo "  NC='\033[0m'" >>"$CONFIG_DIR/$PROFILE_FILE"
  echo "  true > /tmp/liststats" >>"$CONFIG_DIR/$PROFILE_FILE"
  echo "  for SETLIST in \$(ipset -L -n); do" >>"$CONFIG_DIR/$PROFILE_FILE"
  echo "    printf '%s - %b%s%b\n' \"\$SETLIST\" \"\$GREEN\" \"\$((\$(ipset -L \"\$SETLIST\" | wc -l) - 8))\" \"\$NC\" >> /tmp/liststats" >>"$CONFIG_DIR/$PROFILE_FILE"
  echo "  done" >>"$CONFIG_DIR/$PROFILE_FILE"
  echo "  cat /tmp/liststats | sort" >>"$CONFIG_DIR/$PROFILE_FILE"
  echo "  rm /tmp/liststats" >>"$CONFIG_DIR/$PROFILE_FILE"
  echo "}" >>"$CONFIG_DIR/$PROFILE_FILE"
}

Check_Profile_Add() {

  CONFIG_DIR="/jffs/configs"
  PROFILE_FILE="profile.add"
  PARM="liststats"

  if [ -d "$CONFIG_DIR" ]; then
    if [ -s "$CONFIG_DIR/$PROFILE_FILE" ]; then
      if [ "$(grep -cw "$PARM" "$CONFIG_DIR/$PROFILE_FILE")" -gt 0 ]; then # see if line exists
        return
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
  Create_Project_Directory
  Download_File "$LOCAL_REPO" "vpnrouting.sh"
  Download_File "$LOCAL_REPO" "updown.sh"
  Download_File "$LOCAL_REPO" "Advanced_OpenVPNClient_Content.asp"
  Download_File "$LOCAL_REPO" "load_MANUAL_ipset.sh"
  Download_File "$LOCAL_REPO" "load_ASN_ipset.sh"
  Download_File "$LOCAL_REPO" "load_DNSMASQ_ipset.sh"
  Download_File "$LOCAL_REPO" "load_AMAZON_ipset.sh"
  Download_File "$LOCAL_REPO" "mount_files_gui.sh"
  Init_Start_Update "mount_files_gui.sh"
  sh /jffs/scripts/init-start
  Check_Profile_Add
  echo
  echo "Installation of x3mRouting for IPSET lists completed"
  echo "Press enter to continue"
  read -r "enter"
  Welcome_Message
}

Install_x3mRouting_Shell_Scripts() {
  Check_Requirements
  Create_Project_Directory
  Download_File "$LOCAL_REPO" "load_MANUAL_ipset_iface.sh"
  Download_File "$LOCAL_REPO" "load_ASN_ipset_iface.sh"
  Download_File "$LOCAL_REPO" "load_DNSMASQ_ipset_iface.sh"
  Download_File "$LOCAL_REPO" "load_AMAZON_ipset_iface.sh"
  Check_Profile_Add
  echo
  echo "Installation of x3mRouting for IPSET Shell Scripts completed"
  echo "Press enter to continue"
  read -r "enter"
  Welcome_Message
}

Update_Installer() {
  while true; do
    printf '\n\nAn updated version of the x3mRouting menu as been detected\n'
    printf 'Updating the x3mRouting menu is highly recommended.\n'
    printf 'Would you like to download the new version now?\n'
    printf '%b[1]%b  --> Yes\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[2]%b  --> No\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    echo
    printf '[1-2]: '
    read -r "menu_Update_Installer"
    echo
    case "$menu_Update_Installer" in
    1)
      Download_File /jffs/scripts install_x3mRouting.sh
      printf '\nUpdate Complete! %s\n' "$remotemd5"
      Welcome_Message
      break
      ;;
    2)
      Main_Menu
      break
      ;;
    *)
      echo "[*] $menu_Update_Installer Isn't An Option!"
      ;;
    esac
  done
}

Welcome_Message
