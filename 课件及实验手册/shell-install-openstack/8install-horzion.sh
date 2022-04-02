#!/bin/bash

yum install openstack-dashboard -y

cat > local_settings.txt << EOF



ALLOWED_HOSTS = ['*', 'localhost']

SESSION_ENGINE = 'django.contrib.sessions.backends.file'
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,
}
OPENSTACK_HOST = "controller"
OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "default"
CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': 'controller:11211',
    }
}
OPENSTACK_NEUTRON_NETWORK = {
    'enable_router': False,
    'enable_quotas': False,
    'enable_distributed_router': False,
    'enable_ha_router': False,
    'enable_fip_topology_check': False,
    'enable_lb': False,
    'enable_firewall': False,
    'enable_vpn': False,
}
TIME_ZONE = "Asia/Shanghai"
EOF

#cp /etc/openstack-dashboard/local_settings /etc/openstack-dashboard/local_settings.bak 
cat local_settings.txt >> /etc/openstack-dashboard/local_settings

#cp -rf local_settings /etc/openstack-dashboard/local_settings

cat > dashboard.txt << EOF 

WSGIApplicationGroup %{GLOBAL}
EOF

#cp -rf openstack-dashboard.conf /etc/httpd/conf.d/openstack-dashboard.conf
cat dashboard.txt >> /etc/httpd/conf.d/openstack-dashboard.conf

systemctl restart httpd.service memcached.service
systemctl status httpd.service memcached.service



