# x3mRouting ~ Selective Routing for Asuswrt-Merlin Firmware
## Introduction
The features of **x3mRouting** include three selective routing methods to choose from:

#### 1. x3mRouting for LAN Clients Method
 
An alternative approach to automate and easily assign LAN clients to a WAN or OpenVPN Client interface. This method eliminates the need to enter the LAN Client information and IP addresses in the OpenVPN Client Screen. The **x3mRouting for LAN Client Method** can be used by itself or with one of the two methods below.

#### 2. x3mRouting OpenVPN Client Screen & IPSET Shell Script Method

Provides the ability to create IPSET lists using shell scripts and selectively route the IPSET lists by entering the IPSET name in a modified OpenVPN Client Screen.  

#### 3. x3mRouting IPSET Shell Script Method

Provides the ability to create and selectively route IPSET lists using shell scripts. If you're the person who likes to flash alpha and beta software releases and perform firmware updates once they become available, then this is the method for you. No modifications to the firmware source code are used in this method.

Detailed descriptions and usage examples of each method are listed in the **x3mRouting Methods** section below.

## Project Development
I used Amazon Prime, BBC, CBS All Access, Hulu, Netflix and Sling streaming media services in developing the project and included these in the usage examples below.

Please beware that Amazon Prime, BBC, Hulu and Netflix block known VPN servers. If you want a VPN provider who can circumvent the VPN blocks, see my blog post [Why I use Torguard as my VPN Provider](https://x3mtek.com/why-i-use-torguard-as-my-vpn-provider) to learn more.

## Installation

Copy and paste the command below into an SSH session:

    /usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/Xentrk/x3mRouting/master/install_x3mRouting.sh" -o "/jffs/scripts/install_x3mRouting.sh" && chmod 755 /jffs/scripts/install_x3mRouting.sh && sh /jffs/scripts/install_x3mRouting.sh

This command will download and install the installation script **/jffs/scripts/install_x3mRouting.sh**. The installation script is a menu with options to install the three methods described below and options to update or remove the repository.

<img src="https://github.com/Xentrk/x3mRouting/blob/master/InstallationMenu.png" alt="drawing" width="600" height="600"/>

## x3mRouting Methods

### [1] ~ x3mRouting LAN Client Method
In the Asuswrt-Merlin firmware, one must type the IP address of each LAN client into the Policy Routing section of the OpenVPN Client screen in order to assign the LAN client to the OpenVPN Client interface.  If you have many LAN clients, the process of entering the IP address and other required information can be time consuming - especially after performing a factory reset.

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

### [2] ~ x3mRouting OpenVPN Client Screen & IPSET Shell Script Method
As part of this project, you can also choose to download and install a modified OpenVPN Client screen to selectively route IPSET lists thru an OpenVPN Client.

[@Martineau](https://www.snbforums.com/members/martineau.13215/) coded the revisions to the OpenVPN Client screen as a proof of concept on how the Policy Rules section could be modified to incorporate the selective routing of IPSET lists. I greatly appreciate his generosity in providing the modified code and allowing me to include it in the project.

#### OpenVPN Client Screen ~ Policy Routing Section
![Policy Routing Screen](https://github.com/Xentrk/x3mRouting/blob/master/Policy_Routing_Screen.PNG "Policy Routing Screen")

#### IPSET Dimensions
The OpenVPN Client Screen accepts single and multiple dimension IPSET lists. See the [IPSET Man Page](http://ipset.netfilter.org/ipset.man.html) for information.

![IPSET Dimensions](https://github.com/Xentrk/x3mRouting/blob/master/OpenVPN_Client_GUI.png "OpenVPN Client Screen")

#### Video Tutorial

A video tutorial on how to allow the use of IPSET lists via the Selective routing VPN Client Policy Routing Screen can be viewed on [Vimeo](https://vimeo.com/287067217).

#### DummyVPN
In the screen picture above, you will notice an entry for **DummyVPN1**. For the Selective routing of Ports/MACs and IPSETs, [@Martineau](https://www.snbforums.com/members/martineau.13215/) recommends creating a “dummy” VPN Client entry if you require the ability to exploit the **Accept DNS Configuration=Exclusive** option that only creates the appropriate DNSVPN iptable chain if the table isn't empty. Use a valid IPv4 address for the DummyVPN entry that differs from your LAN IPv4 address range. I recommend using a [bogon IP addres](https://ipinfo.io/bogon) for this purpose.    

#### IPSET Save/Restore File Location
By default, all of the scripts will store backup copies of the IPSET lists in the **/opt/tmp** entware directory. This will allow the IPSET lists to be restored on system boot. If you prefer, you can specify another directory location by passing a directory parameter to the script. Usage examples are provided below.

#### Shell Script Usage Examples for use with the modified OpenVPN Client Screen

##### load_AMAZON_ipset.sh
This script will create an IPSET list called containing all IPv4 address for the Amazon AWS region specified. The source file used by the script is provided by Amazon at https://ip-ranges.amazonaws.com/ip-ranges.json. The AMAZON US region is required to route Amazon Prime traffic. You must specify one of the regions below when creating the IPSET list:

* AP - Asia Pacific
* CA - Canada
* CN - China
* EU - European Union
* SA - South America
* US - USA
* GV - USA Government
* GLOBAL - Global

**Usage:**

    load_AMAZON_ipset.sh {ipset_name region} [dir='directory'] [del]

Create the IPSET list AMAZON-US for the US region use the **/opt/tmp** directory for the IPSET save/restore file location:

    load_AMAZON_ipset.sh AMAZON-US US

Create the IPSET list AMAZON-US for the US region and use the **/mnt/sda1/Backups** directory rather than Entware's **/opt/tmp** directory for the IPSET save/restore file location:

    load_AMAZON_ipset.sh AMAZON-US US dir=/mnt/sda1/Backups

Delete IPSET AMAZON-US (the region parameter is not required when using the delete function):

    load_AMAZON_ipset.sh AMAZON-US del

##### load_MANUAL_ipset.sh
This script will create an IPSET list from a file containing IPv4 addresses. For example, I mined the domain names for BBC from dnsmasq and converted the domain names to their respective IPv4 addresses. You must pass the script the IPSET list name. The IPSET list name must match the name of the file containing the IPv4 addresses.

Usage:

    load_MANUAL_ipset.sh {ipset_name} [del] [dir='directory']

Create IPSET BBC and use the default **/opt/tmp** directory as the IPSET save/restore location:

    load_MANUAL_ipset.sh BBC

Create IPSET BBC and use the **/mnt/sda1/Backups** directory rather than the default **/opt/tmp** directory for IPSET save/restore location:

    load_MANUAL_ipset.sh BBC dir=/mnt/sda1/Backups

Delete IPSET BBC:

    load_MANUAL_ipset.sh BBC del

##### load_ASN_ipset.sh
This script will create an IPSET list using the [AS Number](https://www.apnic.net/get-ip/faqs/asn/).  The IPv4 addresses are downloaded from https://ipinfo.io/. https://ipinfo.io/ may require whitelisting if you use an ad-blocker program.  You must pass the script the name of the IPSET list followed by the AS Number.  

Usage example:

    load_ASN_ipset.sh {ipset_name ASN} [del] [dir='directory']

Create IPSET NETFLIX and use the default **/opt/tmp** directory as the IPSET save/restore location:

    load_ASN_ipset.sh NETFLIX AS2906

Create IPSET NETFLIX and use the **/mnt/sda1/Backups** directory rather than the default **/opt/tmp** directory for IPSET save/restore location:

    load_ASN_ipset.sh NETFLIX AS2906 dir=/mnt/sda1/Backups

Delete IPSET NETFLIX (the AS Number parameter is not required when using the delete function):

    load_ASN_ipset.sh NETFLIX del

##### load_DNSMASQ_ipset.sh
This script will create an IPSET list using the IPSET feature inside of dnsmasq to collect IPv4 addresses. The script will also create a cron job to backup the list every 24 hours to the **/opt/tmp** directory so the IPSET list can be restored on system boot. Pass the script the name of the IPSET list followed by the domain names separated by a comma.

Usage example:

    load_DNSMASQ_ipset.sh {ipset_name domains[,...]} ['autoscan'] [del]  [dir='directory']

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
Following is an exammple of how to configure /**jffs/scripts/nat-start** to create the IPSET lists for streaming media traffic at system boot.

    #!/bin/sh
    sh /jffs/scripts/x3mRouting/load_AMAZON_ipset.sh AMAZON-US US

    sh /jffs/scripts/x3mRouting/load_MANUAL_ipset.sh BBC

    sh /jffs/scripts/x3mRouting/load_ASN_ipset.sh HULU AS23286
    sh /jffs/scripts/x3mRouting/load_ASN_ipset.sh NETFLIX AS2906

    sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset.sh HULU_WEB hulu.com,hulustream.com,akamaihd.net
    sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset.sh CBS_WEB cbs.com,cbsnews.com,cbssports.com,cbsaavideo.com,omtrdc.net,akamaihd.net,irdeto.com,cbsi.com,cbsig.net
    sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset.sh BBC_WEB bbc.co.uk,bbc.com,bbc.gscontxt.net,bbci.co.uk,bbctvapps.co.uk,ssl-bbcsmarttv.2cnt.net,llnwd.net
    sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset.sh MOVETV movetv.com

### [3] ~ x3mRouting using the IPSET Shell Script Method
This method is intended for users who want the ability to create and route traffic using IPSET lists, but prefer to use Asuswrt-Merlin firmware without the firmware modifications utilized by the method listed above.

The difference with the scripts above is the ability to pass the interface parameter to the script to specify either the WAN or one of the five OpenVPN Client interfaces.

##### load_AMAZON_ipset_iface.sh
This script will create an IPSET list called containing all IPv4 address for the Amazon AWS region specified. The source file used by the script is provided by Amazon at https://ip-ranges.amazonaws.com/ip-ranges.json. The AMAZON US region is required to route Amazon Prime traffic. You must specify one of the regions below when creating the IPSET list:

* AP - Asia Pacific
* CA - Canada
* CN - China
* EU - European Union
* SA - South America
* US - USA
* GV - USA Government
* GLOBAL - Global

Usage:

    load_AMAZON_ipset_iface.sh {[0|1|2|3|4|5] ipset_name region} [del] [dir='directory']

Create the IPSET list AMAZON-US from the US region via VPN Client 2 and use the **/opt/tmp** directory for the IPSET save/restore file location:

    load_AMAZON_ipset_iface.sh 2 AMAZON-US US

Create the IPSET list AMAZON-US from the US region via VPN Client 2 and use the **/mnt/sda1/Backups** directory rather than the **/opt/tmp** directory for the IPSET save/restore location:

    load_AMAZON_ipset_iface.sh 2 AMAZON-US US dir=/mnt/sda1/Backups

Delete the IPSET list AMAZON-US and remove from VPN Client 2 (the region parameter is not required when using the delete function):

    load_AMAZON_ipset_iface.sh 2 AMAZON-US del

##### load_MANUAL_ipset_iface.sh
This script will create an IPSET list from a file containing IPv4 addresses stored in the **/opt/tmp** directory on entware. For example, I mined the domain names from dnsmasq for BBC and converted the domain names to their respective IPv4 addresses. You must pass the script the IPSET list name. The IPSET list name must match the name of the file containing the IPv4 addresses stored in **/opt/tmp**.

Usage:

    load_MANUAL_ipset.sh {[0|1|2|3|4|5] ipset_name} [del] [dir='directory']

Create IPSET BBC via VPN Client 3 and use the default **/opt/tmp** directory as the IPSET save/restore location:

    load_MANUAL_ipset_iface.sh 3 BBC

Create IPSET BBC via VPN Client 3 and use the **/mnt/sda1/Backups** directory rather than the default **/opt/tmp** directory for IPSET save/restore location:

    load_MANUAL_ipset_iface.sh 3 BBC dir=/mnt/sda1/Backups

Create IPSET BBC via VPN Client 3 and use the **/mnt/sda1/Backups** directory rather than the default **/opt/tmp** directory for IPSET save/restore location:

    load_MANUAL_ipset_iface.sh 3 BBC

##### load_ASN_ipset_iface.sh
This script will create an IPSET list using the [AS Number](https://www.apnic.net/get-ip/faqs/asn/). The IPv4 addresses are downloaded from https://ipinfo.io/. https://ipinfo.io/ may require whitelisting if you use an ad-blocker program.  You must pass the script the name of the IPSET list followed by the AS Number.  

Usage example:

    load_ASN_ipset_iface.sh {[0|1|2|3|4|5] ipset_name ASN} [del] [dir='directory']

Create IPSET NETFLIX from AS2906 via VPN Client 2:

    load_ASN_ipset_iface.sh 2 NETFLIX AS2906

Create IPSET NETFLIX from AS2906 via VPN Client 2, but use the **/mnt/sda1/Backups** directory rather than the default **opt/tmp** as the IPSET save/restore file location:

    load_ASN_ipset_iface.sh 2 NETFLIX AS2906 dir=/mnt/sda1/Backups

Delete IPSET NETFLIX and remove routing via VPN Client 2 (the AS Number parameter is not required when using the delete function):

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
Following is an example of how to configure /**jffs/scripts/nat-start** to create the IPSET lists and define the routing rules for streaming media traffic at system boot.

    #!/bin/sh
    sh /jffs/scripts/x3mRouting/load_AMAZON_ipset_iface.sh 1 AMAZON-US US

    sh /jffs/scripts/x3mRouting/load_ASN_ipset_iface.sh 1 NETFLIX AS2906

    sh /jffs/scripts/x3mRouting/load_MANUAL_ipset_iface.sh 5 PLUTOTV

    sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset_iface.sh 1 HULU_WEB hulu.com,hulustream.com,akamaihd.net
    sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset.sh 2 MOVETV movetv.com
    sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset_iface.sh 2 CBS_WEB cbs.com,cbsnews.com,cbssports.com,cbsaavideo.com,omtrdc.net,akamaihd.net,irdeto.com,cbsi.com,cbsig.net
    sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset_iface.sh 3 BBC_WEB bbc.co.uk,bbc.com,bbc.gscontxt.net,bbci.co.uk,bbctvapps.co.uk,ssl-bbcsmarttv.2cnt.net,llnwd.net

## Helpful Tips, Validation and Troubleshooting

### How to identify domain names
1. Open up a desktop browser session and go to the home page for the streaming service. Right click on the page and select the option to view the page source code. In Firefox, the option is **View Page Source**. Search for the words **".com"** and **".net"**.

2. Use the **"Follow the log file"** option of [Diversion](https://diversion.ch) ad blocker to filter the log file view by LAN Client to see what domain names are being looked up.

### How to determine AS Numbers for streaming services
Use the site [https://bgp.he.net](https://bgp.he.net/) to find AS Numbers for streaming services. You can type the name of the streaming service in the **search box** or an IP address.

Alternatively, you can use the **nslookup** command to find the IP address of a domain name. Then use the **whob** command to find the AS Number of the IP address.

    # nslookup occ-0-1077-1062.1.nflxso.net

    Server:    127.0.0.1
    Address 1: 127.0.0.1 localhost.localdomain

    Name:      occ-0-1077-1062.1.nflxso.net
    Address 1: 2a00:86c0:600:96::138 ipv6_1.lagg0.c009.lax004.ix.nflxvideo.net
    Address 3: 198.38.96.132 ipv4_1.lagg0.c003.lax004.ix.nflxvideo.net

    # whob 198.38.96.132

    IP: 198.38.96.132
    Origin-AS: 2906
    Prefix: 198.38.96.0/24
    AS-Path: 34224 3356 2906
    AS-Org-Name: Netflix Streaming Services Inc.
    <snip>

### IPSET List Update Frequency
The IPSET shell scripts for Amazon and AS Numbers will download new data when the associated file in the IPSET list save/restore location is older than 7 days. The scripts execute whenever there is an event that causes /jffs/scripts/nat-start to execute.  

### Validation and Troubleshooting
#### IPSET lists
The install script will add a function to **/jffs/configs/profile.add** called **liststats** that will list the name of all IPSET lists and the number of IP address entries. To use the function, type **liststats** from the SSH command line (Note: For first time users, you must open up a new SSH session after running the installation script). Following is the sample output:

    AMAZON - 326
    BBC_WEB - 128
    CBS - 57
    CBS_WEB - 82
    HULU_WEB - 8
    MOVETV - 95
    NETFLIX - 150

Display information about an IPSET list, type the command **ipset -L ipset_name**. For example, to display the information about the IPSET list NETFLIX, type: **ipset -L NETFLIX**

    Name: NETFLIX
    Type: hash:net
    Revision: 6
    Header: family inet hashsize 1024 maxelem 65536
    Size in memory: 8044
    References: 1
    Number of entries: 150
    Members:
    198.38.100.0/24
    45.57.32.0/24
    45.57.7.0/24
    45.57.65.0/24
    198.45.56.0/24
    <snip>

#### OpenVPN and LAN Client RPDB Routing and Priorities Rules
Type the command

    ip rule

to display the RPDB routing priority database rules for the OpenVPN and LAN Clients:

    0:      from all lookup local
    9990:   from all fwmark 0x8000/0x8000 lookup main
    9991:   from all fwmark 0x3000/0x3000 lookup ovpnc5
    9992:   from all fwmark 0x7000/0x7000 lookup ovpnc4
    9993:   from all fwmark 0x4000/0x4000 lookup ovpnc3
    9994:   from all fwmark 0x2000/0x2000 lookup ovpnc2
    9995:   from all fwmark 0x1000/0x1000 lookup ovpnc1
    10104:  from 192.168.1.150 lookup ovpnc1
    10105:  from 192.168.1.151 lookup ovpnc1
    10106:  from 192.168.1.153 lookup ovpnc1
    10107:  from 192.168.1.154 lookup ovpnc1
    10301:  from 192.168.1.165 lookup ovpnc2
    10302:  from 192.168.1.149 lookup ovpnc2
    10303:  from 192.168.1.152 lookup ovpnc2
    32766:  from all lookup main
    32767:  from all lookup default

#### IPTABLES Chains

Enter the following command to display the IPTABLES Chains for the PREROUTING table:

    iptables -nvL PREROUTING -t mangle --line

The output will also display the number of packets and bytes traversing the iptables rule which can be used as confirmation that traffic is being routed according to the rule:

    Chain PREROUTING (policy ACCEPT 5808K packets, 6404M bytes)
    num   pkts bytes target     prot opt in     out     source               destination
    1        1    60 MARK       all  --  tun13  *       0.0.0.0/0            0.0.0.0/0            MARK xset 0x1/0x7
    2     661K  863M MARK       all  --  tun15  *       0.0.0.0/0            0.0.0.0/0            MARK xset 0x1/0x7
    3        1    60 MARK       all  --  tun14  *       0.0.0.0/0            0.0.0.0/0            MARK xset 0x1/0x7
    4    76880   70M MARK       all  --  tun12  *       0.0.0.0/0            0.0.0.0/0            MARK xset 0x1/0x7
    5    2030K 2737M MARK       all  --  tun11  *       0.0.0.0/0            0.0.0.0/0            MARK xset 0x1/0x7
    6        0     0 MARK       all  --  tun21  *       0.0.0.0/0            0.0.0.0/0            MARK xset 0x1/0x7
    7        0     0 MARK       all  --  br0    *       0.0.0.0/0            0.0.0.0/0            match-set NETFLIX dst MARK set 0x1000
    8    1067K   60M MARK       all  --  br0    *       0.0.0.0/0            0.0.0.0/0            match-set HULU_WEB dst MARK set 0x1000
    9    33488 6945K MARK       all  --  br0    *       0.0.0.0/0            0.0.0.0/0            match-set AMAZON dst MARK set 0x1000
    10    129K 9898K MARK       all  --  br0    *       0.0.0.0/0            0.0.0.0/0            match-set MOVETV dst MARK set 0x3000
    11   27284 5635K MARK       all  --  br0    *       0.0.0.0/0            0.0.0.0/0            match-set CBS_WEB dst MARK set 0x3000
    12       0     0 MARK       all  --  br0    *       0.0.0.0/0            0.0.0.0/0            match-set BBC_WEB dst MARK set 0x4000


#### Ad Blockers
If you use an ad blocker, some domains may require whitelisting for the streaming service to properly playback video.       

##### CBS All Access

    cbsinteractive.hb.omtrdc.net
    cws.conviva.com
    imasdk.googleapis.com
    pubads.g.doubleclick.net

##### Sling

    dpm.demdex.net
    b.scorecardresearch.com

## x3mRouting Project Code Files
The installation script **install_x3mRouting.sh** will display a menu with the options to install, update the current installation or remove the project from the router. The following table lists the files that will be downloaded for each method.

| Script Name   | LAN Clients   |  OpenVPN Client + IPSET Shell Scripts | IPSET Shell Scripts |
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
* [Martineau](https://www.snbforums.com/members/martineau.13215/) has, and continues to be, very generous in sharing his OpenVPN and Selective Routing expertise with me over the past several years. This project was only made possible through his support and collaboration. Through his guidance, I was able to navigate through the maze of of the firmware's **vpnrouting.sh** script and enhance it to create a much cleaner implementation of my selective routing requirements when compared to the method I had been using previously.

  As part of the ongoing collaboration, Martineau had modified a selective routing script I wrote for routing Netflix traffic and enhanced it by enabling the passing of parameters. The enhancements made the script more user friendly by eliminating the need for users to edit scripts to meet their use case requirements. The enhancements have been applied to all of the IPSET scripts.

  Martineau also contributed the modified **OpenVPN Client screen**, the [Vimeo](https://vimeo.com/287067217) video and **Chk_Entware** function used in the project.

* [Adamm](https://github.com/Adamm00) contributed the **Lock File** function that prevents the scripts from running concurrently. His method is much cleaner when compared to the previous method I had been using. The code for restoring the IPSET lists using the **awk** method and the **md5sum** check function to detect updated code on GitHub were also inspired by Adamm.

* For the installation script, [Jack Yaz](https://github.com/jackyaz/spdMerlin) gave me permission to clone the code he used for the update code function (also inspired by Adamm) used on the [SpdMerlin](https://github.com/jackyaz/spdMerlin) project on GitHub.

* Gratitude to the [thelonelycoder](https://www.snbforums.com/members/thelonelycoder.25480/), also known as the [Decoderman](https://github.com/decoderman) on GitHub, for his inspiration and ongoing support in my coding journey.

* Thank you to [RMerlin](https://www.snbforums.com/members/rmerlin.10954/) for the [Asuswrt-Merlin](https://github.com/RMerl/asuswrt-merlin.ng) firmware and helpful support on the [snbforums.com](https://www.snbforums.com/forums/asuswrt-merlin.42/) website. To learn more about Asuswrt-Merlin firmware for Asus routers, visit the project website at [https://asuswrt.lostrealm.ca/source](https://asuswrt.lostrealm.ca/source).
