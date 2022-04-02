#!/bin/bash

hostipaddress=192.168.137.16
hostipaddress=172.104.203.245
hostipaddress=192.168.0.32
hostipaddress=127.0.0.1

mysql -uroot -p123456 -e "drop DATABASE glance;"
mysql -uroot -p123456 -e "CREATE DATABASE glance;"
mysql -uroot -p123456 -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'glance';"
mysql -uroot -p123456 -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'glance';"
mysql -uroot -p123456 -e "flush privileges;"

source admin-openrc
openstack user create --domain default --password=glance glance
openstack user list
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
openstack service list

openstack endpoint create --region RegionOne image public http://$hostipaddress:9292
openstack endpoint create --region RegionOne image internal http://$hostipaddress:9292
openstack endpoint create --region RegionOne image admin http://$hostipaddress:9292
openstack endpoint list

yum install openstack-glance python-glance python-glanceclient -y

openstack-config --set  /etc/glance/glance-api.conf database connection  mysql+pymysql://glance:glance@controller/glance
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken www_authenticate_uri http://controller:5000
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken auth_url http://controller:5000
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken memcached_servers  controller:11211
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken auth_type password
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken project_domain_name Default
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken user_domain_name Default
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken project_name service 
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken username glance
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken password glance
openstack-config --set  /etc/glance/glance-api.conf paste_deploy flavor keystone
openstack-config --set  /etc/glance/glance-api.conf glance_store stores  file,http
openstack-config --set  /etc/glance/glance-api.conf glance_store default_store file
openstack-config --set  /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

openstack-config --set  /etc/glance/glance-registry.conf database connection mysql+pymysql://glance:glance@controller/glance
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken www_authenticate_uri http://controller:5000
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken auth_url http://controller:5000
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken auth_type password
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken project_domain_name Default
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken user_domain_name Default
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken project_name service
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken username glance
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken password glance
openstack-config --set  /etc/glance/glance-registry.conf paste_deploy flavor keystone

su -s /bin/sh -c "glance-manage db_sync" glance

mysql -h$hostipaddress -uglance -pglance -e "use glance;show tables;"

systemctl restart memcached

systemctl restart openstack-glance-api.service openstack-glance-registry.service
systemctl status openstack-glance-api.service openstack-glance-registry.service

systemctl enable openstack-glance-api.service openstack-glance-registry.service
systemctl list-unit-files |grep openstack-glance*

yum install wget -y
wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

source admin-openrc
openstack image create "cirros" --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public
openstack image list
