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

cat <<'EOF' > {{ .Values.conf.chroot_mnt_path | quote }}/tmp/limits_host.sh
{{ include "divingbell.shcommon" . }}

fname_prefix='60-divingbell-'
persist_path='/etc/security/limits.d'

if [ ! -d "${persist_path}" ]; then
  mkdir -p "${persist_path}"
fi

write_test "${persist_path}"

add_limits_param(){
  local limit="${1}"
  die_if_null "${limit}" ", limit not supplied to function"
  local domain="${2}"
  die_if_null "${domain}" ", domain not supplied to function"
  local type="${3}"
  die_if_null "${type}" ", type not supplied to function"
  local item="${4}"
  die_if_null "${item}" ", item not supplied to function"
  local value="${5}"
  die_if_null "${value}" ", value not supplied to function"

  file_content="${domain} ${type} ${item} ${value}"
  file_name="${fname_prefix}${limit}.conf"
  file_path="${persist_path}/${file_name}"

  # Persist the new setting
  if [ -f "${file_path}" ] &&
     [ "$(cat ${file_path})" != "${file_content}" ] ||
     [ ! -f "${file_path}" ]
  then
    echo "${file_content}" > "${file_path}"
    log.INFO "Limits setting applied: ${file_content}"
  else
    log.INFO "No changes made to limits param: ${limit}"
  fi

  curr_limits="${curr_limits}${file_name}"$'\n'
}

{{- range $index, $limit := .Values.conf.limits }}
add_limits_param {{ $index | squote }} {{ $limit.domain | squote }} {{ $limit.type | squote }}\
                 {{ $limit.item | squote }} {{ $limit.value | squote }}
{{- end }}

# Revert any previously applied limits settings which are now absent
prev_files="$(find "${persist_path}" -type f)"
if [ -n "${prev_files}" ]; then
  basename -a ${prev_files} | sort > /tmp/prev_limits
  echo "${curr_limits}" | sort > /tmp/curr_limits
  revert_list="$(comm -23 /tmp/prev_limits /tmp/curr_limits)"
  IFS=$'\n'
  for orig_limits_setting in ${revert_list}; do
    rm "${persist_path}/${orig_limits_setting}"
    log.INFO "Reverted limits setting: ${persist_path}/${orig_limits_setting}"
  done
fi

# Print limit settings
# su is a simple and fast way to see applied changes
# bash, bash -c, sudo, setsid didn't work out for me.
su -c "prlimit --noheadings --output RESOURCE,SOFT,HARD"
# The setting is persisted for a new process.
# It's deliberate design decision to let current process be intact.
# For this test it's just test bash process.
# For production case it's limits_host.sh run by DivingBell pod which is in sleep mode.

if [ -n "${curr_limits}" ]; then
  log.INFO 'All limits configuration successfully validated on this node.'
else
  log.WARN 'No limits overrides defined for this node.'
fi

log.INFO 'Putting the daemon to sleep.'
EOF

chmod 755 {{ .Values.conf.chroot_mnt_path | quote }}/tmp/limits_host.sh
chroot {{ .Values.conf.chroot_mnt_path | quote }} /tmp/limits_host.sh

while [ 1 ]; do
  sleep 300
done

exit 0
