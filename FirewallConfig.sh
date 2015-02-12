#!/bin/sh

echo "What is the internal(subnet) IP address of your internal firewall? (eg. 192.168.10.1)"
read internalFirewallIP

echo "What is the internal(subnet) IP address of your internal host? (eg. 192.168.10.2)"
read internalHostIP

echo "What is the name of your internal network card? (eg. p3p1)"
read privNet

echo "What is the external IP address of your firewall host? (eg. 192.168.0.XX)"
read externalFirewallIP

echo "What is the name of your external network card? (eg. em1)"
read pubNet

echo "What is the subnet of your internal network? (eg. 192.168.10.0/24)"
read subnet

#Removes the last digits before the decimal and adds a 0 for the subnet
externalSubnet="${externalFirewallIP%.*}"
externalSubnet+=".0"
#Removes the last digits before the decimal and adds a 0 for the subnet
internalSubnet="${internalFirewallIP%.*}"
internalSubnet+=".0"

#Start up a new network by giving the firewall host an IP address such as 192.168.10.1 on the second network interface
ifconfig $privNet $internalFirewallIP up
#Enable IP Forwarding On
echo "1" >/proc/sys/net/ipv4/ip_forward
#New routing rules for the current network:
route add -net $internalSubnet netmask 255.255.255.0 gw $externalFirewallIP
#Configure a new routing rule for the new internal network by making everything in the subnet use the firewall host
route add -net $externalSubnet/24 gw $internalFirewallIP

#Allows any outbound connections to work from the internal network
#Mask all outgoing as the firewall's external IP
iptables -t nat -A POSTROUTING -s $subnet -o em1 -j SNAT --to-source $externalFirewallIP

#Direct all incoming packets to internal host
iptables -t nat -A PREROUTING -i em1 -j DNAT --to-destination $internalHostIP

echo "Firewall host configuration complete!"