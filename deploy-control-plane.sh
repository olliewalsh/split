#!/usr/bin/env bash

source ~/stackrc

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates templates
fi

time openstack overcloud deploy --templates ~/templates \
     -e ~/templates/environments/docker.yaml \
     -e ~/templates/environments/low-memory-usage.yaml \
     -e ~/templates/environments/disable-telemetry.yaml \
     -e ~/templates/environments/debug.yaml \
     -e ~/docker_registry.yaml \
     --compute-scale 0 --control-scale 1 --ntp-server time.google.com \
     --stack control-plane

# Update /etc/hosts

HOSTFILE=/etc/hosts

## * Remove any old overcloud host entries from `/etc/hosts`.
## ::

sudo sed -i '/^## BEGIN OVERCLOUD HOSTS/,/^## END OVERCLOUD HOSTS/ d' $HOSTFILE

## * Add overcloud hosts to `/etc/hosts`.
## ::

cat <<EOF | sudo tee -a $HOSTFILE
## BEGIN OVERCLOUD HOSTS  #nodocs
$(openstack stack output show control-plane HostsEntry -f value -c output_value)

## END OVERCLOUD HOSTS    #nodocs
EOF

for node in `openstack server list -c Name -f value`; do
  ssh -o StrictHostKeyChecking=no heat-admin@${node} sudo sed -i \'/^# HEAT_HOSTS_START/,/^# HEAT_HOSTS_END/ d\' $HOSTFILE
  cat <<EOF | ssh -o StrictHostKeyChecking=no heat-admin@${node} sudo tee -a $HOSTFILE
# HEAT_HOSTS_START
$(openstack stack output show control-plane HostsEntry -f value -c output_value)
# HEAT_HOSTS_END
EOF
done

