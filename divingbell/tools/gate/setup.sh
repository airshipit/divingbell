#!/bin/bash

set -ex

export TMP_DIR=$(mktemp -d)
cd $TMP_DIR
git clone https://git.openstack.org/openstack/openstack-helm
cd openstack-helm/tools/gate/
./setup_gate.sh
