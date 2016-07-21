# dhcpconfman
## Requirements:
 * Ubuntu: libregexp-common-net-cidr-perl
 * CentOS: epel-release, perl-Regexp-Common
 ** ---> Or if you don't like EPEL - just CPAN it
 NOTE: The dhcpd restart at the end uses systemctl. If your system doesn't
 have systemctl, you'll obviously have to use /etc/init.d/dhcpd or something
 similar. systemctl works on CentOS 7, and newer versions of Ubuntu.

## Description:
This perl script takes 3 arguments: MAC-ADDRESS IP-ADDRESS USER-NAME
It then generates a host entry for dhcpd static reservations.
Of course you could manually add these, but this script is designed to prevent
fat fingering / breaking the config. 

It verifies that: 
* MAC-ADDRESS is a valid MAC
* IP-ADDRESS is a valid IP
* None of the 3 arguments already exist in the config

It also allows dynamic DNS domain assignment in the config, based off of a hash
mapping Classful Subnets to DNS domains. Note this is currently just configured for class B mapping. 


## Setup
You will need to add a file: dhcpconfman.cfg to the code directory like so:
------ BEGIN EXAMPLE
    $reservationsFile = "LOCATION OF THE RESERVATION FILE";
    %dnsDomainMappings = (
        "10.10." => "localdomain1.org",
        "10.11." => "localdomain2.org"
    );
------ END EXAMPLE
* Make sure that dhcpd can read the $reservationsFile
* Make sure the SELinux label is dhcp_etc_t for the file you create 
(if using SELinux).
* Reference the file in /etc/dhcp/dhcpd.conf with:
include "YOUR-FILE-LOCATION";


Just for reference, here is an example /etc/dhcp/dhcpd.conf file
------ BEGIN EXAMPLE
    include "/apps/dhcpd.reservations";

    log-facility local7;
    option domain-name-servers 192.168.1.1, 192.168.1.2;

    default-lease-time 1800;
    max-lease-time 7200;
    authoritative;
    subnet 192.168.1.0 netmask 255.255.255.0 {
      range dynamic-bootp 192.168.1.10 192.168.1.20;
      option routers 192.168.1.1;
    }
------ END EXAMPLE



### Ian Reynolds
### The MIS Department
