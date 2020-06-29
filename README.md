# x3mRouting ~ Selective Routing for Asuswrt-Merlin Firmware
[![Build Status](https://travis-ci.com/Xentrk/x3mRouting.svg?branch=master)](https://travis-ci.com/Xentrk/x3mRouting)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/561d1570ed1f4d6aab76bba172f6b31f)](https://www.codacy.com/app/Xentrk/x3mRouting?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=Xentrk/x3mRouting&amp;utm_campaign=Badge_Grade)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

## Introduction
**x3mRouting** includes selective routing features for LAN Clients, OpenVPN Clients and OpenVPN Servers.

If coming from the first generation of x3mRouting, please read the updated instructions below to become familiar with the new features and usage instructions. Refer to the [Version 2.0.0 Changes](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#version-200-changes) section for a description of the changes and the [Version 2.0.0 Update Process](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#version-200-update-process) section for the update instructions.

### 1. LAN Client Routing

An alternative approach to automate and easily assign LAN clients to a WAN or VPN Client interface. This option eliminates the need to enter the LAN Client information and IP addresses in the OpenVPN Client Screen. The [LAN Clients Routing](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#1-lan-client-routing-1) option can be used by itself or with one of the two options below.

### 2. OpenVPN Client Screen, OpenVPN Event & x3mRouting.sh Script

Provides the ability to create IPSET lists using the **x3mRouting.sh** script and selectively route the IPSET lists thru the VPN Client by entering the IPSET name in a modified [OpenVPN Client Screen](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#2-openvpn-client-screen-openvpn-event--x3mroutingsh-script-1).

### 3. OpenVPN Event & x3mRouting.sh Script

The [x3mRouting.sh](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#3-openvpn-event--x3mroutingsh-script-1) script provides the ability to

  * Create and selectively route IPSET lists to the VPN Client interface for all traffic or specific devices.
  * Bypass a VPN Client interface for all traffic or specific devices.
  * Route VPN Server 1, 2 or both to one of the VPN Clients.
  * Selectively route VPN Server 1, 2 or both to the same routing rules as an IPSET.

The features of **openvpn-event** are used to create the routing rule during a VPN Client up event and remove the routing rule during a VPN Client down event.

### 4. getdomainnames.sh & autoscan.sh Scripts
These two scripts can be used to analyze the domain names being used for a website or streaming service.

The [getdomainnames.sh](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#getdomainnamessh-script) script will create a uniquely sorted list of domain names gathered from **dnsmasq.log** that you collect by accessing a website or streaming service. Use the script to help determine the domain names used by a website or streaming service.

The [autoscan.sh](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#autoscansh-script) script is used to search for one or more terms in **dnsmasq.log**. It will return the top level domain names if there is a match.

## Support
For help and support, please visit the Asuswrt-Merlin x3mRouting support thread on [snbforums.com](https://www.snbforums.com/threads/x3mrouting-selective-routing-for-asuswrt-merlin-firmware.57793/#post-506675).

## Requirements
1. An Asus router with [Asuswrt-Merlin](http://asuswrt.lostrealm.ca/) firmware installed.
2. A USB drive with [entware](https://github.com/RMerl/asuswrt-merlin/wiki/Entware) installed. Entware can be installed using [amtm - the SNBForum Asuswrt-Merlin Terminal Menu](https://www.snbforums.com/threads/amtm-the-snbforum-asuswrt-merlin-terminal-menu.42415/)
3. Policy Rules (Strict) or Policy Rules enabled on the OpenVPN Client Screen.

## Project Development
I used Amazon Prime, BBC, CBS All Access, Hulu, Netflix and Sling streaming media services in developing the project and include them in the usage examples below.

Please beware that Amazon Prime, BBC, Hulu and Netflix block known VPN servers. If you want a VPN provider who can circumvent the VPN blocks, see my blog post [Why I use Torguard as my VPN Provider](https://x3mtek.com/why-i-use-torguard-as-my-vpn-provider) to learn more.

## Installation

Copy and paste the command below into an SSH session:

```
sh -c "$(curl -sL https://raw.githubusercontent.com/Xentrk/x3mRouting/x3mRouting-NG/Install_x3mRouting.sh)"
```

This command will download and install the installation menu **x3mRouting_Menu.sh** to the **/jffs/addons/x3mRouting** directory. The installation script is a menu with options to install the four options described below, including options to update or remove the x3mRouting files in **/jffs/scripts/x3mRouting**. To access the installation menu, type the command **x3mMenu**. Option **[7]  Update x3mRouting Menu** will only appear when a new installation menu is detected on the GitHub repository. Option **[u]  Update x3mRouting to Version 2.0.0** will only appear if you have the prior version of x3mRouting installed.

<img src="https://github.com/Xentrk/x3mRouting/blob/x3mRouting-NG/InstallationMenu.PNG" alt="drawing" width="600" height="600"/>

## x3mRouting Options

### [1] LAN Client Routing
In the Asuswrt-Merlin firmware, one must type the IP address of each LAN client into the Policy Routing section of the OpenVPN Client Screen in order to assign the LAN client to the VPN Client interface. If you have many LAN clients, the process of entering the IP address and other required information can be time consuming - especially after performing a factory reset.

The x3mRouting LAN Client method is an alternative approach to assigning LAN clients to a WAN or VPN Client interface. If you have many LAN clients to assign to the interface, the scripts will eliminate the manual effort involved in typing the DHCP IP address of each LAN client in the Policy Routing section of the OpenVPN Client Screen. You can still use the OpenVPN Client Screen to assign LAN clients in addition to using this feature. The two methods can coexist.

#### x3mRouting_client_config.sh
**x3mRouting_client_config.sh** is run automatically when installing LAN Client Routing. The script will create the file **/jffs/scripts/x3mRouting/x3mRouting_client_rules** which contains a separate line for each LAN client with a static DHCP IP address assignment. Each line contains three fields separated by a space. The first field is a number representing the interface assignment (0=WAN, 1=OVPNC1 to 5=OVPNC5) followed by the LAN client IP address and LAN client description.

By default, the script assigns each LAN client to the OVPNC1 interface. After running the script, edit the **/jffs/scripts/x3mRouting/x3mRouting_client_rules** file and assign the interface to each LAN client. Instructions on how to assign the interface to each LAN client are located at the top of the file.

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

If an existing **/jffs/scripts/x3mRouting/x3mRouting_client_rules** file exists, a backup copy of the existing **x3mRouting_client_rules** file is made by appending the timestamp to the existing file. You only need to run this script if you have made changes to DHCP static assignments or deleted the **/jffs/scripts/x3mRouting/x3mRouting_client_rules** file and all backups.

#### x3mRouting_client_nvram.sh
**x3mRouting_client_nvram.sh** script will create the nvram files for VPN Clients in the **/jffs/addons/x3mRouting** directory based on the interface assignments in **/jffs/scripts/x3mRouting/x3mRouting_client_rules**. An nvram file will not be created in the **/jffs/addons/x3mRouting/** directory for LAN clients assigned to use the WAN interface. The OpenVPN Client is then restarted to apply the routing assignments.

The routing rules for LAN Clients will automatically be applied upon a system boot. You only need to rerun **x3mRouting_client_nvram.sh** if you have made LAN Client interface assignment changes in the **/jffs/scripts/x3mRouting/x3mRouting_client_rules** file.

### [2] OpenVPN Client Screen, OpenVPN Event & x3mRouting.sh Script
![Policy Routing Screen](https://github.com/Xentrk/x3mRouting/blob/x3mRouting-NG/Policy_Routing_Screen.PNG "Policy Routing Screen")

#### OpenVPN Client Screen
As part of this project, you can also choose to install a modified OpenVPN Client Screen to selectively route IPSET lists through a VPN Client. [@Martineau](https://www.snbforums.com/members/martineau.13215/) coded the revisions to the OpenVPN Client Screen as a proof of concept on how the Policy Rules section could be modified to incorporate the selective routing of IPSET lists. The screen has been adapted for x3mRouting to allow the routing of IPSET lists to the WAN interface to support VPN Bypass Routing.

Starting with Asuswrt-Merlin 384.18, the default Source IP address is null. You can still specify "0.0.0.0" as the Source IP address on the screen. But it will be converted and stored as a null value to save nvram space. When the Source IP address is null, the routing rule will apply to all LAN Clients. Alternatively, you can specify a LAN Client IPv4 addresses or CIDR as the Source IP address for both LAN Clients and IPSET lists.

##### Advantages and Disadvantages of using the modified OpenVPN Client Screen
If you prefer to use the modified OpenVPN Client Screen, create the IPSET list without specifying the source and destination interfaces. The IPSET list must then be entered in the policy routing section.

If you create the IPSET list and specify the source and destination interfaces, no further action is required. **x3mRouting.sh** will automatically manage the IPSET routing rules using the features of **openvpn-event**.

The advantage of the screen is that it provides a visual depiction of what IPSET lists are being routed or bypassed through the OpenVPN Client. The disadvantage is the extra step required to manually enter the IPSET list in the screen. Note the known issues and work around solutions in the [Caveat Emptor](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#caveat-emptor) section before making a decision on using the modified OpenVPN Client Screen.

##### IPSET Dimensions
The OpenVPN Client Screen accepts single and two dimension IPSET lists. See the [IPSET Man Page](http://ipset.netfilter.org/ipset.man.html) for information. For most x3mRouting use cases, specify 'DST' as the first dimension and leave the second dimension empty to route an IPSET list to the VPN or WAN interface.

##### DummyVPN
Note the **DummyVPN1** entry in the screen above. For the selective routing of IPSETs, creating a “dummy” VPN Client entry is required if no routing rules exist for LAN clients and you need to exploit the **Accept DNS Configuration=Exclusive** feature. The appropriate DNSVPN iptables chain rules will only get created if the routing table isn't empty in the OpenVPN Client Screen. Use a [bogon IP address](https://ipinfo.io/bogon) for this purpose. Use the word "DummyVPN" as the first eight characters followed by the number of the VPN Client. This will prevent a Routing Policy Database Rule (RPDB) reservation from getting created for the DummyVPN entry.  

##### Caveat Emptor
The "dummy" VPN Client entry is also a work around solution for an issue with the modified screen. Applying changes to the screen will not work if there are IPSET entries in the IPSET routing table but no client entries in the client routing table. The "dummy" VPN Client entry in the routing client traffic tables solves the problem. If this condition is encountered, a warning message will be displayed.

If you delete a LAN Client entry in the policy routing table, then add another LAN Client entry before applying the change, the IPSET lists in the policy routing table will disappear when the Add button is selected. The work around solution is to first apply the deletion entry. Then, add the revised entry and apply the change.

I welcome collaboration with other developers to help resolve these issues.
#### OpenVPN Event & x3mRouting.sh Script
Running **x3mRouting** will automatically create the script entry in **/jffs/scripts/nat-start/**. Placing the script entry in **/jffs/scripts/nat-start** will execute the scripts at system boot or during a firewall restart event. The features of **openvpn-event** are not used for the routing of IPSET lists entered in the modified OpenVPN Client Screen. **openvpn-event** is installed to support the routing functions available in x3mRouting that don't require the use of the modified OpenVPN Client Screen:  

* [VPN Client Routing](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#vpn-client-routing)
* [VPN Client Bypass Routing](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#vpn-client-bypass-routing)
* [VPN Server to VPN Client Routing](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#vpn-server-to-vpn-client-routing-1)
* [VPN Server to IPSET List Routing](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#vpn-server-to-ipset-list-routing)

##### IPSET Methods
To create an IPSET list, x3mRouting requires that one of the following methods be specified.

* [AMAZON AWS Region Method](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#amazon-aws-region-method-1)
* [ASN Method](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#asn-method-1)
* [dnsmasq Method](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#dnsmasq-method-1)
* [dnsmasq Method with autoscan](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#dnsmasq-method-with-autosccan)

If no method is specified, x3mRouting will default to the [Manual Method](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#manual-method-1). You can also manually create an IPSET list using the [Manual Method with 'ip='](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#manual-method-with-ip).

#### Create an IPSET List with no Routing Rules Usage Notes
You must specify the 'ipset_name=' parameter when no routing rules are specified. Use the OpenVPN Client Screen to create the routing rules.
* Required parameters are listed inside the braces { }
* Optional parameters are listed inside of the brackets [ ]
````
x3mRouting {ipset_name=}
           ['autoscan='keyword1[,keyword2]...] # Scans for keywords and creates IPSET list using the dnsmasq method
           ['asnum='asnum[,asnum]...] # ASN method
           ['aws_region='US[,EU]...]  # Amazon method
           ['dnsmasq='domain[,domain]...] # dnsmasq method
           ['ip='ip[,ip][,cidr]...] # Equivalent to manual method
           ['dir='save_restore_location] # if 'dir' not specified, defaults to /opt/tmp
           ['del']
````
#### Create an IPSET List with no Routing Rules Usage Examples

##### ASN Method
Create IPSET list NETFLIX using AS2906 as the source
````
x3mRouting ipset_name=NETFLIX asnum=AS2906  
````
#####  Amazon AWS Region Method
Create IPSET list AMAZON_US created from Amazon US region
````
x3mRouting ipset_name=AMAZON_US aws_region=US
````
##### dnsmasq Method
Create IPSET list NETFLIX using the dnsmasq method
````
x3mRouting ipset_name=NETFLIX dnsmasq=netflix.com,nflxext.com,nflximg.net,nflxso.net,nflxvideo.net
````
##### dnsmasq Method with autoscan
Search **dnsmasq.log** file for domains that contain the keyword "amazon" and create the IPSET list AMAZON from the domains collected using the dnsmasq method. You can view the domains collected by looking at the corresponding entry in **/jffs/configs/dnsmasq.conf.add** or by looking at the script entry in **/jffs/scripts/nat-start**
````
x3mRouting AMAZON autoscan=amazon
````
##### Manual Method

Create IPSET list BBC using the manual method
````
x3mRouting ipset_name=BBC
````
Create IPSET list WIMIPCOM created from the IPv4 addresses provided.
````
x3mRouting WIMIPCOM ip=104.27.198.90,104.27.199.90
````
Create IPSET list BBC using the manual method. Use the 'dir=' location as the backup/restore location
````
x3mRouting ipset_name=BBC dir=/tmp/mnt/RT-AC88U/mylists
````
#### Delete an IPSET List, routing rules, script entries and cru jobs
````
x3mRouting ipset_name=MYIPSET del
`````

### [3] OpenVPN Event & x3mRouting.sh Script

Running **x3mRouting** will automatically perform the set-up. The features of **openvpn-event** are used to create the routing rule during a VPN Client up event and remove the routing rule during a VPN Client down event. **/jffs/scripts/nat-start** is used to execute the scripts at system boot or during a firewall restart event.

#### IPSET Methods
To create an IPSET list, x3mRouting requires that one of the following methods be specified

* [AMAZON AWS Region Method](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#amazon-aws-region-method-1)
* [ASN Method](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#asn-method-1)
* [dnsmasq Method](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#dnsmasq-method-1)
* [dnsmasq Method with autoscan](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#dnsmasq-method-with-autosccan)

If no method is specified, x3mRouting will default to the [Manual Method](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#manual-method-1). You can also manually create an IPSET list using the [Manual Method with 'ip='](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#manual-method-with-ip).

Optional **'src='** and **'src_range='** parameters provides the option to specify the source IP address or source IP address ranges of LAN devices you want the routing rules to be applied to.

##### AMAZON AWS Region Method
**x3mRouting.sh** script will create an IPSET list containing all IPv4 address for the Amazon AWS region(s) specified. The source file used by the script is provided by Amazon at [https://ip-ranges.amazonaws.com/ip-ranges.json](https://ip-ranges.amazonaws.com/ip-ranges.json). You must specify the **'aws_region='** parameter and one or more of the regions below, separated by a comma, when creating the IPSET list:

###### Valid Amazon AWS Regions
* AP - Asia Pacific
* CA - Canada
* CN - China
* EU - European Union
* SA - South America
* US - USA
* GV - USA Government
* GLOBAL - Global

##### ASN Method
x3mRouting will create an IPSET list using the [AS Number](https://www.apnic.net/get-ip/faqs/asn/) specified using the **'asnum='** parameter and one or more valid AS numbers separated by a comma. The IPv4 addresses are downloaded from [ipinfo.io](https://ipinfo.io/). ipinfo.io may require whitelisting if you use an ad-blocker program. If x3mRouting is unable to download the IP addresses from ipinfo.io, it will attempt to download using the aslookup tool on [api.hackertarget.com/aslookup/](https://api.hackertarget.com/aslookup/).

##### dnsmasq Method
You must specify the **'dnsmasq='** parameter and one or more domain names separated by a comma.

##### dnsmasq Method with autosccan
This method will search **dnsmasq.log** for domain names that match the search criteria specified on the **'autoscan='** parameter. One or more search criteria can be provided using a comma delimited list. The domains collected will be used to create an IPSET list using the dnsmasq method.

##### Manual Method
The manual method is used to create IPSET lists from a file in the backup/restore directory containing the IPv4 addresses and/or IPv4 CIDR format that you created manually, either using an editor, script or other method to populate the file with IPv4 addresses.

##### Manual Method with 'ip=''
The manual method with **'ip='** parameter is used to create IPSET lists from one or more IP addresses separated by a comma.

#### x3mRouting Usage Notes

* Required parameters are listed inside the braces { }
* Optional parameters are listed inside of the brackets [ ]
* Valid parameter values are listed in parenthesis ( ). The vertical lines "|" are used to separate the values in the list. Example: (1|2|both)

##### Create IPSET List with Routing Rules
Provides the ability to:
* Create and selectively route IPSET lists to the VPN Client interface or bypass a VPN Client interface for all traffic or specific devices.
* Route VPN Server traffic to one of the VPN Clients.
* Selectively route VPN Server traffic to an existing IPSET list routing rule.

````
x3mRouting {src iface} (ALL|1|2|3|4|5)
           {dst iface} (0|1|2|3|4|5)
           **START: src/dst usage notes**
           Valid SRC and DST Combinations
           1) VPN Client Routing
              - Use this SRC and DST combination to route all IPSET list traffic to a VPN Client:
                ALL 1, ALL 2, ALL 3, ALL 4, ALL 5
           2) VPN Bypass Routing
              - Use this SRC and DST combination to bypass the VPN Client for an IPSET list and route to the WAN interface:
                1 0, 2 0, 3 0, 4 0, 5 0
           **END: src/dst usage notes**
           {ipset_name}
           ['autoscan='keyword1[,keyword2]...] # Scans for keywords and creates IPSET list using the dnsmasq method
           ['asnum='asnum[,asnum]...] # ASN method
           ['aws_region='US[,EU]...]  # Amazon method
           ['dnsmasq='domain[,domain]...]  # dnsmasq method
           ['ip='ip[,ip][,cidr]...]  # Equivalent to manual method
           ['src='src_ip]  # Apply rule to IP address
           ['src_range='from_ip-to_ip]  # Apply rule to IP address range
           ['dir='save_restore_location]  # if 'dir' not specified, defaults to /opt/tmp
           ['del']
````

##### VPN Server to VPN Client Routing
````
x3mRouting {'server='1|2|both} {'client='1|2|3|4|5} ['del']
````

##### VPN Server to existing LAN routing rules for one or more IPSET lists
````
x3mRouting {'server='1|2|both} {'ipset_name='IPSET[,IPSET]...} ['del']
````

#### x3mRouting Usage Examples
Usage examples are provided below for the following routing functions:  
  * [VPN Client Routing](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#vpn-client-routing)
  * [VPN Client Bypass Routing](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#vpn-client-bypass-routing)
  * [VPN Server to VPN Client Routing](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#vpn-server-to-vpn-client-routing-1)
  * [VPN Server to IPSET List Routing](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#vpn-server-to-ipset-list-routing)
  * [Delete an IPSET List, all Routing Rules and cru Jobs](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#delete-an-ipset-list-all-routing-rules-and-cru-jobs)
  * [Delete a VPN Server to VPN Client Routing Rule](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#delete-a-vpn-server-to-vpn-client-routing-rule)
  * [Delete a VPN Server to IPSET list Routing Rule](https://github.com/Xentrk/x3mRouting/tree/x3mRouting-NG#delete-a-vpn-server-to-ipset-list-routing-rule)

#### VPN Client Routing
Use this approach to route IPSET traffic to a VPN Client.

##### ASN Method

Route all traffic matching IPSET list NETFLIX created from AS2906 to VPN Client1.

    x3mRouting ALL 1 NETFLIX asnum=AS2906

Route all traffic matching IPSET list BBC created from AS2818 and AS31459 to VPN Client1.

    x3mRouting ALL 1 BBC asnum=AS2818,AS31459

Route all traffic matching IPSET list NETFLIX created from AS2906 to VPN Client1 from LAN device 192.168.1.152.   

    x3mRouting ALL 1 NETFLIX asnum=AS2906 src=192.168.1.152

##### Amazon AWS Region Method
Route all traffic matching IPSET list AMAZON_US created from the AWS US region to VPN Client 1.

    x3mRouting ALL 1 AMAZON_US aws_region=US

Route all traffic matching IPSET list AMAZON created from the AWS US and CA regions to VPN Client 1.

    x3mRouting ALL 1 AMAZON aws_region=US,CA

Route IP address ranges 192.168.1.152-192.168.1.157 traffic matching IPSET list AMAZON_US created from the Amazon US region to VPN Client 1.

    x3mRouting ALL 1 AMAZON_US aws_region=US src_range=192.168.1.152-192.168.1.157

##### dnsmasq Method
Route all traffic matching IPSET list NETFLIX created from domain names to VPN Client1.
````
x3mRouting ALL 1 NETFLIX  dnsmasq=netflix.com,nflxext.com,nflximg.net,nflxso.net,nflxvideo.net
````

##### dnsmasq Method with autoscan
Search **dnsmasq.log** file for domains that contain the keyword "amazon" and create the IPSET list AMAZON from the domains collected using the dnsmasq method. You can view the domains collected by looking at the corresponding entry in **/jffs/configs/dnsmasq.conf.add** or by looking at the script entry in **/jffs/scripts/nat-start**

````
x3mRouting ALL 1 AMAZON autoscan=amazon
````

Search **dnsmasq.log** file for domains that contain the keywords "amazonaws", "netflix" and "nflx" and create the IPSET list AMZ_NFLX using the dnsmasq method.

    x3mRouting ALL 1 AMZ_NFLX autoscan=amazonaws,netflix,nflx

##### Manual Method

Route all traffic matching IPSET list WIMIPCOM to VPN Client 1.

    x3mRouting ALL 1 WIMIPCOM

Route all traffic matching IPSET list WIMIPCOM to VPN Client 1 using the /mnt/ASUS/mylists directory as the save/restore location.

    x3mRouting ALL 1 WIMIPCOM dir=/mnt/ASUS/mylists

Route all VPN Client 1 traffic matching IPSET list WIMIPCOM created from the IPv4 addresses provided.

    x3mRouting ALL 1 WIMIPCOM ip=104.27.198.90,104.27.199.90

#### VPN Client Bypass Routing
Use this approach to bypass the VPN Client for traffic matching an IPSET list and route to the WAN interface. This approach is often used when a rule to route the entire LAN (e.g. 192.168.1.0/24) thru a VPN Client exists in the Policy Routing section of the OpenVPN Client Screen and an exception needs to be made to bypass the VPN Client for a service that blocks known VPN Servers.

##### ASN Method
Route VPN Client 1 traffic matching IPSET list NETFLIX to WAN.

````
x3mRouting 1 0 NETFLIX asnum=AS2906
````

Route VPN Client 1 traffic from 192.168.1.152 matching IPSET list NETFLIX to WAN.

````
x3mRouting 1 0 NETFLIX asnum=AS2906 src=192.168.1.152
````

##### Amazon AWS Region Method
Route VPN Client 1 traffic matching IPSET list AMAZON_US to WAN.
````
x3mRouting 1 0 AMAZON_US aws_region=US
````
Route VPN Client 1 traffic from 192.168.1.152-192.168.1.157 matching IPSET list AMAZON_US to WAN.
````
x3mRouting 1 0 AMAZON_US aws_region=US src_range=192.168.1.152-192.168.1.157
````
##### dnsmasq Method
Route all VPN Client 1 traffic matching IPSET list WIMIPCOM to the WAN.
````
x3mRouting 1 0 WIMIPCOM dnsmasq=whatismyip.com
````
Route all VPN Client 1 traffic matching IPSET list NETFLIX to the WAN.       
````
x3mRouting 1 0 NETFLIX dnsmasq=netflix.com,nflxext.com,nflximg.net,nflxso.net,nflxvideo.net
````
Route VPN Client 1 traffic from 192.168.1.152 matching IPSET list NETFLIX to WAN.
````
x3mRouting 1 0 NETFLIX domain=netflix.com,nflxext.com,nflximg.net,nflxso.net,nflxvideo.net src=192.168.1.152
````
##### Manual Method

Route all VPN Client 1 traffic matching IPSET list WIMIPCOM to the WAN.
````
x3mRouting 1 0 WIMIPCOM
````
Route all VPN Client 1 traffic matching IPSET list WIMIPCOM created from the IPv4 addresses provided to the WAN.
````
x3mRouting 1 0 WIMIPCOM ip=104.27.198.90,104.27.199.90
````
Route VPN Client 1 traffic from 192.168.1.152 matching IPSET list WIMIPCOM to the WAN.
````
x3mRouting 1 0 WIMIPCOM src=192.168.1.152
````
Route VPN Client 1 traffic from 192.168.1.152-192.168.1.157 matching IPSET list WIMIPCOM to WAN.       
````
x3mRouting 1 0 WIMIPCOM src_range=192.168.1.152-192.168.1.157
````
#### VPN Server to VPN Client Routing
Route from VPN Server 1,2 or both to VPN Client 1,2,3,4 or 5.
````
x3mRouting server=1 client=1
x3mRouting server=2 client=1
x3mRouting server=both client=1
````
#### VPN Server to IPSET List Routing
Route from VPN Server 1,2 or both the same routing rules for the IPSET list PANDORA.
````
x3mRouting server=1 ipset_name=PANDORA
x3mRouting server=2 ipset_name=PANDORA
x3mRouting server=both ipset_name=PANDORA
````

Route from VPN Server 1 to the IPSET lists PANDORA and NETFLIX.
````
x3mRouting server=1 ipset_name=PANDORA,NETFLIX
````
##### Requirements
1. The IPSET list must exist!
2. A PREROUTING rule must currently exist so the script can determine the VPN Client to route to!

#### Delete an IPSET List, Routing Rules, Script Entries and cru jobs
Either option listed below will work. The first example is the easiest as there is no requirement to specify the interfaces or method.
````
x3mRouting ipset_name=MYIPSET del
x3mRouting ALL 1 NETFLIX del
````
#### Delete a VPN Server to VPN Client Routing Rule
VPN Server to VPN Client routing rules require the VPN Server and Client to properly remove the iptables rules.
````
x3mRouting server=1 client=1 del
````

#### Delete a VPN Server to IPSET list Routing Rule
VPN Server to IPSET list routing rules require the VPN Server and IPSET name to properly remove the iptables rules.
````
x3mRouting server=1 ipset_name=PANDORA del
````

### [4] getdomainnames.sh and autoscan.sh Scripts
#### getdomainnames.sh Script
**getdomainnames.sh** script will create a uniquely sorted list of domain names from **dnsmasq.log** that you collected by accessing a website or streaming service. Use the script when analyzing domains used by a website or streaming service. The script requires that the **dnsmasq.log** file exists in the **/opt/var/log** directory. You must first enable dnsmasq logging if it's not enabled using the instructions below. You can also enabling dnsmasq logging by installing [Diversion, the Router Ad-Blocker for Asuswrt-Merlin](https://diversion.ch/).

##### Enable dnsmasq Logging
1. Navigate to the **/jffs/configs** directory e.g **cd /jffs/config**
2. Use your SFTP or SSH client to create the **dnsmasq.conf.add** file
3. Add the following entry to **/jffs/configs/dnsmasq.conf.add**:
````
log-async
log-queries
log-facility=/opt/var/log/dnsmasq.log    
````
4. Save and exit **dnsmasq.conf.add**
5. Restart dnsmasq
````
service restart_dnsmasq
````

##### getdomainnames.sh Usage Instructions
1. Navigate to the **/jffs/scripts/x3mRouting** file directory (e.g. cd /jffs/scripts/x3mRouting).
2. Run the script (e.g. sh getdomainnames.sh).
3. You will be prompted for a file name that will be used to store the domain names collected.
4. Next, you will be prompted for the IPv4 address of the device you are using to perform the lookups.
5. When prompted, go to the website or access the streaming service and select each option to generate traffic and collect domain names.
6. When done, type **Ctrl-C** to stop collecting domain names.
7. The domain names collected will appear on the screen. They are also stored in the file you specified in the **/opt/var/log** directory for future reference.

#### autoscan.sh Script
**autoscan.sh** can be used to search for terms in **dnsmasq.log** and return the top level domain names when a match is found. You can specify one or  more search term by separating the search terms with a comma. The top level domain names the script returns can be specified when using the **dnsmasq** method.

````
sh autoscan.sh autoscan=disney

demdex.net
disney-plus.net
disney.com
disney.io
disneyplus.com
footprint.net
go.com
````

````
sh autoscan.sh autoscan=netflix,nflx

netflix.com
nflxext.com
nflximg.net
nflxso.net
nflxvideo.net
````

## Helpful Tips, Validation and Troubleshooting

### Alternative Methods Used to Identify Domain Names
#### View Source Code
Open up a desktop browser session and go to the home page for the streaming service. Right click on the page and select the option to view the page source code. In Firefox, the option is **View Page Source**. Search for the words **".com"** and **".net"**.

#### Follow the Log File
Use the **"Follow the log file"** option of [Diversion](https://diversion.ch) ad blocker to filter the log file view by LAN Client to see what domain names are being looked up.

#### How to determine AS Numbers for streaming services
Use the site [https://bgp.he.net](https://bgp.he.net/) to find AS Numbers for streaming services. You can type the name of the streaming service in the **search box** or an IP address.

Alternatively, you can use the **nslookup** command to find the IP address of a domain name. Then use the **whob** command to find the AS Number and subnet address for the IP address.

    # nslookup occ-0-1077-1062.1.nflxso.net

    Server:    127.0.0.1
    Address 1: 127.0.0.1 localhost.localdomain

    Name:      occ-0-1077-1062.1.nflxso.net
    Address 1: 2a00:86c0:600:96::138 ipv6_1.lagg0.c009.lax004.ix.nflxvideo.net
    Address 3: 198.38.96.132 ipv4_1.lagg0.c003.lax004.ix.nflxvideo.net

    # whob 198.38.96.132

    IP: 198.38.96.132
    Origin-AS: 2906
    Prefix: 198.38.96.0/19
    AS-Path: 20912 3257 3356 2906
    AS-Org-Name: Netflix Streaming Services Inc.
    Org-Name: Netflix Streaming Services Inc.
    Net-Name: SSI-CDN-2
    Cache-Date: 1590306161
    Latitude: 39.738008
    Longitude: -75.550353
    City: Wilmington
    Region: Delaware
    Country: United States
    Country-Code: US

Use the subnet address to validate the entry exists in the IPSET list:

    ipset -L NETFLIX | grep 198.38.96.0/19
    198.38.96.0/19

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
Beware of duplicate hosts entries when using the dnsmasq method to populate an IPSET list. In the example below, the nslookup command will only populate the first IPSET list matched in **/jffs/configs/dnsmasq.conf.add**.
````
ipset=/pandora.com/PANDORA
ipset=/pandora.com/US_VPN
````
##### Local Caching DNS
There was an update made to the firmware in 384.12 that appears to prevent IPSET lists from being populated when doing an **nslookup** on a domain name.

The router will now use ISP-provided resolvers instead of local dnsmasq when attempting to resolve addresses, for improved reliability. This reproduces how stock firmware behaves. This only affects name resolution done by the router itself, not by the LAN clients. The behavior can still be changed on the **Tools** -> **Other Settings page** -> **Wan: Use local caching DNS server as system resolver (default: No)**.

#### VPN and LAN Client RPDB Routing and Priorities Rules
Type the command

    ip rule

to display the RPDB routing priority database rules for the VPN Server, VPN Server and LAN Clients:

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

##### iptables mangle table PREROUTING Chain

Enter the following command to display the PREROUTING IPTABLES Chains for the mangle table:

    iptables -nvL PREROUTING -t mangle --line

The output will display the number of packets and bytes traversing the iptables rule for each IPSET list which can be used as confirmation that traffic is being routed properly:

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

##### iptables nat table POSTROUTING Chain

Enter the following command to display the POSTROUTING IPTABLES Chains for the nat table:

    iptables -nvL POSTROUTING -t nat --line

The output will display the number of packets and bytes traversing the iptables rule for the VPN Clients, VPN Server to VPN Client, and VPN Server to IPSET list routing which can be used as confirmation that traffic is being routed properly:

    Chain POSTROUTING (policy ACCEPT 258 packets, 30946 bytes)
    num   pkts bytes target     prot opt in     out     source               destination
    1        0     0 MASQUERADE  all  --  *      tun15   192.168.1.0/24      0.0.0.0/0
    2        0     0 MASQUERADE  all  --  *      tun14   192.168.1.0/24      0.0.0.0/0
    3      127  9282 MASQUERADE  all  --  *      tun11   192.168.1.0/24      0.0.0.0/0
    4        0     0 MASQUERADE  all  --  *      tun13   192.168.1.0/24      0.0.0.0/0
    5     1121 60169 MASQUERADE  all  --  *      tun12   192.168.1.0/24      0.0.0.0/0
    <snip>
    10       0     0 MASQUERADE  all  --  *      tun11   10.8.0.0/24          0.0.0.0/0
    11       0     0 MASQUERADE  all  --  *      tun15   10.16.0.0/24         0.0.0.0/0

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
The installation menu **x3mMenu** will display a menu with the options to install, update the current installation or remove the project from the router. The following table lists the files that will be downloaded for each method.

| Script Name   | Option [1] |  Option [2] | Option [3] | Option [4] |
| --- | :---: | :---: | :---: | :---: |
|x3mRouting_client_nvram.sh         | X |   |   |   |
|x3mRouting_client_config.sh        | X |   |   |   |
|updown-client.sh                   | X | X |   |   |
|vpnrouting.sh                      | X | X |   |   |
|mount_files_lan.sh                 | X |   |   |   |
|mount_files_gui.sh                 |   | X |   |   |
|Advanced_OpenVPNClient_Content.asp |   | X |   |   |
|x3mRouting.sh                      |   | X | X |   |
|openvpn-event                      |   | X | X |   |
|getdomainnames.sh                  |   |   |   | X |
|autoscan.sh                        |   |   |   | X |

## Acknowledgements
I want to acknowledge the following [snbforums](https://www.snbforums.com) members who helped make this project possible.
* [Martineau](https://www.snbforums.com/members/martineau.13215/) has, and continues to be, very generous in sharing his VPN and Selective Routing expertise with me over the past several years. This project was only made possible through his support and collaboration. Through his guidance, I was able to navigate through the maze of of the firmware's **vpnrouting.sh** script and enhance it to create a much cleaner implementation of my selective routing requirements when compared to the method I had been using previously.

As part of the ongoing collaboration, Martineau had modified a selective routing script I wrote for routing Netflix traffic and enhanced it by enabling the passing of parameters. The enhancements made the script more user friendly by eliminating the need for users to edit scripts to meet their use case requirements. The enhancements have been applied to all of the IPSET scripts.

Martineau also contributed the modified **OpenVPN Client Screen** and **Chk_Entware** function used in the project.

* [Adamm](https://github.com/Adamm00) contributed the code for restoring the IPSET lists using the **awk** method and the **md5sum** check function to detect updated code on GitHub were also inspired by Adamm.

* For the installation script, [Jack Yaz](https://github.com/jackyaz/spdMerlin) gave me permission to clone the code he used for the update code function (also inspired by Adamm) used on the [SpdMerlin](https://github.com/jackyaz/spdMerlin) project on GitHub.

* Gratitude to the [thelonelycoder](https://www.snbforums.com/members/thelonelycoder.25480/), also known as the [Decoderman](https://github.com/decoderman) on GitHub, for including x3mRouting in [amtm - the SNBForum Asuswrt-Merlin Terminal Menu](https://www.snbforums.com/threads/amtm-the-snbforum-asuswrt-merlin-terminal-menu.42415/).

* Thank you to [RMerlin](https://www.snbforums.com/members/rmerlin.10954/) for the [Asuswrt-Merlin](https://github.com/RMerl/asuswrt-merlin.ng) firmware and helpful support on the [snbforums.com](https://www.snbforums.com/forums/asuswrt-merlin.42/) website. To learn more about Asuswrt-Merlin firmware for Asus routers, visit the project website at [https://www.asuswrt-merlin.net/](https://www.asuswrt-merlin.net/).

* I want to also acknowledge the contributions of those who participated in the testing of x3mRouting Version 2.0.0: [Luizlp10](https://www.snbforums.com/members/luizlp10.66974/), [SomeWhereOverTheRainBow](https://www.snbforums.com/members/somewhereovertherainbow.64179/), [TechTinkerer](https://www.snbforums.com/members/techtinkerer.67560/), and [Torson](https://www.snbforums.com/members/torson.59919/)

## Version 2.0.0 Changes

#### x3mRouting Menu
The command to access the **x3mRouting** menu has been changed from **x3mRouting** to **x3mMenu**. A patch was also applied to fix the issue of code output appearing when exiting the menu after performing an update to the x3mRouting menu.

#### VPN Server and VPN Client Routing Script Changes
  * The separate scripts for:

    * IPSET list creation and routing using the ASN, Amazon AWS, dnsmasq and manual methods
    * VPN Server to VPN Client routing (route_all_vpnserver.sh)
    * VPN Server to IPSET routing (route_ipset_vpnserver.sh)

    have been removed and the features combined into one script called **x3mRouting.sh**.
  * The method used to create the IPSET list is passed to **x3mRouting.sh** as a parameter. If the ASN, Amazon AWS or dnsmasq parameter is not specified, **x3mRouting.sh** will default to the manual method.
  * **x3mRouting** has been configured as a command in /opt/bin with a symbolic link to **/jffs/scripts/x3mRouting.sh*, allowing **/jffs/scripts/x3mRouting/x3mRouting.sh** to be run from any location without specifying the path or "sh" command.   
  * Running **x3mRouting** will automatically perform the set-up.
    * **/jffs/scripts/nat-start** is used to execute the scripts at system boot or during a firewall restart event.
    * The features of **openvpn-event** are used to create the routing rule during a VPN Client up event and remove the routing rule during a VPN Client down event when the source and destination interfaces are specified.
  * Simplified the ability to delete an IPSET list and associated routing rules, nat-start and openvpn-event files, and cru jobs for VPN Client IPSET routing rules by passing the 'ipset_name=' and 'del' parameters to x3mRouting.sh. Deleting VPN Server to VPN Client and VPN Server to IPSET list routing rules still require that all parameters used to create the routing rules be specified in addition to the 'del' parameter.
  * **VPN Server to VPN Client** routing feature of **x3mRouting.sh**
    * The **x3mRouting.sh** script will create the required VPN Server nvram entry, eliminating the need to manually enter the VPN Server IP address in the OpenVPN Client Screen. The VPN Client will be restarted for the update to take effect.
  * **VPN Server to VPN Client** and **VPN Server to IPSET List**
    * The IP address of the VPN Server in the openvpn-event up/down scripts is no longer hard coded. Instead, the 'nvram get' command in the openvpn-event up/down scripts will be used to obtain the IP address of the VPN Server. This will eliminate the need to rerun the **x3mRouting.sh** script if the VPN Server IP address is changed.
    * Routing rules will now be applied during an VPN Client up event rather than a VPN Server up event. Based on user feedback, the routing from the VPN Server to the VPN Client would stop working after a VPN Client up/down event, even though the iptables rules were still in effect.
    * Added ability to specify
      * more than one ASN when using the ASN method
      * more than one AWS region when using the Amazon AWS method
      * one or more IPv4 address when creating an IPSET list.
      * one or more search criteria for domain names when using the 'autoscan' option.
      * that a routing rule to be applied to a single LAN IP addresses or IP address range.
      * one or more IPSET lists for VPN Server to IPSET routing.
    * Added ability to display usage notes by passing the 'help' parameter
````
      x3mRouting help
````

#### LAN Client Routing Changes
  * The script **x3mRouting_client_config.sh** now stores the output file **x3mRouting_client_config** in **/jffs/scripts/x3mRouting** rather than **/jffs/configs**.
  * The script **x3mRouting_client_nvram.sh** now stores the nvram files in **/jffs/addons/x3mRouting** rather than **/jffs/configs**.

#### x3mRouting Utility Files
  * The x3mRouting utility files Advanced_OpenVPNClient_Content.asp, updown-client.sh, vpnrouting.sh, and x3mRouting_Menu.sh files are stored in **/jffs/addons/x3mRouting** rather than the project repository directory **/jffs/scripts/x3mRouting**.

## Version 2.0.0 Update Process
You won't be able to update to Version 2.0.0 using the existing **x3mRouting** Menu due to the installation menu changes described above.  

  1.  Copy and paste the command below into an SSH session to download the new x3mRouting menu.

````
sh -c "$(curl -sL https://raw.githubusercontent.com/Xentrk/x3mRouting/x3mRouting-NG/Install_x3mRouting.sh)"
````
  2.  After the download of the x3mRouting Installation Menu has completed, select the **[u]  Update x3mRouting to Version 2.0.0** option.

During the update process, x3mRouting will:
  * Make a backup of **/jffs/scripts/nat-start** and copy the x3mRouting directory contents to **/jffs/scripts/x3mRouting/backup**.
  * Remove obsolete x3mRouting scripts.
  * Remove obsolete x3mRouting script in /opt/bin.
  * Any LAN Client Routing nvram files that exist in **/jffs/configs** will get moved to **/jffs/addons/x3mRouting** and the **x3mRouting_client_rules** to **/jffs/scripts/x3mRouting**.
  * **/jffs/scripts/nat-start** and openvpn-event files in the **/jffs/scripts/x3mRouting** directory will be scanned for references to the old scripts or routing rules. A conversion file will get created in **/jffs/scripts/x3mRouting/x3mRouting_Conversion.sh** containing the new script entries.
  * Backup **/jffs/configs/dnsmasq.conf.add** if it exists and delete any 'ipset=' entries. 'ipset=' entries will get recreated when you run the conversion script.
  * Remove prior x3mRouting version entries found in **/jffs/scripts/nat-start** or **vpnclientX-route-up** files. If only a **#!/bin/sh** or comment lines exist, the user will be prompted to remove the file. The recommendation is to select the option to remove the file. A backup of **nat-start** and the local x3mRouing repository exists in case you need to recover.
  * Update the remaining x3mRouting scripts to the new version.

  3. View the **/jffs/scripts/x3mRouting/x3mRouting_Conversion.sh** script and validate.
     * A line showing the prior entry and file source will be shown with the new entry.
     * Entries involving routing to the WAN interface may require an edit as the new version requires the VPN Client number to bypass be specified in order to peform the setup and configuration. The conversion utility will default to VPN Client 1 as the VPN Client to bypass. If necessary, edit the '1' to be the VPN Client number '1-5' you want to bypass.
      * If you have an entry for **VPN Server to IPSET List" routing, you must validate that the entry for creating the IPSET list is run before the **VPN Server to IPSET List** entry. Otherwise, the **VPN Server to IPSET List" entry will fail since the IPSET list and associated routing rules do not exist.
      * When done, save the conversion script and execute it (e.g. **sh x3mRouting_Conversion.sh**).

##### Example x3mRouting_Conversion.sh
````
#!/bin/sh
# Source File====> /jffs/scripts/nat-start
# Original Entry=> sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset_iface.sh 5 MOVETV movetv.com
sh /jffs/scripts/x3mRouting/x3mRouting.sh ALL 5 MOVETV dnsmasq=movetv.com

# Source File====> /jffs/scripts/nat-start
# Original Entry=> sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset_iface.sh 2 PANDORA pandora.com
sh /jffs/scripts/x3mRouting/x3mRouting.sh ALL 2 PANDORA dnsmasq=pandora.com

# If the source VPN Client you want to bypass is '1', then no changes are required.
# Otherwise, edit the '1' to be a valid VPN Client number '1-5'
# Source File====> /jffs/scripts/nat-start
# Original Entry=> sh /jffs/scripts/x3mRouting/load_DNSMASQ_ipset_iface.sh 0 WIMIPCOM whatismyipaddress.com
sh /jffs/scripts/x3mRouting/x3mRouting.sh 1 0 WIMIPCOM dnsmasq=whatismyipaddress.com

# Found VPN Server to IPSET list iptables entries in /jffs/scripts/x3mRouting/vpnserver1-up
sh /jffs/scripts/x3mRouting/x3mRouting.sh server=1 ipset_name=PANDORA

# Found VPN Server to VPN Client iptables entries in /jffs/scripts/x3mRouting/vpnserver1-up
sh /jffs/scripts/x3mRouting/x3mRouting.sh server=1 client=1
````
  4.  After execution, the IPSET list and associated routing rules, if specified, will be created along with the required entries in **/jffs/scripts/nat-start** and appropriate openvpn-event up/down files.

  5. Run the commands below to validate VPN Server POSTROUTING and VPN Client PREROUTING rules. POSTROUTING rules only get created for **VPN Server to VPN Client** and **VPN Server to IPSET List** rules.

````
  iptables -nvL POSTROUTING -t nat --line
  iptables -nvL PREROUTING -t mangle --line
````
5. Run the **ip rule** command to validate RPDB rules.
