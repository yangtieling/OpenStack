#!/bin/bash

hostipaddress=192.168.137.16
hostipaddress=172.104.203.245
hostipaddress=127.0.0.1

# 1) create db
#------------------------------------------------------------
mysql -uroot -p123456 -e "drop DATABASE keystone;"
mysql -uroot -p123456 -e "CREATE DATABASE keystone;"

mysql -uroot -p123456 -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'keystone';"
mysql -uroot -p123456 -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'keystone'; "
mysql -uroot -p123456 -e "flush privileges; "
mysql -uroot -p123456 -e "show databases; "
#------------------------------------------------------------

# 2) install software
#------------------------------------------------------------
yum install centos-release-openstack-rocky -y
yum install openstack-keystone python-keystoneclient openstack-utils -y
#yum install python-openstackclient openstack-selinux -y
yum install python-openstackclient -y
yum install openstack-keystone httpd mod_wsgi -y
#------------------------------------------------------------

dd if=/dev/zero of=/home/swapfile bs=1M count=4096
mkswap /home/swapfile
whereis mkswap
/usr/sbin/mkswap /home/swapfile
whereis swapon
/usr/sbin/swapon /home/swapfile


# 3) config keystone
#------------------------------------------------------------
openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:keystone@controller/keystone
openstack-config --set /etc/keystone/keystone.conf token provider fernet
#------------------------------------------------------------

# 4) syn keystone db
#------------------------------------------------------------
su -s /bin/sh -c "keystone-manage db_sync" keystone
mysql -ukeystone -pkeystone -e "use keystone;show tables;"
#------------------------------------------------------------

# 5) setup fernet
#------------------------------------------------------------
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
#------------------------------------------------------------

sed  -i  "s/#ServerName www.example.com:80/ServerName $hostipaddress/" /etc/httpd/conf/httpd.conf

ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

systemctl restart httpd.service memcached.service
systemctl status httpd.service
netstat -anptl|grep httpd

systemctl enable httpd.service
systemctl list-unit-files |grep httpd.service
#------------------------------------------------------------
keystone-manage bootstrap --bootstrap-password 123456 \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne
#------------------------------------------------------------

#------------------------------------------------------------
cat > admin-openrc << EOF
export OS_USERNAME=admin
export OS_PASSWORD=123456
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
#------------------------------------------------------------

source admin-openrc

openstack endpoint list
openstack project list
openstack user list
#------------------------------------------------------------

openstack domain create --description "An Example Domain" example
openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" myproject

openstack user create --domain default  --password=myuser myuser
openstack role create myrole
openstack role add --project myproject --user myuser myrole
#------------------------------------------------------------

openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name admin --os-username admin token issue
