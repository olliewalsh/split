#!/usr/bin/env python
import yaml as y, sys as s

overrides = {
  'nova::db::mysql_api::setup_cell0': False
}

blacklist = ['oslo_messaging_rpc_cell_node_names']

data=y.load(s.stdin.read())["output_value"]

data = {k: v for k, v in data.items() if not any((k in blacklist, k.startswith('mysql_'), k.startswith('nova_conductor')))}

data.update(overrides)

# AllNodesExtraMapData might work??
s.stdout.write(y.dump({"parameter_defaults": {"ExtraConfig": data}}))

