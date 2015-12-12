# Standalone Firewall and Packet Filter
A basic standalone Linux firewall and packet filter.

The bash script, when executed, will configure the host’s firewall settings through the use of the IPtables commands. 

The user will be able to specify:
- The internal (inbound) network address and NIC
- The external (outbound) network address and NIC 
- The TCP, UDP and ICMP services that will be allowed. 

It is a stateful filtering firewall, allowing NEW and ESTABLISHED traffic to go through the firewall. 

The commands will:
- Set all the default policies to "DROP"
- Allow inbound/outbound TCP, UDP and ICMP packets through the ports specified by the user
- Drops all packets destined for the firewall host from the outside 
- Drops any packets with a source address from the outside matching your internal network
- Drops all connections coming from high ports (higher than 1023)
- Accepts packet fragments
- Accepts TCP packets that belong to an existing connection (on allowed ports)
- Drops all TCP packets with both SYN and FIN bit set
- Drops all Telnet (port 23) packets
- Drops all external traffic directed to ports 32768-32775, 137-139, TCP ports 111 and 515
- Sets FTP and SSH services to “Minimum Delay” as well as FTP data to “Maximum throughput”
