#!/bin/bash
# Copyright 2018 AT&T Intellectual Property.  All other rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Script to setup helm-toolkit and helm dep up the shipyard chart
#
HELM=$1
HTK_REPO=${HTK_REPO:-"https://github.com/openstack/openstack-helm-infra"}
HTK_PATH=${HTK_PATH:-""}
DEP_UP_LIST=${DEP_UP_LIST:-"divingbell"}

if [[ ! -z $(echo $http_proxy) ]]
then
  export no_proxy=$no_proxy,127.0.0.1
fi

set -x

function helm_serve {
  if [[ -d "$HOME/.helm" ]]; then
     echo ".helm directory found"
  else
     ${HELM} init --client-only
  fi
  if [[ -z $(curl -s 127.0.0.1:8879 | grep 'Helm Repository') ]]; then
     ${HELM} serve & > /dev/null
     while [[ -z $(curl -s 127.0.0.1:8879 | grep 'Helm Repository') ]]; do
        sleep 1
        echo "Waiting for Helm Repository"
     done
  else
     echo "Helm serve already running"
  fi

  if ${HELM} repo list | grep -q "^stable" ; then
     ${HELM} repo remove stable
  fi

  ${HELM} repo add local http://localhost:8879/charts
}

mkdir -p build
pushd build
git clone --depth 1 $HTK_REPO || true
pushd ${HTK_REPO##*/}/$HTK_PATH

git pull
make helm-toolkit
helm_serve

popd && popd
for c in $DEP_UP_LIST
do
  ${HELM} dep up $c
done
