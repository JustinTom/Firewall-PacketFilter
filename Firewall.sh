#!/bin/bash

###### Start User Configurable Section ######

#Default allow FTP data, FTP control, SSH, DNS, HTTP, HTTPS ports respectively with TCP protocol
TCPArray=( 20 21 22 )
#Default allow DNS, DHCP (2) ports respectively with UDP protocol.
UDPArray=( )
#Default allow regular echo-reply, port unreachable reply, and echo-request ports respectively used with ICMP.
ICMPArray=( 0 3 8 )

echo "What is the internal subnet of your network? (eg. 192.168.10.0/24)"
read internalSubnet

echo "What is the name of your internal network card? (eg. p3p1)"
read privNet

echo "What is the name of your external network card? (eg. em1)"
read pubNet

echo "What TCP service ports would you like to be allowed on the firewall?"
echo "Usage: 1,2,3"
echo "Recommended 53,80,443 for DNS, HTTP and HTTPS"
read TCPTemp

OIFS=$IFS
IFS=","
TCPArray2=($TCPTemp)
IFS=$OIFS
#Merge the two arrays - Assume there is no duplicates between the two arrays - no sorting.
TCPUserAllow=( "${TCPArray[@]}" "${TCPArray2[@]}" )

echo "What UDP service ports would you like to be allowed on the firewall?"
echo "Usage: 1,2,3"
echo "Recommended 53,67,68 for DNS and DHCP"
read UDPTemp

OIFS=$IFS
IFS=","
UDPArray2=($UDPTemp)
IFS=$OIFS
#Merge the two arrays - Assume there is no duplicates between the two arrays - no sorting.
UDPUserAllow=( "${UDPArray[@]}" "${UDPArray2[@]}" )

echo "What ICMP service ports would you like to be allowed on the firewall?"
echo "Usage: 1,2,3"
read ICMPTemp

OIFS=$IFS
IFS=","
ICMPArray2=($ICMPTemp)
IFS=$OIFS
#Merge the two arrays - Assume there is no duplicates between the two arrays - no sorting.
ICMPUserAllow=( "${ICMPArray[@]}" "${ICMPArray2[@]}" )
###### End User Configurable Section ######

###### Start Implementation Section ######
#Set the default policies of the firewall
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#user defined chains
iptables -N TCP_In
iptables -N TCP_Out
iptables -N UDP_In
iptables -N UDP_Out
iptables -N ICMP_In
iptables -N ICMP_Out

iptables -A TCP_In -j ACCEPT
iptables -A TCP_Out -j ACCEPT
iptables -A UDP_In -j ACCEPT
iptables -A UDP_Out -j ACCEPT
iptables -A ICMP_In -j ACCEPT
iptables -A ICMP_Out -j ACCEPT

#Allow DNS packets on the Firewall
#iptables -A INPUT -p tcp --sport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -p tcp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A INPUT -p udp --sport 53 -m state -j ACCEPT
#iptables -A OUTPUT -p udp --dport 53 -m state -j ACCEPT

#Allow DHCP packets on the Firewall
#iptables -A INPUT -p udp --dport 67:68 -m state -j ACCEPT
#iptables -A INPUT -p udp --sport 67:68 -m state -j ACCEPT
#iptables -A OUTPUT -p udp --sport 67:68 -m state -j ACCEPT
#iptables -A OUTPUT -p udp --dport 67:68 -m state -j ACCEPT

#Drop all packets destined for the firewall host from the outside
iptables -A INPUT -i $pubNet -j DROP

#Drop packets with source address matching our internal network
iptables -A FORWARD -i $pubNet -s $internalSubnet -j DROP

#Drop all TCP packets with the SYN and FIN bit set.
iptables -A FORWARD -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP -m comment --comment "Drop all TCP Pakets with both SYN and FIN flags set"

#Do not allow Telnet packets at all
iptables -A FORWARD -p tcp --dport 23 -j DROP -m comment --comment "Drop all incoming telnet packets"
iptables -A FORWARD -p tcp --sport 23 -j DROP -m comment --comment "Drop all outgoing telnet packets"

#Block all external traffic directed to ports 32768-32775, 137-139, TCP ports 111 and 515
iptables -A FORWARD -i $pubNet -o $privNet -p tcp --dport 32768:32775 -j DROP
iptables -A FORWARD -i $pubNet -o $privNet -p tcp --dport 137:139 -j DROP
iptables -A FORWARD -i $pubNet -o $privNet -p udp --dport 32768:32775 -j DROP
iptables -A FORWARD -i $pubNet -o $privNet -p udp --dport 137:139 -j DROP
iptables -A FORWARD -i $pubNet -o $privNet -p tcp --dport 111 -j DROP
iptables -A FORWARD -i $pubNet -o $privNet -p tcp --dport 515 -j DROP

#Reject those connections that are coming the "wrong" way (incomming SYN to high ports)
iptables -A FORWARD -i $pubNet -o $privNet -p tcp --tcp-flags ALL SYN ! --dport 0:1023 -j DROP -m comment --comment "Drop all high port connections that are coming the wrong way"
#iptables -A FORWARD -i $pubNet -o $privNet -p tcp --dport 0:1023 -j DROP
#iptables -A FORWARD -i $pubNet -o $privNet -p udp --dport 0:1023 -j DROP

#Accept Fragments
iptables -A FORWARD -f -j ACCEPT -m comment --comment "Accept fragment packets"

#FTP and SSH services with "Minimum Delay"
#FTP Data
iptables -A PREROUTING -t mangle -p tcp --dport 20 -j TOS --set-tos Minimize-Delay
iptables -A PREROUTING -t mangle -p tcp --sport 20 -j TOS --set-tos Minimize-Delay
#FTP Control
iptables -A PREROUTING -t mangle -p tcp --dport 21 -j TOS --set-tos Minimize-Delay
iptables -A PREROUTING -t mangle -p tcp --sport 21 -j TOS --set-tos Minimize-Delay
#SSH
iptables -A PREROUTING -t mangle -p tcp --dport 22 -j TOS --set-tos Minimize-Delay
iptables -A PREROUTING -t mangle -p tcp --sport 22 -j TOS --set-tos Minimize-Delay

#FTP data to "Maximum Throughput"
iptables -A PREROUTING -t mangle -p tcp --dport 20 -j TOS --set-tos Maximize-Throughput
iptables -A PREROUTING -t mangle -p tcp --sport 20 -j TOS --set-tos Maximize-Throughput

#User Configuration TCP Rules
for i in "${TCPUserAllow[@]}"
do
	iptables -A FORWARD -i $privNet -o $pubNet -p tcp --dport $i -m state --state NEW,ESTABLISHED -j TCP_In
	iptables -A FORWARD -i $pubNet -o $privNet -p tcp --sport $i -m state --state NEW,ESTABLISHED -j TCP_Out
	iptables -A FORWARD -i $privNet -o $pubNet -p tcp --sport $i -m state --state NEW,ESTABLISHED -j TCP_In
	iptables -A FORWARD -i $pubNet -o $privNet -p tcp --dport $i -m state --state NEW,ESTABLISHED -j TCP_Out
done

#User Configuration UDP Rules
for j in "${UDPUserAllow[@]}"
do
	iptables -A FORWARD -i $privNet -o $pubNet -p udp --dport $j -j UDP_In
	iptables -A FORWARD -i $pubNet -o $privNet -p udp --sport $j -j UDP_Out
	iptables -A FORWARD -i $privNet -o $pubNet -p udp --sport $j -j UDP_In
	iptables -A FORWARD -i $pubNet -o $privNet -p udp --dport $j -j UDP_Out
done

#User Configuration ICMP Rules
for k in "${ICMPUserAllow[@]}"
do
	iptables -A FORWARD -i $privNet -o $pubNet -p icmp --icmp-type $k -j ICMP_In
	iptables -A FORWARD -i $pubNet -o $privNet -p icmp --icmp-type $k -j ICMP_Out
done

service iptables save
service iptables restart
iptables -L -x -n -v
##### End Implementation Section #####
