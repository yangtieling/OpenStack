#!/bin/bash

##### 用户配置区 开始 ######################
# 将此脚本放在/root目录;
#
##### 用户配置区 结束  #####################


#--------------------------------------------
# 安装OpenStack基本环境
#--------------------------------------------
hostipaddress=127.0.0.1

#) 设定主机名字
hostnamectl set-hostname controller

rm -rf /etc/hosts

cat >> /etc/hosts <<EOF
#127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
#::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
$hostipaddress controller
EOF

echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 4.4.4.4" >> /etc/resolv.conf


#--------------------------------------------
# 安装OpenStack基本环境
# 禁用防火墙；关闭Selinux
#--------------------------------------------
systemctl stop firewalld.service
systemctl disable firewalld.service
systemctl status firewalld.service
setenforce 0
getenforce

sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/sysconfig/selinux
grep SELINUX=disabled /etc/sysconfig/selinux


#--------------------------------------------
# 安装OpenStack基本环境
# 启用时间同步
#--------------------------------------------
yum install chrony -y
systemctl restart chronyd.service
systemctl status chronyd.service
systemctl enable chronyd.service


#--------------------------------------------
# 安装OpenStack基本环境
# 安装openstack source
# install openstack client
#--------------------------------------------
yum install centos-release-openstack-rocky -y
yum install python-openstackclient openstack-selinux -y

ulimit -SHn 65536

#--------------------------------------------
# 安装OpenStack基本环境
#--------------------------------------------
yum install mariadb mariadb-server MySQL-python python2-PyMySQL -y

systemctl start mariadb.service
systemctl status mariadb.service 
systemctl enable mariadb.service 
mysqladmin -u root password 123456
/usr/bin/mysql_secure_installation                                                                 
#mysql -uroot -p123456 -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '123456' WITH GRANT OPTION;"
#mysql -uroot -p123456 -e "FLUSH PRIVILEGES;"


#--------------------------------------------
# 安装OpenStack基本环境
#--------------------------------------------
yum install rabbitmq-server -y

systemctl restart  rabbitmq-server.service
systemctl status rabbitmq-server.service

systemctl enable rabbitmq-server.service

rabbitmqctl add_user openstack openstack
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

#--------------------------------------------
# 安装OpenStack基本环境
#--------------------------------------------
yum install memcached python-memcached -y

systemctl start memcached.service
systemctl status memcached.service
netstat -anptl | grep memcached
systemctl enable memcached.service

#--------------------------------------------
# 安装OpenStack基本环境
#--------------------------------------------
yum install etcd -y
#-----------the end--------------------------

dd if=/dev/zero of=/home/swapfile bs=1M count=4096
/usr/sbin/mkswap /home/swapfile
/usr/sbin/swapon /home/swapfile
