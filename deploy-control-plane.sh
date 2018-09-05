#!/usr/bin/env bash

source ~/stackrc

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates templates
fi

time openstack overcloud deploy --templates ~/templates \
     -e ~/templates/environments/docker.yaml \
     -e ~/templates/environments/low-memory-usage.yaml \
     -e ~/templates/environments/disable-telemetry.yaml \
     -e ~/docker_registry.yaml \
     --compute-scale 0 --control-scale 1 --ntp-server 10.5.26.10 \
     --stack control-plane

# Update /etc/hosts, deploy-compute can then use the hostname to ssh

HOSTFILE=/etc/hosts

## * Remove any old overcloud host entries from `/etc/hosts`.
## ::

sudo sed -i '/^## BEGIN CONTROL-PLANE HOSTS/,/^## END CONTROL_PLANE HOSTS/ d' $HOSTFILE

## * Add overcloud hosts to `/etc/hosts`.
## ::

cat <<EOF | sudo tee -a $HOSTFILE
## BEGIN CONTROL-PLANE HOSTS  #nodocs
$(openstack stack output show control-plane HostsEntry -f value -c output_value)

## END CONTROL-PLANE HOSTS    #nodocs
EOF
