#!/usr/bin/env bash

source ~/stackrc

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates templates
fi

openstack overcloud deploy --templates ~/templates \
	  -r compute_only_roles_data.yaml \
	  -e ~/templates/environments/docker.yaml \
	  -e ~/templates/environments/low-memory-usage.yaml \
	  -e ~/templates/environments/disable-telemetry.yaml \
	  -e ~/templates/environments/debug.yaml \
	  -e ~/docker_registry.yaml \
	  -e endpoint.yaml \
	  -e extra_hosts.yaml \
          -e extra.yaml \
          --disable-password-generation \
          -e passwords.yaml \
	  --stack compute0

# Update /etc/hosts

HOSTFILE=/etc/hosts

## * Remove any old overcloud host entries from `/etc/hosts`.
## ::

sudo sed -i '/^## BEGIN OVERCLOUD HOSTS/,/^## END OVERCLOUD HOSTS/ d' $HOSTFILE

## * Add overcloud hosts to `/etc/hosts`.
## ::

cat <<EOF | sudo tee -a $HOSTFILE
## BEGIN OVERCLOUD HOSTS  #nodocs
$(openstack stack output show compute0 HostsEntry -f value -c output_value)

## END OVERCLOUD HOSTS    #nodocs
EOF

for node in `openstack server list -c Name -f value`; do
  ssh -o StrictHostKeyChecking=no heat-admin@${node} sudo sed -i \'/^# HEAT_HOSTS_START/,/^# HEAT_HOSTS_END/ d\' $HOSTFILE
  cat <<EOF | ssh -o StrictHostKeyChecking=no heat-admin@${node} sudo tee -a $HOSTFILE
# HEAT_HOSTS_START
$(openstack stack output show compute0 HostsEntry -f value -c output_value)
# HEAT_HOSTS_END
EOF
done

# Run cell_v2 host discovery on the controller to pick up the new compute
ssh -o StrictHostKeyChecking=no heat-admin@control-plane-controller-0 sudo docker exec -i nova_api nova-manage cell_v2 discover_hosts --by-service --verbose

# TODO: nova migration is unlikely to work between computes on different stacks
# we will need to propegate ssh_known_hosts to all hosts to resolve this
# and probably /etc/hosts too until I revert https://review.openstack.org/590362
