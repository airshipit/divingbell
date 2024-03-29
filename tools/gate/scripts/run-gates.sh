#!/bin/bash

# Copyright 2017 The Openstack-Helm Authors.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

set -xe



../../openstack/openstack-helm-infra/tools/deployment/apparmor/001-setup-apparmor-profiles.sh
../../openstack/openstack-helm-infra/tools/deployment/common/005-deploy-k8s.sh
./tools/gate/scripts/010-build-charts.sh
sudo --preserve-env ./tools/gate/scripts/020-test-divingbell.sh
