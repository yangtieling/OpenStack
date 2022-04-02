#!/bin/bash

source admin-openrc 


openstack network create --share --external --disable-port-security --provider-physical-network public --provider-network-type flat public 
openstack subnet create --network public --dhcp --allocation-pool start=10.124.0.20,end=10.124.0.200 --dns-nameserver 8.8.8.8 --gateway=10.124.0.2 --subnet-range 10.124.0.0/24  public-subnet01

openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano

openstack network list
openstack server create --flavor m1.nano --image cirros --nic net-id=f00df293-0f41-4ef2-903e-bbc435f40963 vm-name1

openstack server list

echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE



