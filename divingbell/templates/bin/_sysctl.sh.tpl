#!/bin/bash

{{/*
# Copyright 2017 AT&T Intellectual Property.  All other rights reserved.
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

cat <<'EOF' > {{ .Values.conf.chroot_mnt_path | quote }}/tmp/sysctl_host.sh
{{ include "divingbell.shcommon" . }}

# TODO: Make prefix configurable to control param loading order
fname_prefix='60-divingbell-'
defaults_path='/var/divingbell/sysctl'
persist_path='/etc/sysctl.d'
reload_system_configs=false

if [ ! -d "${defaults_path}" ]; then
  mkdir -p "${defaults_path}"
fi

write_test "${defaults_path}"
write_test "${persist_path}"

add_sysctl_param(){
  local user_key="${1}"
  die_if_null "${user_key}" ", 'user_key' not supplied to function"
  local user_val="${2}"
  die_if_null "${user_val}" ", 'user_val' not supplied to function"

  # Try reading the current sysctl tunable param / value
  # If sysctl cannot find the specified tunable, script will exit here
  local system_key_val_pair
  system_key_val_pair="$(sysctl $user_key)"

  # For further operation, use the tunable name returned by sysctl above,
  # rather than the one specified by the user.
  # sysctl gives a consistently formatted tunable (e.g., net.ipv4.ip_forward)
  # regardless of input format (e.g., net/ipv4/ip_forward).
  local system_key
  system_key="$(echo ${system_key_val_pair} |
                cut -d'=' -f1 | tr -d '[:space:]')"
  [ -n "${system_key}" ] || die 'Null variable exception'

  # Store current kernel sysctl default in the event we need to restore later
  # But only if it is the first time we are changing the tunable,
  # to capture the orignal value.
  local system_val
  system_val="$(echo ${system_key_val_pair} |
                cut -d'=' -f2 | tr -d '[:space:]')"
  [ -n "${system_val}" ] || die 'Null variable exception'
  local orig_val="${defaults_path}/${fname_prefix}${system_key}.conf"
  if [ ! -f "${orig_val}" ]; then
    echo "${system_key_val_pair}" > "${orig_val}"
  fi

  # Apply new setting. If an invalid value were provided, sysctl would choke
  # here, before making the change persistent.
  if [ "${user_val}" != "${system_val}" ]; then
    sysctl -w "${system_key}=${user_val}"
  fi

  # Persist the new setting
  file_content="${system_key}=${user_val}"
  file_path="${persist_path}/${fname_prefix}${system_key}.conf"
  if [ -f "${file_path}" ] &&
     [ "$(cat ${file_path})" != "${file_content}" ] ||
     [ ! -f "${file_path}" ]
  then
    echo "${file_content}" > "${file_path}"
    reload_system_configs=true
    log.INFO "Sysctl setting applied: ${system_key}=${user_val}"
  else
    log.INFO "No changes made to sysctl param: ${system_key}=${user_val}"
  fi

  curr_settings="${curr_settings}${fname_prefix}${system_key}.conf"$'\n'
}

{{- range $key, $value := .Values.conf.sysctl }}
add_sysctl_param {{ $key | squote }} {{ $value | squote }}
{{- end }}

# Revert any previously applied sysctl settings which are now absent
prev_files="$(find "${defaults_path}" -type f)"
if [ -n "${prev_files}" ]; then
  basename -a ${prev_files} | sort > /tmp/prev_sysctl
  echo "${curr_settings}" | sort > /tmp/curr_sysctl
  revert_list="$(comm -23 /tmp/prev_sysctl /tmp/curr_sysctl)"
  IFS=$'\n'
  for orig_sysctl_setting in ${revert_list}; do
    rm "${persist_path}/${orig_sysctl_setting}"
    sysctl -p "${defaults_path}/${orig_sysctl_setting}"
    log.INFO "Reverted sysctl setting:" \
             "$(cat "${defaults_path}/${orig_sysctl_setting}")"
    rm "${defaults_path}/${orig_sysctl_setting}"
    reload_system_configs=true
  done
fi

# Final validation of sysctl settings written to /etc/sysctl.d
# Also allows for nice play with other automation (or manual) systems that
# may have separate overrides for reverted tunables.
if [ "${reload_system_configs}" = "true" ]; then
  sysctl --system
fi

if [ -n "${curr_settings}" ]; then
  log.INFO 'All sysctl configuration successfully validated on this node.'
else
  log.WARN 'No sysctl overrides defined for this node.'
fi

log.INFO 'Putting the daemon to sleep.'
EOF

chmod 755 {{ .Values.conf.chroot_mnt_path | quote }}/tmp/sysctl_host.sh
chroot {{ .Values.conf.chroot_mnt_path | quote }} /tmp/sysctl_host.sh

while [ 1 ]; do
  sleep 300
done

exit 0
