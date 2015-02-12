#!/bin/bash
echo "----------Setting up Testing Parameters----------"

echo "What is the external IP adress of your firewall host? (eg. 192.168.0.23)"
read firewallIP

echo "What is the IP adress of your target internal host? (eg. 192.168.10.2)"
read hostIP

echo "What is the subnet of your internal network? (eg. 192.168.10.0/24)"
read subnet

#Lets the test machine know where to reach the target host through the firewall being the new gateway
#echo "Adding routing rule to allow this machine to properly send packets to target host"
#route add -net $subnet gw $firewallIP

echo "----------End of Setting up Testing Parameters----------"

#List the original Iptables rules
echo "Listing pre-existing IP tables rules"
iptables -L -v -n -x

echo "----------Testing Begins----------" | tee -a $filename
echo "All tests send 5 packets each and keep on the specified port." | tee -a $filename

#All packets are dropped destined for the firewall except DNS (53) and DHCP (67,68)
echo "Test 1 - Drop all packets destined for the firewall host from the outside" | tee -a $filename
echo "Test 1 expected result - All packets are dropped." | tee -a $filename
hping3 $firewallIP -V -S -c 5 -p 80 --fast | tee -a $filename
echo -e "Test 1 complete\n" | tee -a $filename

echo "Test 2 - Do not accept any packets with a source address from the outside matching your internal network" | tee -a $filename
echo "Test 2 expected result - All packets are dropped." | tee -a $filename
#Removes the last digits before the decimal and adds a 88 for the simulated internal host
simHost="${subnet%.*}" | tee -a $filename
simHost+=".88" | tee -a $filename
hping3 $hostIP -V -S -c 5 -k -a $simHost -p 80 --fast | tee -a $filename
echo -e "Test 2 complete\n" | tee -a $filename

echo "Test 3 - Reject those connections that are coming the 'wrong' way (incomming SYN to high ports)" | tee -a $filename
echo -e "\tTesting TCP on port 5050..." | tee -a $filename
echo -e "\tExpected result - All packets dropped." | tee -a $filename
hping3 $hostIP -V -S -c 5 -k -p 5050 --fast | tee -a $filename
echo -e "\tTesting TCP on port 2020..." | tee -a $filename
echo -e "\tExpected result - All packets dropped." | tee -a $filename
hping3 $hostIP -V -S -c 5 -k -p 2020 --fast | tee -a $filename
echo -e "Test 3 complete\n" | tee -a $filename

##NOT SURE HOW TO TEST - MAKE SURE THIS IS THE CORRECT WAY##
echo "Test 4 - Accept fragments" | tee -a $filename
echo "Test 4 expected result - All packets accepted" | tee -a $filename
hping3 $hostIP -V -c 5 -k -p 80 --data 2048 | tee -a $filename
echo -e "Test 4 complete\n" | tee -a $filename

echo "Test 5 - Drop all TCP packets with the SYN and FIN bit set" | tee -a $filename
hping3 $hostIP -V -SF -k -c 5 -p 80 --fast | tee -a $filename
hping3 $hostIP -V -SF -k -c 5 -p 22 --fast | tee -a $filename
echo -e "Test 5 complete\n" | tee -a $filename

echo "Test 6 - Do not allow Telnet packets at all" | tee -a $filename
echo "Test 6 expected result - All packets dropped" | tee -a $filename
hping3 $hostIP -V -S -k -c 5 -p 23 -s 23 --fast | tee -a $filename
echo -e "Test 6 complete\n" | tee -a $filename

echo "Test 7 - Block all external traffic directed to ports 32768-32775" | tee -a $filename
echo -e "\tTesting TCP on port 32769..." | tee -a $filename
echo -e "\tExpected result - All packets dropped." | tee -a $filename
hping3 $hostIP -V -S -k -c 5 -p 32769 --fast | tee -a $filename
echo -e "\tTesting UDP on port 32769..." | tee -a $filename
echo -e "\tExpected result - All packets dropped." | tee -a $filename
hping3 $hostIP -V -k -c 5 -p 32769 --udp --fast | tee -a $filename
echo -e "\tTesting TCP on port 32770..." | tee -a $filename
echo -e "\tExpected result - All packets dropped." | tee -a $filename
hping3 $hostIP -V -S -k -c 5 -p 32770 --fast | tee -a $filename
echo -e "\tTesting UDP on port 32771..." | tee -a $filename
echo -e "\tExpected result - All packets dropped." | tee -a $filename
hping3 $hostIP -V -k -c 5 -p 32771 --udp --fast | tee -a $filename
echo -e "Test 7 complete\n" | tee -a $filename

echo "Test 8 - Block all external traffic directed to ports 137-139" | tee -a $filename
echo -e "\tTesting TCP on port 137..." | tee -a $filename
echo -e "\tExpected result - All packets dropped." | tee -a $filename
hping3 $hostIP -V -S -k -c 5 -p 137 --fast | tee -a $filename
echo -e "\tTesting UDP on port 137..." | tee -a $filename
echo -e "\tExpected result - All packets dropped." | tee -a $filename
hping3 $hostIP -V -k -c 5 -p 137 --udp --fast | tee -a $filename
echo -e "\tTesting TCP on port 138..." | tee -a $filename
echo -e "\tExpected result - All packets dropped." | tee -a $filename
hping3 $hostIP -V -S -k -c 5 -p 138 --fast | tee -a $filename
echo -e "\tTesting UDP on port 138..." | tee -a $filename
echo -e "\tExpected result - All packets dropped." | tee -a $filename
hping3 $hostIP -V -k -c 5 -p 138 --udp --fast | tee -a $filename
echo -e "Test 8 complete\n" | tee -a $filename

echo "Test 9 - Block all external traffic directed to TCP on port 111" | tee -a $filename
hping3 $hostIP -V -S -k -c 5 -p 111 --fast | tee -a $filename
echo -e "Test 9 complete\n" | tee -a $filename

echo "Test 10 - Block all external traffic directed to TCP on port 515" | tee -a $filename
hping3 $hostIP -V -S -k -c 5 -p 515 --fast | tee -a $filename
echo -e "Test 10 complete\n" | tee -a $filename

echo "Test 11 - Testing random ports using either TCP or UDP" | tee -a $filename
echo -e "\tTesting TCP on port 22" | tee -a $filename
echo -e "\tExpected result - All packets allowed." | tee -a $filename
hping3 $hostIP -V -S -k -c 5 -p 22 --fast | tee -a $filename
echo -e "\tTesting UDP on port 1020" | tee -a $filename
echo -e "\tExpected result - All packets dropped unless user has specified port 1020 to be allowed on UDP." | tee -a $filename
hping3 $hostIP -V -k -c 5 -p 1020 --udp --fast | tee -a $filename
echo -e "\tTesting UDP on port 88" | tee -a $filename
echo -e "\tExpected result - All packets dropped unless user has specified port 88 to be allowed on UDP." | tee -a $filename
hping3 $hostIP -V -k -c 5 -p 88 --udp --fast | tee -a $filename
echo -e "\tTesting TCP on port 1234" | tee -a $filename
echo -e "\tExpected result - All packets dropped unless user has specified port 1234 to be allowed on TCP." | tee -a $filename
hping3 $hostIP -V -S -k -c 5 -p 1234 --fast | tee -a $filename
echo -e "\tTesting TCP on port 443" | tee -a $filename
echo -e "\tExpected result - All packets allowed." | tee -a $filename
hping3 $hostIP -V -S -k -c 5 -p 443 --fast | tee -a $filename
echo -e "Test 11 complete\n" | tee -a $filename

echo "----------End of Testing----------" | tee -a $filename