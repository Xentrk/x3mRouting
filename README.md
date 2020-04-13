# x3mRouting ~ Selective Routing for Asuswrt-Merlin Firmware
[![Build Status](https://travis-ci.com/Xentrk/x3mRouting.svg?branch=master)](https://travis-ci.com/Xentrk/x3mRouting)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/561d1570ed1f4d6aab76bba172f6b31f)](https://www.codacy.com/app/Xentrk/x3mRouting?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=Xentrk/x3mRouting&amp;utm_campaign=Badge_Grade)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

## Introduction
The features of **x3mRouting** include selective routing features for LAN Clients and IPSET Lists.

#### 1. LAN Client Routing

An alternative approach to automate and easily assign LAN clients to a WAN or OpenVPN Client interface. This option eliminates the need to enter the LAN Client information and IP addresses in the OpenVPN Client Screen. The **LAN Clients** option can be used by itself or with one of the two options below.

#### 2. OpenVPN Client GUI, OpenVPN Event & x3mRouting.sh Script

Provides the ability to create IPSET lists using the **x3mRouting.sh** script and selectively route the IPSET lists thru the OpenVPN Client by entering the IPSET name in a modified OpenVPN Client Screen. You can't use the screen to route IPSET lists to the WAN interface at this time. Use option 3 below instead.

#### 3. x3mRouting.sh Script

Provides the ability to create and selectively route IPSET lists to the WAN or OpenVPN Client interfaces using the **x3mRouting.sh** script.

#### x3mRouting.sh Additional Features

The x3mRouting.sh script also provides the ability to:

  * Route all VPN Server traffic to one of the VPN Clients.
  * Selectively route VPN Server traffic to an existing LAN routing rule for an IPSET list.

#### openvpn-event Script

x3mRouting uses the **openvpn-event** script during an OpenVPN "up" event to create the IPSET list and routing rule and during an OpenVPN "down" event to remove the routing rule. **openvpn-event** is automatically installed when selecting options 2 and 3.

**openvpn-event** will call OpenVPN related scripts such as:

  * vpnclient1-route-up
  * vpnclient1-route-pre-down
  * vpnserver2-up
  * vpnserver2-down

located in **/jffs/scripts/x3mRouting** based on OpenVPN Client or Server events.
#### /jffs/scripts/x3mRouting/vpnclient1-route-up example

````
#!/bin/sh
sh /jffs/scripts/x3mRouting/load_AMAZON_ipset_iface.sh 1 AMAZON-US US
sh /jffs/scripts/x3mRouting/load_ASN_ipset_iface.sh 1 NETFLIX AS2906
sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset_iface.sh 1 HULU_WEB hulu.com,hulustream.com,akamaihd.net
````

## Support
For help and support, please visit the Asuswrt-Merlin x3mRouting support thread on [snbforums.com](https://www.snbforums.com/threads/x3mrouting-selective-routing-for-asuswrt-merlin-firmware.57793/#post-506675).

## Requirements
1.  An Asus router with  [Asuswrt-Merlin](http://asuswrt.lostrealm.ca/) firmware installed.
2.  A USB drive with [entware](https://github.com/RMerl/asuswrt-merlin/wiki/Entware) installed. Entware can be installed using [amtm - the SNBForum Asuswrt-Merlin Terminal Menu](https://www.snbforums.com/threads/amtm-the-snbforum-asuswrt-merlin-terminal-menu.42415/)
3.  Policy Rules (Strict) or Policy Rules enabled on the OpenVPN Client screen.

## Project Development
I used Amazon Prime, BBC, CBS All Access, Hulu, Netflix and Sling streaming media services in developing the project and include them in the usage examples below.

Please beware that Amazon Prime, BBC, Hulu and Netflix block known VPN servers. If you want a VPN provider who can circumvent the VPN blocks, see my blog post [Why I use Torguard as my VPN Provider](https://x3mtek.com/why-i-use-torguard-as-my-vpn-provider) to learn more.

## Installation

Copy and paste the command below into an SSH session:

      /usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/Xentrk/x3mRouting/master/x3mRouting" -o "/opt/bin/x3mRouting" && chmod 755 /opt/bin/x3mRouting && x3mRouting

This command will download and install the installation menu **x3mRouting** to the **/opt/bin** directory. The installation script is a menu with options to install the three options described below, and options to update or remove the repository. To access the installation menu, type the command **x3mRouting**.

<img src="https://github.com/Xentrk/x3mRouting/blob/master/InstallationMenu.PNG" alt="drawing" width="600" height="600"/>

## x3mRouting Options

### [1] ~ LAN Client Routing
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

If an existing **/jffs/configs/x3mRouting_client_rules** file exists, a backup copy of the existing **x3mRouting_client_rules** file is made by appending the timestamp to the existing file.  You only need to run this script if you have made changes to DHCP static assignments or accidentally deleted the **/jffs/configs/x3mRouting_client_rules** file.  

#### x3mRouting_client_nvram.sh
**x3mRouting_client_nvram.sh** is the second script to run. This script will create the nvram files
(e.g. **/jffs/configs/ovpnc1.nvram**) for OpenVPN clients in the **/jffs/configs** directory based on the interface assignments in **/jffs/configs/x3mRouting_client_rules**. An nvram file will not be created in the **/jffs/configs/** directory for LAN clients assigned to use the WAN interface.

Similar to the firmware, the next step is to bounce the OpenVPN Client interface to have the routing assignments take effect.  This is accomplished by selecting the **“Apply”** button on the OpenVPN Client screen you assigned the LAN client to.  Alternatively, you can bounce the WAN interface by selecting the **“Apply”** button on the WAN screen. Restarting the WAN will also restart any active OpenVPN clients. There is a slight delay before the OpenVPN Client becomes active. Check the OpenVPN Client status using the OpenVPN Status page.

The routing rules for LAN Clients will automatically be applied upon a system boot.  You only need to rerun **x3mRouting_client_nvram.sh** and bounce the OpenVPN client if you have made LAN Client interface assignment changes in the **/jffs/configs/x3mRouting_client_rules** file.  

### [2] ~ OpenVPN Client GUI, OpenVPN Event & Routing Script
As part of this project, you can also choose to download and install a modified OpenVPN Client screen to selectively route IPSET lists thru an OpenVPN Client. You can't use the screen to route IPSET lists to the WAN interface. Use method 3 instead.

[@Martineau](https://www.snbforums.com/members/martineau.13215/) coded the revisions to the OpenVPN Client screen as a proof of concept on how the Policy Rules section could be modified to incorporate the selective routing of IPSET lists. I greatly appreciate his generosity in providing the modified code and allowing me to include it in the project.

#### OpenVPN Client Screen ~ Policy Routing Section
![Policy Routing Screen](https://github.com/Xentrk/x3mRouting/blob/master/Policy_Routing_Screen.PNG "Policy Routing Screen")

#### IPSET Dimensions
The OpenVPN Client Screen accepts single and multiple dimension IPSET lists. See the [IPSET Man Page](http://ipset.netfilter.org/ipset.man.html) for information.

![IPSET Dimensions](https://github.com/Xentrk/x3mRouting/blob/master/OpenVPN_Client_GUI.png "OpenVPN Client Screen")

#### Video Tutorial

A video tutorial on how to allow the use of IPSET lists via the Selective routing VPN Client Policy Routing Screen can be viewed on [Vimeo](https://vimeo.com/287067217).

#### DummyVPN
In the screen picture above, you will notice an entry for **DummyVPN1**. For the Selective routing of Ports/MACs and IPSETs, [@Martineau](https://www.snbforums.com/members/martineau.13215/) recommends creating a “dummy” VPN Client entry if you require the ability to exploit the **Accept DNS Configuration=Exclusive** option that only creates the appropriate DNSVPN iptables chain if the table isn't empty. Use a valid IPv4 address for the DummyVPN entry that differs from your LAN IPv4 address range. I recommend using a [bogon IP addres](https://ipinfo.io/bogon) for this purpose.    

#### IPSET Save/Restore File Location
By default, all of the scripts will store backup copies of the IPSET lists in the **/opt/tmp** entware directory. This will allow the IPSET lists to be restored on system boot. If you prefer, you can specify another directory location by passing a directory parameter to the script. Usage examples are provided below.

## x3mRouting Usage Notes

* Required parameters are listed inside the braces { }
* Optional parameters are listed inside of the brackets [ ]
* Valid parameter values are listed in parenthesis ( )

Create IPSET List with Routing Rules
````
x3mRouting.sh {src iface} (ALL|1|2|3|4|5)
              {dst iface} (0|1|2|3|4|5)
               **src/dst NOTES Start**
                 Valid SRC and DST Combinations
                 1) VPN Client Routing
                    - Use this SRC and DST combination to route all IPSET list traffic to a VPN Client:
                      ALL 1, ALL 2, ALL 3, ALL 4, ALL 5
                 2) VPN Bypass Routing
                    - Use this SRC and DST combination to bypass the VPN Client for an IPSET list and
                      route to the WAN interface:
                      1 0, 2 0, 3 0, 4 0, 5 0
               **src/dst NOTES End**
               {ipset_name}
               ['autoscan='keyword1[,keyword2]...] # Scans for keywords and creates IPSET list using the dnsmasq method
               ['asnum='asnum[,asnum]...] # ASN method
               ['aws_region='US[,EU]...]  # Amazon method
               ['dnsmasq='domain[,domain]...] # dnsmasq method
               ['ip='ip[,ip][,cidr]...] # Equivalent to manual method
               ['dir='save_restore_location] # if 'dir' not specified, defaults to /opt/tmp
               ['ip='ip[,ip][,cidr]...]
               ['src='src_ip]
               ['src_range='from_ip-to_ip]
               ['dir='save_restore_location]
               ['del']
````
Create IPSET List with no Routing Rules
````
 x3mRouting.sh {ipset_name=}
               ['autoscan='keyword1[,keyword2]...] # Scans for keywords and creates IPSET list using the dnsmasq method
               ['asnum='asnum[,asnum]...] # ASN method
               ['aws_region='US[,EU]...]  # Amazon method
               ['dnsmasq='domain[,domain]...] # dnsmasq method
               ['ip='ip[,ip][,cidr]...] # Equivalent to manual method
               ['dir='save_restore_location] # if 'dir' not specified, defaults to /opt/tmp
               ['del']
````
VPN Server to VPN Client Routing

````
x3mRouting.sh {'server='1|2|both} {'client='1|2|3|4|5} ['del']
````

VPN Server to existing LAN routing rules for an IPSET list

````
x3mRouting.sh {'server='1|2|both} {'ipset_name='} ['del']
````

#### Valid Amazon AWS Regions
**x3mRouting.sh** script will create an IPSET list containing all IPv4 address for the Amazon AWS region(s) specified. The source file used by the script is provided by Amazon at https://ip-ranges.amazonaws.com/ip-ranges.json. You must specify one or more of the regions below when creating the IPSET list:

* AP - Asia Pacific
* CA - Canada
* CN - China
* EU - European Union
* SA - South America
* US - USA
* GV - USA Government
* GLOBAL - Global

## x3mRouting Usage Examples

#### ASN Method

Route all traffic matching IPSET list NETFLIX created from AS2906 to VPN Client1.

    sh /jffs/scripts/x3mRouting/x3mRouting.sh ALL 1 NETFLIX asnum=AS2906

Route all traffic matching IPSET list NETFLIX created from AS2906 to VPN Client1 from LAN device 192.168.22.152.    

    sh /jffs/scripts/x3mRouting/x3mRouting.sh ALL 1 NETFLIX asnum=AS2906 src=192.168.22.152

#### Amazon AWS Region Method
Route all traffic matching IPSET list AMAZON_US created from the AWS US region to VPN Client 1.

    sh /jffs/scripts/x3mRouting/x3mRouting.sh ALL 1 AMAZON_US aws_region=US

Route IP address ranges 192.168.22.152-192.168.22.157 traffic matching IPSET list AMAZON_US created from the Amazon US region to VPN Client 1.

    sh /jffs/scripts/x3mRouting/x3mRouting.sh ALL 1 AMAZON_US aws_region=US src_range=192.168.22.152-192.168.22.157

#### dnsmasq Method
Route all traffic matching IPSET list NETFLIX created from domain names to VPN Client1.

````
sh /jffs/scripts/x3mRouting/x3mRouting.sh ALL 1 NETFLIX  dnsmasq=netflix.com,nflxext.com,nflximg.net,nflxso.net,nflxvideo.net
````

#### dnsmasq Method with autoscan
Search dnsmasq.log file for domains that contain the keyword "amazon" and create the IPSET list AMAZON using the dnsmasq method

````
sh /jffs/scripts/x3mRouting/x3mRouting.sh ALL 1 AMAZON autoscan=amazon
````

Search dnsmasq.log file for domains that contain the keywords "amazonaws,netflix,nflx" and create the IPSET list AMZ_NFLX using the dnsmasq method

    sh /jffs/scripts/x3mRouting/x3mRouting.sh ALL 1 AMZ_NFLX autoscan=amazonaws,netflix,nflx

#### Manual Method
The Manual Method is used for IPSET lists from a file in the save/restore directory containing IPv4 addresses and/or IPv4 CIDR format.

Route all traffic matching IPSET list WIMIPCOM to VPN Client.

    sh /jffs/scripts/x3mRouting/x3mRouting.sh ALL 1 WIMIPCOM

Route all VPN Client 1 traffic matching IPSET list WIMIPCOM created from the IPv4 addresses provided.

    sh /jffs/scripts/x3mRouting/x3mRouting.sh ALL 1 WIMIPCOM ip=104.27.198.90,104.27.199.90

### VPN Client Bypass Routing #####

#### ASN Method
Route VPN Client 1 traffic matching IPSET list NETFLIX to WAN.

````
sh /jffs/scripts/x3mRouting/x3mRouting.sh 1 0 NETFLIX asnum=AS2906
````

Route VPN Client 1 traffic from 192.168.22.152 matching IPSET list NETFLIX to WAN.

````
sh /jffs/scripts/x3mRouting/x3mRouting.sh 1 0 NETFLIX asnum=AS2906 src=192.168.22.152
````

#### Amazon AWS Region Method
Route VPN Client 1 traffic matching IPSET list AMAZON_US to WAN.

    sh /jffs/scripts/x3mRouting/x3mRouting.sh 1 0 AMAZON_US aws_region=US

Route VPN Client 1 traffic from 192.168.22.152-192.168.22.157 matching IPSET list AMAZON_US to WAN.

    sh /jffs/scripts/x3mRouting/x3mRouting.sh 1 0 AMAZON_US aws_region=US src_range=192.168.22.152-192.168.22.157

#### dnsmasq Method
Route all VPN Client 1 traffic matching IPSET list WIMIPCOM to the WAN.

    sh /jffs/scripts/x3mRouting/x3mRouting.sh 1 0 WIMIPCOM dnsmasq=whatismyip.com

Route all VPN Client 1 traffic matching IPSET list NETFLIX to the WAN.        

    sh /jffs/scripts/x3mRouting/x3mRouting.sh 1 0 NETFLIX dnsmasq=netflix.com,nflxext.com,nflximg.net,nflxso.net,nflxvideo.net

Route VPN Client 1 traffic from 192.168.22.152 matching IPSET list NETFLIX to WAN.

    sh /jffs/scripts/x3mRouting/x3mRouting.sh 1 0 NETFLIX domain=netflix.com,nflxext.com,nflximg.net,nflxso.net,nflxvideo.net src=192.168.22.152

#### Manual Method
Route all VPN Client 1 traffic matching IPSET list WIMIPCOM to the WAN.

    sh /jffs/scripts/x3mRouting/x3mRouting.sh 1 0 WIMIPCOM

Route all VPN Client 1 traffic matching IPSET list WIMIPCOM created from the IPv4 addresses provided to the WAN.

    sh /jffs/scripts/x3mRouting/x3mRouting.sh 1 0 WIMIPCOM ip=104.27.198.90,104.27.199.90

Route VPN Client 1 traffic from 192.168.22.152 matching IPSET list WIMIPCOM to the WAN.

    sh /jffs/scripts/x3mRouting/x3mRouting.sh 1 0 WIMIPCOM src=192.168.22.152

Route VPN Client 1 traffic from 192.168.22.152-192.168.22.157 matching IPSET list WIMIPCOM to WAN.        

    sh /jffs/scripts/x3mRouting/x3mRouting.sh 1 0 WIMIPCOM src_range=192.168.22.152-192.168.22.157

#### Delete an IPSET list and all routing rules and cru jobs
Either option listed below will work. There is no requirement to specify the method.

    sh /jffs/scripts/x3mRouting/x3mRouting.sh ipset_name=MYIPSET del
    sh /jffs/scripts/x3mRouting/x3mRouting.sh ALL 1 NETFLIX del

### IPSET list creation only - no routing rules

#### ASN Method
Create IPSET list NETFLIX from AS2906

    sh /jffs/scripts/x3mRouting/x3mRouting.sh/x3mRouting.sh ipset_name=NETFLIX asnum=AS2906  create IPSET list using AS2906 as the source

####  Amazon AWS Region Method
Create IPSET list AMAZON_US created from Amazon US region
    sh /jffs/scripts/x3mRouting/x3mRouting.sh/x3mRouting.sh ipset_name=AMAZON_US aws_region=US

#### dnsmasq Method
Create IPSET list NETFLIX using dnsmasq method
    sh /jffs/scripts/x3mRouting/x3mRouting.sh ipset_name=NETFLIX dnsmasq=netflix.com,nflxext.com,nflximg.net,nflxso.net,nflxvideo.net

#### Manual Method
Create IPSET list BBC using manual method
    sh /jffs/scripts/x3mRouting/x3mRouting.sh ipset_name=BBC

Create IPSET list BBC using manual method. Use 'dir' location as the backup/restore location
    sh /jffs/scripts/x3mRouting/x3mRouting.sh ipset_name=BBC dir=/tmp/mnt/RT-AC88U/mylists

#### VPN Server to VPN Client Routing:
Route from server 1,2 or both to VPN client 1,2,3,4 or 5.

    sh /jffs/scripts/x3mRouting/x3mRouting.sh server=1 client=1
    sh /jffs/scripts/x3mRouting/x3mRouting.sh server=2 client=1
    sh /jffs/scripts/x3mRouting/x3mRouting.sh server=both client=1

#### VPN Server to existing LAN routing rules for an IPSET list
Route from server 1,2 or both to use same LAN rules for IPSET list PANDORA.

    sh /jffs/scripts/x3mRouting/x3mRouting.sh server=1 ipset_name=PANDORA
    sh /jffs/scripts/x3mRouting/x3mRouting.sh server=2 ipset_name=PANDORA
    sh /jffs/scripts/x3mRouting/x3mRouting.shserver=both ipset_name=PANDORA

##### Requirements
1. The IPSET list must exist!
2. A PREROUTING rule must currently exist so the script can determine the VPN Client to route to!

Refer to the [Wiki](https://github.com/RMerl/asuswrt-merlin/wiki/User-scripts#creating-scripts ) for instructions on how to configure nat-start and other user scripts.

## Helpful Tips, Validation and Troubleshooting

### How to identify domain names
#### View Source Code
Open up a desktop browser session and go to the home page for the streaming service. Right click on the page and select the option to view the page source code. In Firefox, the option is **View Page Source**. Search for the words **".com"** and **".net"**.

#### Follow the Log File
Use the **"Follow the log file"** option of [Diversion](https://diversion.ch) ad blocker to filter the log file view by LAN Client to see what domain names are being looked up.

#### How to determine AS Numbers for streaming services
Use the site [https://bgp.he.net](https://bgp.he.net/) to find AS Numbers for streaming services. You can type the name of the streaming service in the **search box** or an IP address.

Alternatively, you can use the **nslookup** command to find the IP address of a domain name. Then use the **whob** command to find the AS Number of the IP address.

    # nslookup occ-0-1077-1062.1.nflxso.net

    Server:    127.0.0.1
    Address 1: 127.0.0.1 localhost.localdomain

    Name:      occ-0-1077-1062.1.nflxso.net
    Address 1: 2a00:86c0:600:96::138 ipv6_1.lagg0.c009.lax004.ix.nflxvideo.net
    Address 3: 198.38.96.132 ipv4_1.lagg0.c003.lax004.ix.nflxvideo.net

    # whob 198.38.96.132 | grep AS

    Origin-AS: 2906
    AS-Path: 34224 3356 2906
    AS-Org-Name: Netflix Streaming Services Inc.

#### getdomainnames.sh Script
This script will create a uniquely sorted list of domain names from dnsmasq.log that you collected by accessing a website or streaming service.
1. Download the script **getdomainnames.sh**
2. Navigate to the log file directory **/opt/var/log**
3. Enter the command: **tail -f dnsmasq.log > myfile** where 'myfile' is any file name you choose.
4. Access the streaming service and watch some videos for a few seconds and select each option to generate domain names
5. Type 'Ctrl-c' to exit
6. **sh getdomainnames.sh {file} {IP}**, where 'file'
is the name of the source file you created in the **/opt/var/log** directory and 'IP' is the IPv4 address of client device that was used to collect the domains.

Usage Example:
    sh /jffs/scripts/x3mRouting/getdomainnames.sh myfile 192.168.1.50

The domains collected will be stored in the **/opt/var/log/** directory using the same name as the output file with '_domains' concatenated at the end of the file name (e.g myfile_domains)

The next step is to check the file for domains not related to the streaming service. These are domains generated by other applications on the LAN client you streamed from. You don't have to use the fully qualified domain name. For example, the domain **occ-0-1077-1062.1.nflxso.net** would be entered as **nflxso.net**. Likewise, www.netflix.com would be entered as **netflix.com**.

### Validation and Troubleshooting
#### IPSET lists
The install script will add a function to **/jffs/configs/profile.add** called **liststats** that will list the name of all IPSET lists and the number of IP address entries. To use the function, type **liststats** from the SSH command line (Note: For first time users, you must open up a new SSH session after running the installation script). Following is the sample output:

    AMAZON - 326
    BBC - 128
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

#### IPSET List not Populating
##### Duplicate Host Entires
Beware of duplicate hosts entries when using the DNSMASQ script method to populate an IPSET list. In the example below, the nslookup commmand will only populate the first IPSET list in **/jffs/configs/dnsmasq.conf.add**.  
````
ipset=/pandora.com/PANDORA
ipset=/pandora.com/US_VPN
````
##### Local Caching DNS
There was an update made to the firmware in 384.12 that prevents IPSET lists from being populated when doing an **nslookup** on a domain name.

The router will now use ISP-provided resolvers instead of local dnsmasq when attempting to resolve addresses, for improved reliability. This reproduces how stock firmware behaves. This only affects name resolution done by the router itself, not by the LAN clients. The behavior can still be changed on the **Tools** -> **Other Settings page** -> **Wan: Use local caching DNS server as system resolver (default: No)**.

To resolve the issue, the installation script changes the default value to **"Yes"**.

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
    12       0     0 MARK       all  --  br0    *       0.0.0.0/0            0.0.0.0/0            match-set BBC dst MARK set 0x4000


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
The installation menu **x3mRouting** will display a menu with the options to install, update the current installation or remove the project from the router. The following table lists the files that will be downloaded for each method.

| Script Name   | LAN Clients   |  OpenVPN Client + IPSET Shell Scripts | IPSET Shell Scripts |
| --- | :---: | :---: | :---: |
|x3mRouting_client_nvram.sh         | X |   |   |
|x3mRouting_config.sh               | X |   |   |
|updown.sh                          | X | X |   |
|vpnrouting.sh                      | X | X |   |
|mount_files_lan.sh                 | X |   |   |
|mount_files_gui.sh                 |   | X |   |
|Advanced_OpenVPNClient_Content.asp |   | X |   |  
|x3mRouting.sh                      |   | X | X |
|openvpn-event                      |   | X | X |

## Acknowledgements
I want to acknowledge the following [snbforums](https://www.snbforums.com) members who helped make this project possible.
* [Martineau](https://www.snbforums.com/members/martineau.13215/) has, and continues to be, very generous in sharing his OpenVPN and Selective Routing expertise with me over the past several years. This project was only made possible through his support and collaboration. Through his guidance, I was able to navigate through the maze of of the firmware's **vpnrouting.sh** script and enhance it to create a much cleaner implementation of my selective routing requirements when compared to the method I had been using previously.

As part of the ongoing collaboration, Martineau had modified a selective routing script I wrote for routing Netflix traffic and enhanced it by enabling the passing of parameters. The enhancements made the script more user friendly by eliminating the need for users to edit scripts to meet their use case requirements. The enhancements have been applied to all of the IPSET scripts.

Martineau also contributed the modified **OpenVPN Client screen**, the [Vimeo](https://vimeo.com/287067217) video and **Chk_Entware** function used in the project.

* [Adamm](https://github.com/Adamm00) contributed the code for restoring the IPSET lists using the **awk** method and the **md5sum** check function to detect updated code on GitHub were also inspired by Adamm.

* For the installation script, [Jack Yaz](https://github.com/jackyaz/spdMerlin) gave me permission to clone the code he used for the update code function (also inspired by Adamm) used on the [SpdMerlin](https://github.com/jackyaz/spdMerlin) project on GitHub.

* Gratitude to the [thelonelycoder](https://www.snbforums.com/members/thelonelycoder.25480/), also known as the [Decoderman](https://github.com/decoderman) on GitHub, for his inspiration and ongoing support in my coding journey.

* Thank you to [RMerlin](https://www.snbforums.com/members/rmerlin.10954/) for the [Asuswrt-Merlin](https://github.com/RMerl/asuswrt-merlin.ng) firmware and helpful support on the [snbforums.com](https://www.snbforums.com/forums/asuswrt-merlin.42/) website. To learn more about Asuswrt-Merlin firmware for Asus routers, visit the project website at [https://asuswrt.lostrealm.ca/source](https://asuswrt.lostrealm.ca/source).
