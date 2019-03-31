#!/bin/sh
####################################################################################################
# Script: install_x3mRouting.sh
# Original Author: Xentrk
# Last Updated Date: 31-March-2019
#
# Description:
#  Install, Update or Remove the Asuswrt-Merlin-Selective-Routing repository
#
# Acknowledgement:
#  This project would never have been made possible if not for @Martineau on snbfourms.com
#  providing his Selective Routing knowledge and expertise. I am extemely GRATEFUL!
#
####################################################################################################
export PATH=/sbin:/bin:/usr/sbin:/usr/bin$PATH
logger -t "($(basename "$0"))" "$$ Starting Script Execution ($(if [ -n "$1" ]; then echo "$1"; else echo "menu"; fi))"
VERSION="1.0.0"
GIT_REPO="Asuswrt-Merlin-Selective-Routing"
GITHUB_DIR="https://raw.githubusercontent.com/Xentrk/$GIT_REPO/master"

# Uncomment the line below for debugging
#set -x

COLOR_RED='\033[0;31m'
COLOR_WHITE='\033[0m'
COLOR_GREEN='\e[0;32m'

welcome_message() {
  while true; do
    printf '\n_______________________________________________________________________\n'
    printf '|                                                                     |\n'
    printf '|  Welcome to the %bx3mRouting%b installation script |\n' "$COLOR_GREEN" "$COLOR_WHITE"
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
    printf '| %bhttps://github.com/Xentrk/Asuswrt-Merlin-Selective-Routing%b           |\n' "$COLOR_GREEN" "$COLOR_WHITE"
    printf '| for helpful tips.                                                   |\n'
    printf '|_____________________________________________________________________|\n\n'
    if [ "$1" = "uninstall" ]; then
      menu1="2"
    else
      localmd5="$(md5sum "$0" | awk '{print $1}')"
      remotemd5="$(curl -fsL --retry 3 "${GITHUB_DIR}/install_x3mRouting.sh" | md5sum | awk '{print $1}')"
      if [ "$localmd5" != "$remotemd5" ]; then
        update_installer
      fi
      printf '%b[1]%b = Install Selective Routing for LAN Clients\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
      printf '%b[2]%b = Install Selective Routing for IPSET lists\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
      printf '%b[3]%b = Update current Selective Routing installation\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
      printf '%b[4]%b = Remove x3mRouting Repository\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
      printf '\n%b[e]%b = Exit Script\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
      printf '\n%bOption ==>%b ' "${COLOR_GREEN}" "${COLOR_WHITE}"
      read -r "menu1"
    fi
    case "$menu1" in
    1)
      install_x3mRouting_LAN_clients
      break
      ;;
    2)
      install_x3mRouting_IPSET_lists
      break
      ;;
    3)
      update_current_installation
      break
      ;;
    4)
      validate_removal
      break
      ;;
    e)
      exit_message
      break
      ;;
    *)
      printf '%bInvalid Option%b %s%b Please enter a valid option\n' "$COLOR_RED" "$COLOR_GREEN" "$menu1" "$COLOR_WHITE"
      ;;
    esac
  done
}

validate_removal() {
  while true; do
    printf 'Are you sure you want to uninstall the %bAsuswrt-Merlin-Selective-Routing Repository%b\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf 'and all changes made by the installer?\n'
    printf '%b[y]%b --> Yes \n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[n]%b --> Cancel\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[e]%b --> Exit Script\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '\n%bOption ==>%b ' "${COLOR_GREEN}" "${COLOR_WHITE}"
    read -r "menu3"
    case "$menu3" in
    y)
      remove_existing_installation
      break
      ;;
    n)
      welcome_message
      break
      ;;
    e)
      exit_message
      break
      ;;
    *)
      printf '%bInvalid Option%b %s%b Please enter a valid option\n' "$COLOR_RED" "$COLOR_GREEN" "$menu3" "$COLOR_WHITE"
      ;;
    esac
  done
}

update_current_installation() {
  while true; do
    printf '\n\nThis option will check your current installation and update any files that have changed\n'
    printf 'since you last installed the repository.  Updating is highly recommended to get the most recent.\n'
    printf 'files. Chosing this option will not update missing files. Select the install option from the\n'
    printf 'menu to reinstall the files\n'
    printf 'Would you like to download and update any new version now?\n'
    echo "[1]  --> Yes"
    echo "[2]  --> No"
    echo
    printf "[1-2]: "
    read -r "menu_update_current_installation"
    echo
    case "$menu_update_current_installation" in
    1)
      update_current_installation_2
      welcome_message
      break
      ;;
    2)
      welcome_message
      break
      ;;
    *)
      echo "[*] $menu_update_installer Isn't An Option!"
      ;;
    esac
  done
}

update_current_installation_2() {
  DIR="/jffs/scripts/Asuswrt-Merlin-Selective-Routing"
  if [ -d "$DIR" ]; then
    for FILE in x3mRouting_client_nvram.sh \
                x3mRouting_config.sh \
                vpnrouting.sh \
                updown.sh \
                Advanced_OpenVPNClient_Content.asp \
                load_MANUAL_ipset.sh \
                load_ASN_ipset.sh \
                load_DNSMASQ_ipset.sh \
                load_AMAZON_ipset.sh; do
      if [ -s "$DIR/$FILE" ]; then
        localmd5="$(md5sum "$DIR/$FILE" | awk '{print $1}')"
        remotemd5="$(curl -fsL --retry 3 "${GITHUB_DIR}/$FILE" | md5sum | awk '{print $1}')"
        if [ "$localmd5" != "$remotemd5" ]; then
          downloaded_file "$DIR" "$FILE"
        fi
    done
  else
    echo "Project Repository directory $DIR not found"
    echo "Select the install option from the main menu to install the respository"
  fi
}

remove_existing_installation() {
  echo "Starting removal of Asuswrt-Merlin-Selective-Routing Repository"

  # Remove the jq package
  Chk_Entware jq
  if [ "$READY" -eq "0" ]; then
    echo "Existing jq package found. Removing jq"
    if opkg remove jq; then echo "jq successfully removed"; else echo "Error occurred when removing jq"; fi
  else
    echo "Unable to remove the jq package. Entware is not mounted"
  fi

  # Remove entries from /jffs/scripts/init-start
  if [ -s "/jffs/scripts/init-start" ]; then # file exists
    for PARM in "sh /jffs/scripts/Asuswrt-Merlin-Selective-Routing/mount_files_lan.sh" "sh /jffs/scripts/Asuswrt-Merlin-Selective-Routing/mount_files_ipset.sh"; do
      if grep -q "$PARM" "/jffs/scripts/init-start"; then # see if line exists
        sed -i "\\~$PARM~d" "/jffs/scripts/init-start"
        echo "$PARM entry removed from /jffs/scripts/init-start"
        echo "manaully delete /jffs/scripts/init-start if you no longer require it"
      fi
    done
  fi
  # TBD - ckeck if only the she-bang exists and del file it it does

  # Purge /jffs/scripts/Asuswrt-Merlin-Selective-Routing directory
  for DIR in "/jffs/scripts/Asuswrt-Merlin-Selective-Routing"; do
    if [ -d "$DIR" ]; then
      if ! rm "$DIR"/* >/dev/null 2>&1; then
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

create_project_directory() {
  for DIR in "/jffs/scripts/Asuswrt-Merlin-Selective-Routing"; do
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

download_file() {
  DIR="$1"
  FILE="$2"
  STATUS="$(curl --retry 3 -sL -w '%{http_code}' "$GITHUB_DIR/$FILE" -o "$DIR/$FILE")"
  if [ "$STATUS" -eq "200" ]; then
    printf '%b%s%b downloaded successfully\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE"
  else
    printf '%b%s%b download failed with curl error %s\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$STATUS"
    printf 'Rerun the install %bx3mRouting for LAN Clients%b option\n' "$COLOR_GREEN" "$COLOR_WHITE" "$COLOR_GREEN" "$COLOR_WHITE"
    exit 1
  fi
}

exit_message() {
  printf '\n   %bhttps://github.com/Xentrk/Stubby-Installer-Asuswrt-Merlin%b\n' "$COLOR_GREEN" "$COLOR_WHITE\\n"
  printf '                      Have a Grateful Day!\n\n'
  printf '           ____        _         _                           \n'
  printf '          |__  |      | |       | |                          \n'
  printf '    __  __  _| |_ _ _ | |_  ___ | | __    ____ ____  _ _ _   \n'
  printf '    \ \/ / |_  | %b %b \  __|/ _ \| |/ /   /  _//    \| %b %b \ \n' "\`" "\`" "\`" "\`"
  printf '     /  /  __| | | | |  |_ | __/|   <   (  (_ | [] || | | |  \n'
  printf '    /_/\_\|___ |_|_|_|\___|\___||_|\_\[] \___\\\____/|_|_|_| \n\n\n'
  rm -rf /tmp/stubby.lock
  exit 0
}

init_start_update() {
  PARM=$1
  # checking for condition that user previously installed LAN clients. if so, remove mount_files_lan.sh entry
  if [ -s "/jffs/scripts/init-start" ] && [ "$PARM" = "sh /jffs/scripts/Asuswrt-Merlin-Selective-Routing/mount_files_ipset.sh" ]; then
    if grep -q "sh /jffs/scripts/Asuswrt-Merlin-Selective-Routing/mount_files_lan.sh" "/jffs/scripts/init-start"; then
      sed -i "\\~/jffs/scripts/Asuswrt-Merlin-Selective-Routing/mount_files_lan.sh~d" "/jffs/scripts/init-start"
    fi
  fi

  if [ -s "/jffs/scripts/init-start" ]; then # file exists
    if ! grep -q "$PARM" "/jffs/scripts/init-start"; then
      echo "$PARM" >>/jffs/scripts/init-start
      printf 'Updated %b/jffs/scripts/init-start%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
    else
      printf 'Required entry already exists in %b/jffs/scripts/init-start%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
      printf 'Skipping update of %b/jffs/scripts/init-start%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
    fi
  else
    echo "#!/bin/sh" >/jffs/scripts/init-start
    echo "$PARM" >>/jffs/scripts/init-start
    chmod 755 /jffs/scripts/init-start
    printf 'Created %b/jffs/scripts/init-start%b\n' "$COLOR_GREEN" "$COLOR_WHITE"
  fi
}

install_x3mRouting_LAN_clients() {
  # check for stubby folders with no files
  create_project_directory
  download_file /jffs/scripts/Asuswrt-Merlin-Selective-Routing x3mRouting_client_nvram.sh
  download_file /jffs/scripts/Asuswrt-Merlin-Selective-Routing x3mRouting_config.sh
  download_file /jffs/scripts/Asuswrt-Merlin-Selective-Routing vpnrouting.sh
  download_file /jffs/scripts/Asuswrt-Merlin-Selective-Routing updown.sh
  download_file /jffs/scripts/Asuswrt-Merlin-Selective-Routing mount_files_lan.sh
  init_start_update "sh /jffs/scripts/Asuswrt-Merlin-Selective-Routing/mount_files_lan.sh"
  echo "Installation of x3mRouting for LAN Clients completed"
}

install_x3mRouting_IPSET_lists() {
  if Chk_Entware; then
    if opkg update >/dev/null 2>&1; then
      echo "Entware package list successfully updated"
      # load_AMAZON_ipset.sh requires the jq package to extract the Amazon json file
      if opkg install jq --force-downgrade; then
        echo "jq successfully installed"
      else
        echo "An error occurred installing jq"
        exit 1
      fi
    else
      echo "An error occurred updating Entware package list"
      exit 1
    fi
  else
    echo "You must first install Entware before proceeding"
    printf 'Exiting %s\n' "$(basename "$0")"
    exit 1
  fi

  create_project_directory
  download_file /jffs/scripts/Asuswrt-Merlin-Selective-Routing vpnrouting.sh
  download_file /jffs/scripts/Asuswrt-Merlin-Selective-Routing updown.sh
  download_file /jffs/scripts/Asuswrt-Merlin-Selective-Routing Advanced_OpenVPNClient_Content.asp
  download_file /jffs/scripts/Asuswrt-Merlin-Selective-Routing load_MANUAL_ipset.sh
  download_file /jffs/scripts/Asuswrt-Merlin-Selective-Routing load_ASN_ipset.sh
  download_file /jffs/scripts/Asuswrt-Merlin-Selective-Routing load_DNSMASQ_ipset.sh
  download_file /jffs/scripts/Asuswrt-Merlin-Selective-Routing load_AMAZON_ipset.sh
  download_file /jffs/scripts/Asuswrt-Merlin-Selective-Routing mount_files_ipset.sh
  init_start_update "sh /jffs/scripts/Asuswrt-Merlin-Selective-Routing/mount_files_ipset.sh"
  echo "Installation of x3mRouting for IPSET lists completed"
}

update_installer() {
  while true; do
    printf '\n\nAn updated version of the x3mRouting menu as been detected\n'
    printf 'Updating the x3mRouting menu is highly recommended.\n'
    printf 'Would you like to download the new version now?\n'
    echo "[1]  --> Yes"
    echo "[2]  --> No"
    echo
    printf "[1-2]: "
    read -r "menu_update_installer"
    echo
    case "$menu_update_installer" in
    1)
      download_file /jffs/scripts install_x3mRouting.sh
      printf '\nUpdate Complete! %s\n' "$remotemd5"
      welcome_message
      break
      ;;
    2)
      welcome_message
      break
      ;;
    *)
      echo "[*] $menu_update_installer Isn't An Option!"
      ;;
    esac
  done
}

clear
welcome_message
