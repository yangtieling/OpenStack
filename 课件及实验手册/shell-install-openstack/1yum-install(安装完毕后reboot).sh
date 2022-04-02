#!/bin/bash

setenforce 0
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/sysconfig/selinux
grep SELINUX=disabled /etc/sysconfig/selinux

systemctl stop firewalld.service
systemctl disable firewalld.service
systemctl status firewalld.service

dd if=/dev/zero of=/home/swapfile bs=1M count=4096
/usr/sbin/mkswap /home/swapfile
/usr/sbin/swapon /home/swapfile

hostnamectl set-hostname controller
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 4.4.4.4" >> /etc/resolv.conf



yum install wget -y
yum install etcd -y
yum install chrony -y
yum install centos-release-openstack-rocky -y
yum install python-openstackclient openstack-selinux -y
yum install mariadb mariadb-server MySQL-python python2-PyMySQL -y
yum install rabbitmq-server -y
yum install memcached python-memcached -y

yum install centos-release-openstack-rocky -y
yum install openstack-keystone python-keystoneclient openstack-utils -y
yum install python-openstackclient -y

yum install openstack-keystone httpd mod_wsgi -y

yum install openstack-glance python-glance python-glanceclient -y

yum install openstack-nova-api openstack-nova-conductor \
  openstack-nova-console openstack-nova-novncproxy \
  openstack-nova-scheduler openstack-nova-placement-api -y

yum install python-openstackclient openstack-selinux -y
yum install openstack-nova-compute python-openstackclient openstack-utils -y


yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables -y
yum install openstack-neutron-linuxbridge ebtables ipset -y

