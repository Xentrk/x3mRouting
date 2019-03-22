# Asuswrt-Merlin-Selective-Routing
This project was written to satisfy my use case requirement to perform:
* Selective routing of LAN clients over the WAN or one of the available OpenVPN Client interfaces
* Selective routing of streaming media traffic thru three OpenVPN Client interfaces using IPSET lists.

## Selective Routing for LAN Clients
Best practice is to assign static DHCP IP addresses for LAN clients that you want to selectively route thru the WAN or one of the five OpenVPN clients available in the Asuswrt-Merlin firmware.  In the Asuswrt-Merlin firmware, one must type the IP address of each LAN client into the Policy Routing section of the OpenVPN Client screen in order to assign the LAN client to the OpenVPN Client interface.  If you have many LAN clients, the process of entering the IP address and other required information could be time consuming - especially after performing a factory reset.

The x3mRouting scripts are an alternative method to assign LAN clients to a WAN or OpenVPN Client interface.  If you have many LAN clients to assign to the interface, the scripts will eliminate the manual effort involved in typing the DHCP IP address of each LAN client in the Policy Routing section of the OpenVPN Client screen.  You can still use the OpenVPN screen to assign LAN clients in addition to the scripts. The two methods can coexist.  

##### x3mRouting_config.sh
**x3mRouting_config.sh** is the first script to run.  The script will create the file **/jffs/configs/x3mRouting_rules**.  **x3mRouting_rules** contains a separate line for each LAN client with a static DHCP IP address assignment.  Each line contains three fields separated by a space.  The first field is a number representing the interface assignment (0=WAN, 1=OVPNC1 to 5=OVPNC5) followed by the LAN client IP address and LAN client description.  

By default, the script assigns each LAN client to the OVPNC1 interface.  After running the script, edit the **/jffs/configs/x3mRouting_rules** file and assign the interface to each LAN client.  Instructions on how to assign the interface to each LAN client are located at the top of the file.  

    #########################################################
    # Assign the interface for each LAN client by entering  #
    # the appropriate interface number in the first column  #
    # 0 = WAN                                               #
    # 1 = OVPNC1                                            #
    # 2 = OVPNC2                                            #
    # 3 = OVPNC3                                            #
    # 4 = OVPNC4                                            #
    # 5 = OVPNC5                                            #
    #########################################################
    0 192.168.1.150 SamsungTV
    1 192.168.1.151 Samsung-Phone
    2 192.168.1.152 Asus-Laptop
    2 192.168.1.153 iPad
    1 192.168.1.154 Lenovo-Laptop


If an existing **/jffs/configs/x3mRouting_rules** file exists, a backup copy of the existing **x3mRouting_rules** file is made by appending the timestamp to the existing file.  You only need to run this script if you have made changes to DHCP static assignments or accidently deleted the **/jffs/configs/x3mRouting_rules** file.  

##### x3mRouting_client_nvram.sh
**x3mRouting_client_nvram.sh** is the second script to run.  This script will create the nvram files for OpenVPN clients in the **/jffs/configs** directory for each interface assignment e.g. **/jffs/configs/ovpnc1.nvram**.  If a LAN client is not assigned to use an OpenVPN interface, an nvram file will not be created, as the LAN client will automatically default to the WAN interface.

Similar to the firmware, the final step is to bounce the OpenVPN Client interface to have the LAN client assignments take effect.  This is accomplished by selecting the “Apply” button on the OpenVPN Client screen you assigned the LAN client to.  Alternatively, you can bounce the WAN interface by selecting the “Apply” button on the WAN screen as doing so will also restart any active OpenVPN clients.  If you prefer, you can manually restart an OpenVPN Client from an SSH session using the command service **restart_vpnclientx**, where the **x** represents the OpenVPN Client number.  Just remember there is a slight delay before the OpenVPN Client becomes active.  Check the OpenVPN Client status using the OpenVPN Status page.   

The selective routing rules for LAN Clients will automatically be applied upon a system reboot.  You only need to rerun **x3mRouting_client_nvram.sh** and bounce the OpenVPN client if you have made LAN Client interface assignment changes in the **/jffs/configs/x3mRouting_rules** file.  

To make this work, the install script will also download customized versions of the **vpnrouting.sh** and **updown.sh** scripts used by the firmware.  It will not replace or delete the firmware versions of the **vpnrouting.sh** and **updown.sh** scripts.  Rather, it will store the customized versions of the files in the project directory and inform the firmware to use the project versions of the files by mapping the modified scripts to the original firmware versions thru the use of a mount command.

init-start for mounting vpnrouting.sh and updown.sh

## Selective Routing of IPSET Lists using the OpenVPN Client Screen
As part of this project, you can also choose to download and install a modified OpenVPN Client screen to selectively route IPSET lists thru an OpenVPN Client.  Similar to the **vpnrouting.sh** and **updown.sh** script, the installer will not replace or delete the firmware version of the OpeVPN Client web page.  Rather, it will store the customized version of the web page in the project directory and inform the firmware to use the project version of the file by mapping the modified scripts to the original firmware versions thru the use of a mount command.

@Martineau coded the revisions made to the OpenVPN Client screen as a proof of concept on how the Policy Rules section could be modified to incorporate the selective routing of IPSET lists.

![Image of OpenVPN Client Screen](https://github.com/Xentrk/Asuswrt-Merlin-Selective-Routing/OpenVPN_Client_GUI.PNG)

A video tutorial on how to allow the use of IPSET lists via the Selective routing VPN Client Policy Routing table GUI can be viewed on [vimeo](https://vimeo.com/287067217).

##### DummyVPN
In the screen picture above, you will notice an entry for **DummyVPN1**.  For the Selective routing of Ports/MACs and IPSETs, Martineau recommends that you create a “dummy” VPN Client entry if you require the ability to exploit the **Accept DNS Configuration=EXCLUSIVE** option that only creates the appropriate DNSVPN iptable chains if the table isn't empty.  Use a valid IPv4 address for the DummyVPN entry that differs from your LAN IPv4 address range.    

### Creating IPSET lists
The following scripts will assist users in creating IPSET lists.  Different scripts exists depending on the source of the IPSET list.  In order to have the IPSET lists restored at boot, execute the scripts from **/jffs/scripts/nat-start**.  The scripts will store backup copies in the **/opt/tmp** directory on entware.  This will allow the lists to be restored on system boot.  Refer to the [Wiki](https://github.com/RMerl/asuswrt-merlin/wiki/User-scripts#creating-scripts ) for instructions on how to configure nat-start.

##### load_AMAZON_ipset.sh
This script will create an IPSET list called AMAZON containing all IPv4 address for the Amazon AWS US region.  The IPSET list is required to route Amazon Prime traffic.  The script must also be used in combination with the NETFLIX IPSET list to selectively route Netflix traffic since Netflix hosts on Amazon AWS servers.  

Usage example:

    sh /jffs/scripts/Asuswrt-Merlin-Selective-Routing/load_AMAZON_ipset.sh

##### load_MANUAL_ipset.sh
This script will create an IPSET list from a file containing IPv4 addresses stored in the **/opt/tmp** directory on entware.  For example, I mined the domain names from dnsmasq for BBC and converted the domain names to their respective IPv4 addresses.  You must pass the script the IPSET list name.  The IPSET list name must match the name of the file containing the IPv4 addresses stored in **/opt/tmp**.

Usage example:

    sh /jffs/scripts/Asuswrt-Merlin-Selective-Routing/load_MANUAL_ipset.sh BBC

##### load_ASN_ipset.sh
This script will create an IPSET list using the AS Number.  The IPv4 addresses are downloaded from https://ipinfo.io/. https://ipinfo.io/ may require whitelisting if you use an ad-blocker program.  You must pass the script the name of the IPSET list followed by the AS Number.  

Usage example:

    sh /jffs/scripts/Asuswrt-Merlin-Selective-Routing/load_ASN_ipset.sh NETFLIX AS2906
    sh /jffs/scripts/Asuswrt-Merlin-Selective-Routing/load_ASN_ipset.sh SLINGTV AS35873

##### load_DNSMASQ_ipset.sh
This script will create an IPSET list using the ipset feature inside of dnsmasq to collect IPv4 addresses when the domain is looked up by dnsmasq.  The script will also create a cron job to backup the list every 24 hours to the **/opt/tmp** directory so the IPSET list can be restored on system boot.  Pass the script the name of the IPSET list followed by the domain names separated by a comma.     

Usage example:

    sh /jffs/scripts/Asuswrt-Merlin-Selective-Routing/load_DNSMASQ_ipset.sh BBC_WEB bbc.com,bbci.co.uk,bbc.co.uk
