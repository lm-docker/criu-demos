#!/bin/bash

# Simulate a setting with two different network namespces (same IP) connected to a bridge
# refs: 
#   - https://ops.tips/blog/using-network-namespaces-and-bridge-to-isolate-servers/
#   - Sauvanaud et. al. "Interconnecting Netowrk Namespaces"

# IP handles live at /var/run/netns
ip netns add namespace1
ip netns add namespace2

# Bring up localhost interfaces
ip netns exec namespace1 ip link set dev lo up
ip netns exec namespace2 ip link set dev lo up

# Create the two virtual ethernet pairs
# br stands for the peer that will be on the bridge side
ip link add veth1 type veth peer name br-veth1
ip link add veth2 type veth peer name br-veth2

# Assosciate the non bridge side with the ns
ip link set veth1 netns namespace1
ip link set veth2 netns namespace2

# Assign IPs to each one
ip netns exec namespace1 ip addr add 192.168.1.11/24 dev veth1
ip netns exec namespace2 ip addr add 192.168.1.12/24 dev veth2

# Setup the bridge to connect to the overlay network
ip link add name br1 type bridge

# Add IP for the bridge
# The '+' sets the host bits to 255 for the broadcast
ip addr add 192.168.1.10/24 brd + dev br1
ip link set br1 up

# Now bring up all the interfaces
ip netns exec namespace1 ip link set veth1 up
ip netns exec namespace2 ip link set veth2 up

# Add bridge veth interfaces to the bridge and bring them up
ip link set br-veth1 master br1
ip link set br-veth2 master br1
ip link set br-veth1 up
ip link set br-veth2 up

# Add gateway route for the namespaces
ip netns exec namespace1 ip route add default via 192.168.1.10 
ip netns exec namespace2 ip route add default via 192.168.1.10

# Add route in host's ip table to forward responses to any namespace's ip
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -j MASQUERADE
