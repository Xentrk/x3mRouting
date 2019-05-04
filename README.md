# x3mRouting ~ Selective Routing for Asuswrt-Merlin Firmware
## Introduction
The features of **x3mRouting** include an alternative method to selectively route LAN Clients in the Asuswrt-Merlin firmware and two alternative methods for selectively routing traffic using IPSET lists.

## x3mRouting Methods

### x3mRouting LAN Client Method
In the Asuswrt-Merlin firmware, one must type the IP address of each LAN client into the Policy Routing section of the OpenVPN Client screen in order to assign the LAN client to the OpenVPN Client interface.  If you have many LAN clients, the process of entering the IP address and other required information could be time consuming - especially after performing a factory reset.

The x3mRouting LAN Client method is an alternative approach to assigning LAN clients to a WAN or OpenVPN Client interface.  If you have many LAN clients to assign to the interface, the scripts will eliminate the manual effort involved in typing the DHCP IP address of each LAN client in the Policy Routing section of the OpenVPN Client screen.  You can still use the OpenVPN screen to assign LAN clients in addition to the scripts. The two methods can coexist.  

#### x3mRouting_client_config.sh
**x3mRouting_client_config.sh** is the first script to run.  The script will create the file **/jffs/configs/x3mRouting_client_rules** which contains a separate line for each LAN client with a static DHCP IP address assignment.  Each line contains three fields separated by a space.  The first field is a number representing the interface assignment (0=WAN, 1=OVPNC1 to 5=OVPNC5) followed by the LAN client IP address and LAN client description.  

By default, the script assigns each LAN client to the OVPNC1 interface.  After running the script, edit the **/jffs/configs/x3mRouting_client_rules** file and assign the interface to each LAN client.  Instructions on how to assign the interface to each LAN client are located at the top of the file.  

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

If an existing **/jffs/configs/x3mRouting_client_rules** file exists, a backup copy of the existing **x3mRouting_client_rules** file is made by appending the timestamp to the existing file.  You only need to run this script if you have made changes to DHCP static assignments or accidently deleted the **/jffs/configs/x3mRouting_client_rules** file.  

#### x3mRouting_client_nvram.sh
**x3mRouting_client_nvram.sh** is the second script to run. This script will create the nvram files
(e.g. **/jffs/configs/ovpnc1.nvram**) for OpenVPN clients in the **/jffs/configs** directory based on the interface assignments in **/jffs/configs/x3mRouting_client_rules**. An nvram file will not be created in the **/jffs/configs/** directory for LAN clients assigned to use the WAN interface.

Similar to the firmware, the next step is to bounce the OpenVPN Client interface to have the routing assignments take effect.  This is accomplished by selecting the **“Apply”** button on the OpenVPN Client screen you assigned the LAN client to.  Alternatively, you can bounce the WAN interface by selecting the **“Apply”** button on the WAN screen. Restarting the WAN will also restart any active OpenVPN clients. There is a slight delay before the OpenVPN Client becomes active. Check the OpenVPN Client status using the OpenVPN Status page.

The routing rules for LAN Clients will automatically be applied upon a system boot.  You only need to rerun **x3mRouting_client_nvram.sh** and bounce the OpenVPN client if you have made LAN Client interface assignment changes in the **/jffs/configs/x3mRouting_client_rules** file.  

For the **x3Routing for LAN Clients** to work, the install script will also download customized versions of the **vpnrouting.sh** and **updown.sh** scripts used by the firmware.  *These scripts will not replace or delete the firmware versions* of the **vpnrouting.sh** and **updown.sh** scripts.  Rather, it will store the customized versions of the files in the project directory **/jffs/scripts/x3mRouting** and inform the firmware to use the project versions of the files by mapping the modified scripts to the original firmware versions using the **mount** command.

The installation script will also insert a line in **/jffs/scripts/init-start** to execute a script to mount **vpnrouting.sh** and **updown.sh** on system boot.

### x3mRouting OpenVPN Client Screen & IPSET Shell Script Method
As part of this project, you can also choose to download and install a modified OpenVPN Client screen to selectively route IPSET lists thru an OpenVPN Client.  Similar to the **vpnrouting.sh** and **updown.sh** script, the installer will not replace or delete the firmware version of the OpenVPN Client web page.  Rather, it will store the customized version of the web page in the project directory and inform the firmware to use the project version of the file by mapping the modified scripts to the original firmware versions using the **mount** command.

[@Martineau](https://www.snbforums.com/members/martineau.13215/) coded the revisions to the OpenVPN Client screen as a proof of concept on how the Policy Rules section could be modified to incorporate the selective routing of IPSET lists. I greatly appreciate his generosity in providing the modified code and allowing me to include it in the project.

![Image of OpenVPN Client Screen](https://github.com/Xentrk/x3mRouting/OpenVPN_Client_GUI.PNG)

#### Video Tutorial

A video tutorial on how to allow the use of IPSET lists via the Selective routing VPN Client Policy Routing Screen can be viewed on [Vimeo](https://vimeo.com/287067217).

#### DummyVPN
In the screen picture above, you will notice an entry for **DummyVPN1**.  For the Selective routing of Ports/MACs and IPSETs, [@Martineau](https://www.snbforums.com/members/martineau.13215/) recommends creating a “dummy” VPN Client entry if you require the ability to exploit the **Accept DNS Configuration=Exclusive** option that only creates the appropriate DNSVPN iptable chains if the table isn't empty.  Use a valid IPv4 address for the DummyVPN entry that differs from your LAN IPv4 address range. I recommend using a [bogon IP addres](https://ipinfo.io/bogon) for this purpose.    

#### Creating IPSET lists
The following scripts will assist users in creating IPSET lists. Different scripts exists depending on the source of the IPSET list.

#### IPSET Save/Restore File Location
By default, all of the scripts will store backup copies of the IPSET lists in the **/opt/tmp** entware directory. This will allow the IPSET lists to be restored on system boot. If you prefer, you can specify another directory location by passing a directory parameter to the script. Usage examples are provided below.

#### IPSET Shell Script Usage Examples for use with the modified OpenVPN Client Screen

##### load_AMAZON_ipset.sh
This script will create an IPSET list called AMAZON containing all IPv4 address for the Amazon AWS US region. The source file used by the script is provided by Amazon at https://ip-ranges.amazonaws.com/ip-ranges.json. The AMAZON IPSET list is required to route Amazon Prime traffic.  The script must also be used in combination with the NETFLIX IPSET list to selectively route Netflix traffic as Netflix hosts on Amazon AWS servers.  

Usage:

    load_AMAZON_ipset.sh [dir='directory'] [del]

Create the AMAZON IPSET list and use the **/opt/tmp** directory for the IPSET save/restore file location:

    load_AMAZON_ipset.sh

Create the AMAZON IPSET list and use the **/mnt/sda1/Backups** directory rather than Entware's **/opt/tmp** directory for the IPSET save/restore file location:

    load_AMAZON_ipset.sh dir=/mnt/sda1/Backups

Delete IPSET AMAZON:

    load_AMAZON_ipset.sh del

##### load_MANUAL_ipset.sh
This script will create an IPSET list from a file containing IPv4 addresses. For example, I mined the domain names for BBC from dnsmasq and converted the domain names to their respective IPv4 addresses. You must pass the script the IPSET list name. The IPSET list name must match the name of the file containing the IPv4 addresses.

Usage:

    load_MANUAL_ipset.sh ipset_name [del] [dir='directory']

Create IPSET BBC and use the default **/opt/tmp** directory as the IPSET save/restore location:

    load_MANUAL_ipset.sh BBC

Create IPSET BBC and use the **/mnt/sda1/Backups** directory rather than the default **/opt/tmp** directory for IPSET save/restore location:

    load_MANUAL_ipset.sh BBC dir=/mnt/sda1/Backups

Delete IPSET BBC:

    load_MANUAL_ipset.sh BBC del

##### load_ASN_ipset.sh
This script will create an IPSET list using the [AS Number](https://www.apnic.net/get-ip/faqs/asn/).  The IPv4 addresses are downloaded from https://ipinfo.io/. https://ipinfo.io/ may require whitelisting if you use an ad-blocker program.  You must pass the script the name of the IPSET list followed by the AS Number.  

Usage example:

    load_ASN_ipset.sh ipset_name ASN [del] [dir='directory']

Create IPSET NETFLIX and use the default **/opt/tmp** directory as the IPSET save/restore location:

    load_ASN_ipset.sh NETFLIX AS2906

Create IPSET NETFLIX and use the **/mnt/sda1/Backups** directory rather than the default **/opt/tmp** directory for IPSET save/restore location:

    load_ASN_ipset.sh NETFLIX AS2906 dir=/mnt/sda1/Backups

Delete IPSET NETFLIX:

    load_ASN_ipset.sh NETFLIX del

##### load_DNSMASQ_ipset.sh
This script will create an IPSET list using the IPSET feature inside of dnsmasq to collect IPv4 addresses. The script will also create a cron job to backup the list every 24 hours to the **/opt/tmp** directory so the IPSET list can be restored on system boot.  Pass the script the name of the IPSET list followed by the domain names separated by a comma.

Usage example:

    load_DNSMASQ_ipset.sh ipset_name domains[,...]} ['autoscan'] [del]  [dir='directory']

Create IPSET BBC and auto populate IPs for domain 'bbc.co.uk'

    load_DNSMASQ_ipset_iface.sh BBC bbc.co.uk

Delete IPSET BBC and associated entry in dnsmasq.conf.add:

    load_DNSMASQ_ipset.sh BBC bbc.co.uk del

Create IPSET BBC and use the **/mnt/sda1/Backups** directory rather than the default **/opt/tmp** directory for IPSET save/restore location:

    load_DNSMASQ_ipset_iface.sh BBC bbc.co.uk dir=/mnt/sda1/Backups

Create IPSET NETFLIX and auto populate IPs for multiple Netflix domains

    load_DNSMASQ_ipset_iface.sh NETFLIX amazonaws.com,netflix.com,nflxext.com,nflximg.net,nflxso.net,nflxvideo.net

Create IPSET SKY and extract all matching Top-Level domains containing 'sky.com' from '/opt/var/log/dnsmasq.log'

    load_DNSMASQ_ipset.sh SKY sky.com autoscan

Example:

    ipset=/akadns.net/edgekey.net/edgesuite.net/epgsky.com/sky.com/SKY from 'a674.hsar.cdn.sky.com.edgesuite.net/adm.sky.com/assets.sky.com/assets.sky.com-secure.edgekey.net/awk.epgsky.com' etc...

In order to have the IPSET lists restored at boot, execute the scripts from **/jffs/scripts/nat-start**. Refer to the [Wiki](https://github.com/RMerl/asuswrt-merlin/wiki/User-scripts#creating-scripts ) for instructions on how to configure nat-start.

#### /jffs/scripts/nat-start example
Following is an exammple of how I have configured /**jffs/scripts/nat-start** to create the IPSET lists I use for streaming media traffic at system boot.

    #!/bin/sh
    sh /jffs/scripts/x3mRouting/load_AMAZON_ipset.sh

    sh /jffs/scripts/x3mRouting/load_MANUAL_ipset.sh BBC
    sh /jffs/scripts/x3mRouting/load_MANUAL_ipset.sh BBC_IPLAYER
    sh /jffs/scripts/x3mRouting/load_MANUAL_ipset.sh CBS
    sh /jffs/scripts/x3mRouting/load_MANUAL_ipset.sh SLINGTV_LIST

    sh /jffs/scripts/x3mRouting/load_ASN_ipset.sh HULU AS23286
    sh /jffs/scripts/x3mRouting/load_ASN_ipset.sh NETFLIX AS2906
    sh /jffs/scripts/x3mRouting/load_ASN_ipset.sh SLINGTV AS35873

    sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset.sh HULU_WEB hulu.com,hulustream.com,akamaihd.net
    sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset.sh CBS_WEB cbs.com,cbsnews.com,cbssports.com,cbsaavideo.com,omtrdc.net,akamaihd.net,irdeto.com,cbsi.com,cbsig.net
    sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset.sh BBC_WEB bbc.co.uk,bbc.com,bbc.gscontxt.net,bbci.co.uk,bbctvapps.co.uk,ssl-bbcsmarttv.2cnt.net,llnwd.net

### x3mRouting using the IPSET Shell Script Method
This method is intended for users who want the ability to create and route traffic using IPSET lists, but prefer to use Asuswrt-Merlin firmware without the firmware modifications utilized by the method listed above.

The difference with the scripts above is the ability to pass the interface parameter to the script to specify either the WAN or one of the five OpenVPN Client interfaces.

#### Creating IPSET lists
The following scripts will assist users in creating IPSET lists. Different scripts exists depending on the source of the IPSET list. In order to have the IPSET lists restored at boot, execute the scripts from **/jffs/scripts/nat-start**. Refer to the [Wiki](https://github.com/RMerl/asuswrt-merlin/wiki/User-scripts#creating-scripts ) for instructions on how to configure nat-start.

By default, the scripts will store backup copies in the **/opt/tmp** directory on entware. This will allow the IPSET lists to be restored on system boot.

#### IPSET Save/Restore File Location
By default, all of the scripts will store backup copies of the IPSET lists in the **/opt/tmp** entware directory. This will allow the IPSET lists to be restored on system boot. If you prefer, you can specify another directory location by passing a directory parameter to the script. Usage examples are provided below.

##### load_AMAZON_ipset_iface.sh
This script will create an IPSET list called AMAZON containing all IPv4 address for the Amazon AWS US region. The source file used by the script is provided by Amazon at https://ip-ranges.amazonaws.com/ip-ranges.json. The AMAZON IPSET list is required to route Amazon Prime traffic. The script must also be used in combination with the NETFLIX IPSET list to selectively route Netflix traffic as Netflix hosts on Amazon AWS servers.  

Usage:

    load_AMAZON_ipset_iface.sh {[0|1|2|3|4|5]} [del] [dir='directory']

Create the AMAZON IPSET list via VPN Client 2 and use the **/opt/tmp** directory for the IPSET save/restore file location:

    load_AMAZON_ipset_iface.sh 2

Create the AMAZON IPSET list via VPN Client 2 and use the **/mnt/sda1/Backups** directory rather than the **/opt/tmp** directory for the IPSET save/restore location:

    load_AMAZON_ipset_iface.sh 2 dir=/mnt/sda1/Backups

Delete IPSET list AMAZON and remove from VPN Client 2:

    load_AMAZON_ipset_iface.sh 2 del

##### load_MANUAL_ipset_iface.sh
This script will create an IPSET list from a file containing IPv4 addresses stored in the **/opt/tmp** directory on entware. For example, I mined the domain names from dnsmasq for BBC and converted the domain names to their respective IPv4 addresses. You must pass the script the IPSET list name. The IPSET list name must match the name of the file containing the IPv4 addresses stored in **/opt/tmp**.

Usage:

    load_MANUAL_ipset.sh {[0|1|2|3|4|5]} ipset_name [del] [dir='directory']

Create IPSET BBC via VPN Client 3 and use the default **/opt/tmp** directory as the IPSET save/restore location:

    load_MANUAL_ipset_iface.sh BBC 3

Create IPSET BBC via VPN Client 3 and use the **/mnt/sda1/Backups** directory rather than the default **/opt/tmp** directory for IPSET save/restore location:

    load_MANUAL_ipset_iface.sh BBC 3 dir=/mnt/sda1/Backups

Create IPSET BBC via VPN Client 3 and use the **/mnt/sda1/Backups** directory rather than the default **/opt/tmp** directory for IPSET save/restore location:

    load_MANUAL_ipset_iface.sh 3 BBC

##### load_ASN_ipset_iface.sh
This script will create an IPSET list using the [AS Number](https://www.apnic.net/get-ip/faqs/asn/). The IPv4 addresses are downloaded from https://ipinfo.io/. https://ipinfo.io/ may require whitelisting if you use an ad-blocker program.  You must pass the script the name of the IPSET list followed by the AS Number.  

Usage example:

    load_ASN_ipset_iface.sh {[0|1|2|3|4|5]} ipset_name ASN [del] [dir='directory']

Create IPSET NETFLIX from AS2906 via VPN Client 2:

    load_ASN_ipset_iface.sh 2 NETFLIX AS2906

Create IPSET NETFLIX from AS2906 via VPN Client 2, but use the **/mnt/sda1/Backups** directory rather than the default **opt/tmp** as the IPSET save/restore file location:

    load_ASN_ipset_iface.sh 2 NETFLIX AS2906 dir=/mnt/sda1/Backups

Delete IPSET NETFLIX and remove routing via VPN Client 2 (the AS Number is not required when using the delete function):

    load_ASN_ipset_iface.sh 2 NETFLIX del

##### load_DNSMASQ_ipset_iface.sh
This script will create an IPSET list using the IPSET feature inside of dnsmasq to collect IPv4 addresses. The script will also create a cron job to backup the list every 24 hours to the **/opt/tmp** directory so the IPSET list can be restored on system boot.  Pass the script the name of the IPSET list followed by the domain names separated by a comma.

Usage example:

    load_DNSMASQ_ipset_iface.sh   {[0|1|2|3|4|5]  ipset_name  domains[,...]} ['autoscan'] [del]  [dir='directory']

Create IPSET BBC via VPN Client 3 and auto populate IPs for domain **bbc.co.uk**:

    load_DNSMASQ_ipset_iface.sh 3 BBC bbc.co.uk

Create IPSET BBC via VPN Client 3 and auto populate IPs for domain **bbc.co.uk**, but use **/mnt/sda1/Backups** directory rather than the **opt/tmp** directory for the IPSET  save/restore

    load_DNSMASQ_ipset_iface.sh 3 BBC bbc.co.uk dir=/mnt/sda1/Backups

Delete IPSET BBC and remove from VPN Client 3:
    load_DNSMASQ_ipset_iface.sh 3 BBC bbc.co.uk del

Create IPSET NETFLIX via WAN and auto populate IPs for multiple Netflix domains

    load_DNSMASQ_ipset_iface.sh 0 NETFLIX amazonaws.com,netflix.com,nflxext.com,nflximg.net,nflxso.net,nflxvideo.net

Create IPSET SKY and extract all matching Top-Level domains containing **sky.com** from **/opt/var/log/dnsmasq.log**:

    load_DNSMASQ_ipset_iface.sh 2 SKY sky.com autoscan

For example, the following entry will be created in **/jffs/configs/dnsmasq.confg.add**:

    ipset=/edgesuite.net/sky.com/edgekey.net/epgsky.com/SKY

from the following entries in **/opt/var/log/dnsmasq.log**:

    a674.hsar.cdn.sky.com.edgesuite.net
    adm.sky.com
    assets.sky.com
    assets.sky.com-secure.edgekey.net
    awk.epgsky.com
    etc...

In order to have the IPSET lists and routing rules restored at boot, execute the scripts from **/jffs/scripts/nat-start**. Refer to the [Wiki](https://github.com/RMerl/asuswrt-merlin/wiki/User-scripts#creating-scripts ) for instructions on how to configure nat-start.

#### /jffs/scripts/nat-start example
Following is an example of how I have configured /**jffs/scripts/nat-start** to create the IPSET lists and define the routing rules for streaming media traffic at system boot.

    #!/bin/sh
    sh /jffs/scripts/x3mRouting/load_AMAZON_ipset_iface.sh 1

    sh /jffs/scripts/x3mRouting/load_ASN_ipset_iface.sh 1 HULU AS23286
    sh /jffs/scripts/x3mRouting/load_ASN_ipset_iface.sh 1 NETFLIX AS2906

    sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset_iface.sh 1 HULU_WEB hulu.com,hulustream.com,akamaihd.net
    sh /jffs/scripts/ifacetest/load_DNSMASQ_ipset.sh 2 MOVETV movetv.com
    sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset_iface.sh 2 CBS_WEB cbs.com,cbsnews.com,cbssports.com,cbsaavideo.com,omtrdc.net,akamaihd.net,irdeto.com,cbsi.com,cbsig.net
    sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset_iface.sh 3 BBC_WEB bbc.co.uk,bbc.com,bbc.gscontxt.net,bbci.co.uk,bbctvapps.co.uk,ssl-bbcsmarttv.2cnt.net,llnwd.net

## x3mRouting Project Code Files
The installation script **install_x3mRouting.sh** will display a menu with the options to install, update the current installation or remove the project from the router. The following table lists the files that will be downloaded for each method.

| Script Name   | LAN Clients   |  OpenVPN GUI + Shell Scripts | Shell Scripts |
| --- | :---: | :---: | :---: |
|x3mRouting_client_nvram.sh         | X |   |   |
|x3mRouting_config.sh               | X |   |   |
|updown.sh                          | X | X |   |
|vpnrouting.sh                      | X | X |   |
|mount_files_lan.sh                 | X |   |   |
|mount_files_gui.sh                 |   | X |   |
|Advanced_OpenVPNClient_Content.asp |   | X |   |  
|load_AMAZON_ipset.sh               |   | X |   |
|load_ASN_ipset.sh                  |   | X |   |
|load_DNSMASQ_ipset.sh              |   | X |   |
|load_MANUAL_ipset.sh               |   | X |   |
|load_AMAZON_ipset_iface.sh         |   |   | X |
|load_ASN_ipset_iface.sh            |   |   | X |
|load_DNSMASQ_ipset_iface_ipset.sh  |   |   | X |
|load_MANUAL_ipset_iface_ipset.sh   |   |   | X |

### Acknowledgements
I want to acknowledge the following [snbforums](https://www.snbforums.com) members who helped make this project possible.
* [Martineau](https://www.snbforums.com/members/martineau.13215/) has been very generous in sharing his OpenVPN and Selective Routing expertise with me over the past several years. This project was only made possible through his support and collaboration. Through his guidance, I was able to navigate through the maze of of the firmware's **vpnrouting.sh** script and enhance it to create a much cleaner implementation of my selective routing requirements when compared to the method I had been using previously.

 As part of the ongoing collaboration, Martineau had modified a selective routing script I wrote for routing Netflix traffic and enhanced it by enabling the passing of parameters. The enhancements were applied to the other IPSET scripts used in the project and make the scripts more user friendly by eliminating the need for users to edit scripts to meet their use case requirements.

 Martineau also contributed the modified **OpenVPN Client screen** and **Chk_Entware** function used in the project.
* [Adamm](https://github.com/Adamm00) contributed the Lock File function that prevents the scripts from running concurrently. His method is much cleaner when compared to the previous method I had been using. The code for the update function was also inspired by Adamm.

* For the installation script, [Jack Yaz](https://github.com/jackyaz/spdMerlin) gave me permission to clone the code he used for the update code function, also inspired by Adamm, used on the [SpdMerlin](https://github.com/jackyaz/spdMerlin) project on GitHub.

* I also want to thank [thelonelycoder](https://www.snbforums.com/members/thelonelycoder.25480/), also known as the [Decoderman](https://github.com/decoderman) on GitHub, for his inspiration and ongoing support in my coding journey.
