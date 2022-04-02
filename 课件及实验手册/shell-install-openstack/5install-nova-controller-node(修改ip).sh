#!/bin/bash
cat > nova_sql.sql << EOF
drop DATABASE if exists nova_api;;
drop DATABASE if exists nova;
drop DATABASE if exists nova_cell0;
drop DATABASE if exists placement;

CREATE DATABASE nova_api;
CREATE DATABASE nova;
CREATE DATABASE nova_cell0;
CREATE DATABASE placement;

GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'nova';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'nova';

GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'nova';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'nova';

GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'nova';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'nova';

GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY 'placement';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY 'placement';

flush privileges;
show databases;
select user,host from mysql.user;
exit
EOF


mysql -uroot -p123456 < nova_sql.sql


source admin-openrc
openstack user create --domain default --password=nova nova
openstack user list

openstack role add --project service --user nova admin

openstack service create --name nova --description "OpenStack Compute" compute
openstack service list

openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1
openstack endpoint list


openstack user create --domain default --password=placement placement
openstack role add --project service --user placement admin
openstack service create --name placement --description "Placement API" placement


openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778
openstack endpoint list


yum install openstack-nova-api openstack-nova-conductor \
  openstack-nova-console openstack-nova-novncproxy \
  openstack-nova-scheduler openstack-nova-placement-api -y


openstack-config --set  /etc/nova/nova.conf DEFAULT enabled_apis  osapi_compute,metadata
openstack-config --set  /etc/nova/nova.conf DEFAULT my_ip   139.59.121.57
openstack-config --set  /etc/nova/nova.conf DEFAULT use_neutron  true 
openstack-config --set  /etc/nova/nova.conf DEFAULT firewall_driver  nova.virt.firewall.NoopFirewallDriver
openstack-config --set  /etc/nova/nova.conf DEFAULT transport_url  rabbit://openstack:openstack@controller
openstack-config --set  /etc/nova/nova.conf api_database connection  mysql+pymysql://nova:nova@controller/nova_api
openstack-config --set  /etc/nova/nova.conf database connection  mysql+pymysql://nova:nova@controller/nova
openstack-config --set  /etc/nova/nova.conf placement_database connection  mysql+pymysql://placement:placement@controller/placement
openstack-config --set  /etc/nova/nova.conf api auth_strategy  keystone 
openstack-config --set  /etc/nova/nova.conf keystone_authtoken auth_url  http://controller:5000/v3
openstack-config --set  /etc/nova/nova.conf keystone_authtoken memcached_servers  controller:11211
openstack-config --set  /etc/nova/nova.conf keystone_authtoken auth_type  password
openstack-config --set  /etc/nova/nova.conf keystone_authtoken project_domain_name  default 
openstack-config --set  /etc/nova/nova.conf keystone_authtoken user_domain_name  default
openstack-config --set  /etc/nova/nova.conf keystone_authtoken project_name  service 
openstack-config --set  /etc/nova/nova.conf keystone_authtoken username  nova 
openstack-config --set  /etc/nova/nova.conf keystone_authtoken password  nova
openstack-config --set  /etc/nova/nova.conf vnc enabled true
openstack-config --set  /etc/nova/nova.conf vnc server_listen '$my_ip'
openstack-config --set  /etc/nova/nova.conf vnc server_proxyclient_address '$my_ip'
openstack-config --set  /etc/nova/nova.conf glance api_servers  http://controller:9292
openstack-config --set  /etc/nova/nova.conf oslo_concurrency lock_path  /var/lib/nova/tmp 
openstack-config --set  /etc/nova/nova.conf placement region_name RegionOne
openstack-config --set  /etc/nova/nova.conf placement project_domain_name Default
openstack-config --set  /etc/nova/nova.conf placement project_name service
openstack-config --set  /etc/nova/nova.conf placement auth_type password
openstack-config --set  /etc/nova/nova.conf placement user_domain_name Default
openstack-config --set  /etc/nova/nova.conf placement auth_url http://controller:5000/v3
openstack-config --set  /etc/nova/nova.conf placement username placement
openstack-config --set  /etc/nova/nova.conf placement password placement
openstack-config --set  /etc/nova/nova.conf scheduler discover_hosts_in_cells_interval 300

cat > nova-placement-api.txt << EOF



<Directory /usr/bin>
   <IfVersion >= 2.4>
      Require all granted
   </IfVersion>
   <IfVersion < 2.4>
      Order allow,deny
      Allow from all
   </IfVersion>
</Directory>
EOF

cat nova-placement-api.txt >> /etc/httpd/conf.d/00-nova-placement-api.conf

systemctl restart httpd
systemctl status httpd 

su -s /bin/sh -c "nova-manage api_db sync" nova

mysql -h127.0.0.1 -unova -pnova -e "use nova_api;show tables;"
mysql -h127.0.0.1 -uplacement -pplacement -e "use placement;show tables;"


su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova

su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova

su -s /bin/sh -c "nova-manage db sync" nova

su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova

mysql -h127.0.0.1 -unova -pnova -e "use nova_cell0;show tables;"
mysql -h127.0.0.1 -unova -pnova -e "use nova;show tables;"

systemctl restart openstack-nova-api.service openstack-nova-consoleauth.service \
  openstack-nova-scheduler.service openstack-nova-conductor.service \
  openstack-nova-novncproxy.service

systemctl status openstack-nova-api.service openstack-nova-consoleauth.service \
  openstack-nova-scheduler.service openstack-nova-conductor.service \
  openstack-nova-novncproxy.service

systemctl enable openstack-nova-api.service openstack-nova-consoleauth.service \
  openstack-nova-scheduler.service openstack-nova-conductor.service \
  openstack-nova-novncproxy.service

systemctl list-unit-files |grep openstack-nova* |grep enabled


