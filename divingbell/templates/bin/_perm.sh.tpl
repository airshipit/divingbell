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

cat <<'EOF' > {{ .Values.conf.chroot_mnt_path | quote }}/tmp/perm_host.sh
{{ include "divingbell.shcommon" . }}

backup_path='/var/divingbell/perm'

[ ! -d "${backup_path}" ] && mkdir -p "${backup_path}"

write_test "${backup_path}"

add_perm(){
# accepts $path, $owner, $group, $permissions
  local path="${1}"

  for i in ${path}; do
    add_single_perm $i ${2} ${3} ${4}
  done
}

add_single_perm(){
# accepts $path, $owner, $group, $permissions
  local path="${1}"
  local owner="${2}"
  local group="${3}"
  local permissions="${4}"

  # check if file exists
  [ -e $path ] || return 1
  # if set -e is set the entire script will exit

  # construct backup name
  local file_name=$(systemd-escape $path)
  local backup_file="${backup_path}/${file_name}"
  # check if backup exists
  if [ ! -e ${backup_file} ]; then
      # Try reading the current permissions and owner
      local o_owner="$(stat -c %U ${path})"
      local o_group="$(stat -c %G ${path})"
      local o_permissions="$(stat -c %a ${path})"

      # write restore script/data
      # design decision:
      # we could write complete script to restore originals
      # but for security reasons write only data
      # otherwise we would execute _any_ script from backup dir

      # chmod o_permissions path
      echo "$o_permissions $path"> ${backup_file}
      # chown o_owner:o_group path
      echo "$o_owner:$o_group $path">> ${backup_file}

      log.DEBUG ${backup_file}
  fi

  # apply permissions
  chmod ${permissions} ${path}
  # apply owner and group
  chown ${owner}:${group} ${path}

  # notice applied perm
  applied_perm="${applied_perm}${file_name}"$'\n'
  # ("${file_name}"$'\n')

}

{{- range $perm := .Values.conf.perm }}
add_perm {{ $perm.path | squote }} {{ $perm.owner | squote }} {{ $perm.group | squote }} {{ $perm.permissions | squote }}
{{- end }}

log.INFO "Applied: ${applied_perm}"

# Revert
prev_files="$(find "${backup_path}" -type f)"
if [ -n "${prev_files}" ]; then
  basename -a ${prev_files} | sort > /tmp/prev_perm
  echo "${applied_perm}" | sort > /tmp/curr_perm
  log.DEBUG /tmp/prev_perm
  log.DEBUG /tmp/curr_perm
  revert_list="$(comm -23 /tmp/prev_perm /tmp/curr_perm)"
  IFS=$'\n'
  for o_perm in ${revert_list}; do
    first=1
    while IFS=' ' read -r a1 a2; do
      if [ "$first" -eq 1 ]; then
        $(chmod $a1 $a2)
        first=0
      else
        $(chown $a1 $a2)
      fi
    done < "${backup_path}/${o_perm}"

    rm "${backup_path}/${o_perm}"
    log.INFO "Reverted permissions and owner: ${backup_path}/${o_perm}"
  done
fi

if [ -n "${curr_settings}" ]; then
  log.INFO 'All permissions successfully applied on this node.'
else
  log.WARN 'No permissions overrides defined for this node.'
fi

exit 0
EOF

chmod 755 {{ .Values.conf.chroot_mnt_path | quote }}/tmp/perm_host.sh
chroot {{ .Values.conf.chroot_mnt_path | quote }} /tmp/perm_host.sh

sleep 1
echo 'INFO Putting the daemon to sleep.'

while [ 1 ]; do
  sleep 300
done

exit 0
