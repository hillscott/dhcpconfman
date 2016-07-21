#!/usr/bin/perl
# dhcpconfman.pl
# Ian Reynolds - MIS
# Generates DHCPd host configuration files, for inclusion into dhcpd
# Relies on the configured reservations file being used by 
# /etc/dhcp/dhcpd.conf via an include statement
# Usage: ./dhcpconfman.pl MAC-ADDRESS IP USER-NAME
use strict;
require "dhcpconfman.cfg";
use Regexp::Common qw /net/;
our ($reservationsFile, %dnsDomainMappings);


# The user did something wrong...
sub printUsage{
    print "Usage: dhcpconfman.pl MAC-ADDRESS IP-ADDRESS USER-NAME\n";
    print "Where MAC-ADDRESS is in the XX:XX:XX:XX:XX:XX format\n";
    print "and IP-ADDRESS is in the 1.2.3.4 format\n";
    print "and USER-NAME is the username\n";
    print "This program will add a DHCP Reservation to $reservationsFile"."\n";
    exit;
}

# Verify the correct arguments were passed and that the host file is present
sub usageCheck{
    if ($#ARGV != 2){
        &printUsage;
    }
    my $macAddy = $ARGV[0];
    if ($macAddy =~ /^([0-9A-F]{2}:){5}[0-9A-F]{2}$/i){
    #if ($macAddy =~ /^$RE{net}{MAC}$/){
        print "MAC Address passes!\n";
    }
    else{
        die "FAIL - be sure that you follow the MAC-ADDRESS syntax!";
    }
    my $ipAddy = $ARGV[1];
    if ($ipAddy =~/^$RE{net}{IPv4}$/){
        print "IP-Address passes!\n";
    }
    else{
        print "FAIL - be sure that you've entered a valid IP-Address!\n";
        die "No changes made... dying.";
    }
    my $username = $ARGV[2];
    return ($ipAddy, $macAddy, $username);
}

# Verify that the IP or MAC isn't already in use
sub inUseCheck{
    my $ipAddy = shift;
    my $macAddy = shift;
    my $username = shift;
    # Open the reservation file and verify that the ip and mac don't appear
    open(my $fileHandle, '<:encoding(UTF-8)', $reservationsFile)
        or die "$reservationsFile wasn't available for opening!";
    while (my $row = <$fileHandle>){
        chomp $row;
        if ($row =~ /$macAddy/){
            die "MAC-Address already exists in the reservation file!";
        }
        elsif ($row =~ /$ipAddy/){
            die "IP-Address already exists in the reservation file!";
        }
        elsif ($row =~ /$username/){
            die "User already has a host entry in the reservation file!";
        }
    }
    print "Passed MAC-Address and IP-Address existence checks...\n";
}

# Generate the DNS domain based on the subnet
sub dnsDomainSet{
    my $ipAddy = shift;
    my $macAddy = shift;
    if ($ipAddy =~ /$RE{net}{IPv4}{-keep}/){
        my $twoOctets = $2.".".$3.".";
#        print $twoOctets."\n";
        my $dnsDomain = $dnsDomainMappings{$twoOctets};
        if (defined($dnsDomain)){
            print "Found DNS Domain of ".$dnsDomain."\n";
            return($dnsDomain); 
        }
        else{
            print "You've entered an IP Address for a range that I don't know about...\n";
            die "You'll need to add it to the hash mapping or correct your typo";
        }
    }
}

# Create the config statements and save to a buffer for writing out
sub generateStatements{
    my $username = shift;
    my $ipAddy = shift;
    my $macAddy = shift;
    my $dnsDomain = shift;
    open(my $fileHandle, ">>", $reservationsFile) or 
      die "Couldn't open reservations file for writing!";
    print $fileHandle "###\n";
    print $fileHandle "host $username"." {"."\n";
    print $fileHandle "  hardware ethernet $macAddy".";"."\n";
    print $fileHandle "  fixed-address $ipAddy".";"."\n";
    print $fileHandle "  option domain-name \"$dnsDomain\"".";"."\n";
    print $fileHandle "}"."\n";
    print $fileHandle "### Added ".localtime()." \n";
    close $fileHandle;
    print $reservationsFile." Updated!\n";
   
}
### MAIN
# Run the subs
my ($ipAddy, $macAddy, $username) = &usageCheck;
&inUseCheck($ipAddy, $macAddy, $username);
my $dnsDomain = &dnsDomainSet($ipAddy, $macAddy);
# Write out the config changes
&generateStatements($username, $ipAddy, $macAddy, $dnsDomain);
# Reload DHCPd
print "Reloading DHCPd - if this fails, you'll have to do it manually.\n";
system("sudo systemctl restart dhcpd");
