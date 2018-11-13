#!/bin/bash

{{/*
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
*/}}

set -e

cat <<'EOF' > {{ .Values.conf.chroot_mnt_path | quote }}/tmp/apt.sh
{{ include "divingbell.shcommon" . }}

persist_path='/var/divingbell/apt'
declare -A CURRENT_PACKAGES
declare INSTALLED_THIS_TIME
declare TO_DELETE
declare TO_KEEP
declare REQUESTED_PACKAGES

if [ ! -d "${persist_path}" ]; then
  mkdir -p "${persist_path}"
fi

write_test "${persist_path}"

load_package_list_with_versions(){
    set +x
    for f in "$@"; do
        IFS="=" read -r name version <<< $f;
        IFS=":" read -r name arch <<< $name;
        CURRENT_PACKAGES["$name"]="$version";
    done
    set -x
}

################################################
#Stage 1
#Collect data
################################################

# First 5 lines are field descriptions
load_package_list_with_versions $(dpkg -l | awk 'NR>5 {print $2"="$3}')

################################################
#Stage 2
#Install new packages
################################################

{{- if hasKey .Values.conf "apt" }}
{{- if hasKey .Values.conf.apt "packages" }}
{{- range .Values.conf.apt.packages }}
if [[ "${CURRENT_PACKAGES[{{ .name | squote }}]+isset}" != "isset"{{- if .version }} || "${CURRENT_PACKAGES[{{ .name | squote }}]}" != {{ .version | squote }}{{- end }} ]]; then
    apt-get install -y{{ if .repo }} -t {{ .repo | squote }}{{ end }} {{ .name | squote -}} {{- if .version }}={{ .version | squote }}{{ end }}
    INSTALLED_THIS_TIME="$INSTALLED_THIS_TIME {{ .name }}"
fi
REQUESTED_PACKAGES="$REQUESTED_PACKAGES {{ .name }}"
{{- end }}
{{- end }}
{{- end }}

################################################
#Stage 3
#Remove packages not present in conf.apt anymore
################################################

echo $INSTALLED_THIS_TIME | sed 's/ /\n/g' | sed '/^[[:space:]]*$/d' | sort > ${persist_path}/packages.new
echo $REQUESTED_PACKAGES | sed 's/ /\n/g' | sed '/^[[:space:]]*$/d' | sort > ${persist_path}/packages.requested
if [ -f ${persist_path}/packages ]; then
    TO_DELETE=$(comm -23 ${persist_path}/packages ${persist_path}/packages.requested)
    TO_KEEP=$(echo "$TO_DELETE" | comm -23 ${persist_path}/packages -)
    if [ ! -z "$TO_DELETE" ]; then
        for pkg in "$TO_DELETE"; do
            apt-get purge -y $pkg
        done
        apt-get autoremove -y
    fi
    if [ ! -z "$TO_KEEP" ]; then
        echo "$TO_KEEP" > ${persist_path}/packages
    else
        rm ${persist_path}/packages
    fi
fi
if [ ! -z "$INSTALLED_THIS_TIME" ]; then
    cat ${persist_path}/packages.new >> ${persist_path}/packages
    sort ${persist_path}/packages -o ${persist_path}/packages
fi

exit 0
EOF

chmod 755 {{ .Values.conf.chroot_mnt_path | quote }}/tmp/apt.sh
chroot {{ .Values.conf.chroot_mnt_path | quote }} /tmp/apt.sh

sleep 1
echo 'INFO Putting the daemon to sleep.'

while [ 1 ]; do
  sleep 300
done

exit 0
