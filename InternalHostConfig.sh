#!/bin/bash

echo "What is the internal(subnet) IP address of your internal host? (eg. 192.168.10.2)"
read internalHostIP

echo "What is the internal(subnet) IP address of your internal firewall? (eg. 192.168.10.1)"
read internalFirewallIP

echo "What is the name of your internal network card? (eg. p3p1)"
read privNet

echo "What is the name of your external network card? (eg. em1)"
read pubNet

#Disable the NIC that is connected to the Internet
ifconfig $pubNet down
#Enable the second NIC that is connected to the firewall host and assign an IP address on that subnet
ifconfig $privNet $internalHostIP up
#Add a routing rule to route the firewall host as the default gateway for the internal network.
route add default gw $internalFirewallIP

ifconfig

echo "Internal host configuration complete!"
