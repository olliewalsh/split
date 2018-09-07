# Split Stack Experiments

**NOTE: requires https://review.openstack.org/600042**

Prototype of a TripleO [Split Controlplane](https://specs.openstack.org/openstack/tripleo-specs/specs/rocky/split-controlplane.html) deployment.

## External Compute

1. Deploy a single controller node with [deploy-control-plane.sh](deploy-control-plane.sh)
2. Extract control plane information that an "external" compute node would need with [create-compute-stack-env.sh](create-compute-stack-env.sh)
3. Deploy an "external" compute node with a separate heat stack [deploy-compute.sh](deploy-compute.sh)

"Work for me", at least the pingtest does (owalsh)

TODO(owalsh): migration is unlikely to work between computes on different stacks. We will need to propegate `ssh_known_hosts` to all hosts to resolve this and probably `/etc/hosts` too until I revert https://review.openstack.org/590362

Based [examples](https://review.openstack.org/#/q/topic:compute_only_stack2+(status:open+OR+status:merged)) from shardy.

## Multi-Cell

**NOTE requires:
https://review.openstack.org/600042
https://review.openstack.org/600588
https://review.openstack.org/600589**

1. Deploy a single controller node with [deploy-control-plane.sh](deploy-control-plane.sh)
2. Extract control plane information that a connected cell v2 controller and compute would need with [create-cell-stack-env.sh](create-cell-stack-env.sh)
3. Deploy a cell controller and compute node with a separate heat stack [deploy-cell.sh](deploy-cell.sh)

Should see the newcompute being added to mycomputecell e.g:

```
Found 3 cell mappings.
Skipping cell0 since it does not contain hosts.
Getting computes from cell 'default': 1c4883d8-0ab5-422d-95d5-c786bd2caecc
Found 0 unmapped computes in cell: 1c4883d8-0ab5-422d-95d5-c786bd2caecc
Getting computes from cell 'mycomputecell': 3d868a19-5152-4977-8fc4-d87dab2a3cbc
Creating host mapping for service computecell0-novacompute-0.localdomain
Found 1 unmapped computes in cell: 3d868a19-5152-4977-8fc4-d87dab2a3cbc
```

TODO:
- look at improving how hieradata is passed from parent to child stack (probably need to support multiple generations too)
- probably need to add new t-h-t services instead of hieradata hacks to avoid conflicts with the parent stack services' hieradata
- need a proper solution for /etc/hosts. This is required for cell_v2 as the main stack needs to connect to the cell mq using the fqdn (rabbit will not allow IPs to be used).

## Notes

Workaround here for reboot issues with cinder LVM - https://bugzilla.redhat.com/show_bug.cgi?id=1412661#c15

