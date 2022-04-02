#!/bin/bash

mysql -uroot -p123456 -e "drop DATABASE neutron;"
mysql -uroot -p123456 -e "CREATE DATABASE neutron;"
mysql -uroot -p123456 -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'neutron';"
mysql -uroot -p123456 -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'neutron';"
mysql -uroot -p123456 -e "flush privileges;"

source admin-openrc
openstack user create --domain default --password=neutron neutron
openstack user list

openstack role add --project service --user neutron admin

openstack service create --name neutron --description "OpenStack Networking" network
openstack service list

openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696
openstack endpoint list

yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables -y

openstack-config --set  /etc/neutron/neutron.conf database connection  mysql+pymysql://neutron:neutron@controller/neutron 
openstack-config --set  /etc/neutron/neutron.conf DEFAULT core_plugin  ml2  
openstack-config --set  /etc/neutron/neutron.conf DEFAULT service_plugins 
openstack-config --set  /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:openstack@controller
openstack-config --set  /etc/neutron/neutron.conf DEFAULT auth_strategy  keystone  
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri  http://controller:5000
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken auth_url  http://controller:5000
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken memcached_servers  controller:11211
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken auth_type  password  
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken project_domain_name default  
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken user_domain_name  default  
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken project_name  service  
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken username  neutron  
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken password  neutron  
openstack-config --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes  True  
openstack-config --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes  True  
openstack-config --set  /etc/neutron/neutron.conf nova auth_url  http://controller:5000
openstack-config --set  /etc/neutron/neutron.conf nova auth_type  password 
openstack-config --set  /etc/neutron/neutron.conf nova project_domain_name  default  
openstack-config --set  /etc/neutron/neutron.conf nova user_domain_name  default  
openstack-config --set  /etc/neutron/neutron.conf nova region_name  RegionOne  
openstack-config --set  /etc/neutron/neutron.conf nova project_name  service  
openstack-config --set  /etc/neutron/neutron.conf nova username  nova  
openstack-config --set  /etc/neutron/neutron.conf nova password  nova  
openstack-config --set  /etc/neutron/neutron.conf oslo_concurrency lock_path  /var/lib/neutron/tmp  

openstack-config --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers  flat,vlan
openstack-config --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types 
openstack-config --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers  linuxbridge
openstack-config --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers  port_security
openstack-config --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks public
openstack-config --set  /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset  True 

openstack-config --set   /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings  public:eth0
openstack-config --set   /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan  enable_vxlan  False
openstack-config --set   /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup  enable_security_group  False
openstack-config --set   /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup  firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

#sysctl net.bridge.bridge-nf-call-iptables
#sysctl net.bridge.bridge-nf-call-ip6tables

#openstack-config --set   /etc/neutron/dhcp_agent.ini DEFAULT  interface_driver  linuxbridge
openstack-config --set   /etc/neutron/dhcp_agent.ini DEFAULT  interface_driver  neutron.agent.linux.interface.BridgeInterfaceDriver
openstack-config --set   /etc/neutron/dhcp_agent.ini DEFAULT  dhcp_driver  neutron.agent.linux.dhcp.Dnsmasq
openstack-config --set   /etc/neutron/dhcp_agent.ini DEFAULT  enable_isolated_metadata  True 

openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host controller
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret neutron

openstack-config --set  /etc/nova/nova.conf  neutron url http://controller:9696
openstack-config --set  /etc/nova/nova.conf  neutron auth_url http://controller:5000
openstack-config --set  /etc/nova/nova.conf  neutron auth_type password
openstack-config --set  /etc/nova/nova.conf  neutron project_domain_name default
openstack-config --set  /etc/nova/nova.conf  neutron user_domain_name default
openstack-config --set  /etc/nova/nova.conf  neutron region_name RegionOne
openstack-config --set  /etc/nova/nova.conf  neutron project_name service
openstack-config --set  /etc/nova/nova.conf  neutron username neutron
openstack-config --set  /etc/nova/nova.conf  neutron password neutron
openstack-config --set  /etc/nova/nova.conf  neutron service_metadata_proxy true
openstack-config --set  /etc/nova/nova.conf  neutron metadata_proxy_shared_secret neutron

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

systemctl restart openstack-nova-api.service

systemctl restart neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service
systemctl status neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service
systemctl enable neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service
systemctl list-unit-files |grep neutron* |grep enabled

yum install openstack-neutron-linuxbridge ebtables ipset -y

openstack-config --set /etc/neutron/neutron.conf DEFAULT transport_url  rabbit://openstack:openstack@controller
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri  http://controller:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password neutron
openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings  public:eth0
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan false
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group true
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver


openstack-config --set /etc/nova/nova.conf neutron url http://controller:9696
openstack-config --set /etc/nova/nova.conf neutron auth_url http://controller:5000
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron project_domain_name default
openstack-config --set /etc/nova/nova.conf neutron user_domain_name default
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_name service 
openstack-config --set /etc/nova/nova.conf neutron username neutron
openstack-config --set /etc/nova/nova.conf neutron password neutron

systemctl restart openstack-nova-compute.service
systemctl status openstack-nova-compute.service

systemctl restart neutron-linuxbridge-agent.service
systemctl status neutron-linuxbridge-agent.service

systemctl enable neutron-linuxbridge-agent.service
systemctl list-unit-files |grep neutron* |grep enabled

source admin-openrc 

openstack extension list --network

