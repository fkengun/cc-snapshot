#!/usr/bin/python

import os
from novaclient import client
import novaclient
import sys

os_password=os.environ.get('OS_PASSWORD')
os_auth_url=os.environ.get('OS_AUTH_URL')
os_username=os.environ.get('OS_USERNAME')
os_project=os.environ.get('OS_TENANT_NAME')

if os_password is None or os_auth_url is None or os_username is None or os_project is None:
  sys.stderr.write("env not found, please source your openrc file first\n")
  sys.exit(0)

nova = client.Client("2", os_username, os_password, os_project, os_auth_url)

my_servers = nova.servers.list() #search_opts={'OS-EXT-AZ:availability_zone':reservation_name})

username = 'kun'

for server in my_servers:
    server_dict = server.to_dict()
    ips = nova.servers.ips(server)
    for key in ips.keys():
        addresses = server.networks[key]
        if len(addresses) >= 1:
          if username in server.name or username.upper() in server.name:
            print "%s\t%s" % (addresses[0], server.name.lower())
