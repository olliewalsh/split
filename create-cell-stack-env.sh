#!/usr/bin/env bash

source ~/stackrc

STACK=control-plane

openstack stack output show $STACK EndpointMap --format yaml  | grep -A 1000 output_value | sed "s/^/ /" | sed "1s/^/parameter_defaults:\n EndpointMapOverride:\n/" | sed "/output_value/d" > endpoint.yaml
(openstack stack output show control-plane AllNodesConfig --format yaml; openstack stack output show control-plane GlobalConfig --format yaml  | grep -A 1000 output_value | tail -n +2) | ./cell_param_prep.py > cell_extra.yaml
openstack stack output show $STACK HostsEntry | grep controller | sed "s/|//g" | sed "s/^ */ - /" | sed "1s/^/parameter_defaults:\n ExtraHostFileEntries:\n/" > extra_hosts.yaml

openstack object save --file - $STACK plan-environment.yaml | python -c 'import yaml as y, sys as s; s.stdout.write(y.dump({"parameter_defaults": y.load(s.stdin.read())["passwords"]}));' > passwords.yaml

openstack overcloud roles generate --roles-path ~/templates/roles -o cell_roles_data.yaml Compute CellController

