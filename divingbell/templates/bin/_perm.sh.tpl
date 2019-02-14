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

{{- $perm_loop_sleep_interval := 60 }}

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

revert_perm(){
# Revert
  prev_files="$(find "${backup_path}" -type f ! -name last_run_timestamp)"
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
        if [ "$first" -eq 1 && -e "$a2"]; then
          $(chmod "$a1" "$a2")
          first=0
        elif [ -e "$a2"]; then
          $(chown "$a1" "$a2")
        else
          log.WARN "Unable to revert permissions on $a2"
          continue
        fi
      done < "${backup_path}/${o_perm}"

      rm "${backup_path}/${o_perm}"
      log.INFO "Reverted permissions and owner: ${backup_path}/${o_perm}"
    done
  fi
}

{{- $_ := set $.Values "__rerun_policy" "always" }}
{{- if hasKey .Values.conf "perm" }}
{{- if hasKey .Values.conf.perm "rerun_policy" }}
  {{- if and (not (eq .Values.conf.perm.rerun_policy "always")) (not (eq .Values.conf.perm.rerun_policy "never")) (not (eq .Values.conf.perm.rerun_policy "once_successfully")) }}
    {{- fail (print "BAD 'rerun_policy' Got '" .Values.conf.perm.rerun_policy "', but expected 'always', 'never', or 'once_successfully'.") }}
  {{- end }}
  {{- $_ := set $.Values "__rerun_policy" .Values.conf.perm.rerun_policy }}
{{- end }}

{{- $_ := set $.Values "__rerun_interval" "infinite" }}
{{- if hasKey .Values.conf.perm "rerun_interval" }}
{{- $_ := set $.Values "__rerun_interval" .Values.conf.perm.rerun_interval }}

  {{- if not (eq (.Values.conf.perm.rerun_interval | toString) "infinity") }}
    {{- if lt (.Values.conf.perm.rerun_interval | int) $perm_loop_sleep_interval }}
      {{- fail (print "BAD 'rerun_interval' Got '" $.Values.__rerun_interval "', but expected >= '" $perm_loop_sleep_interval "'.") }}
    {{- end }}
    {{- if not (eq $.Values.__rerun_policy "always") }}
      {{- fail (print "BAD COMBINATION: Must use 'rerun_policy' of 'always' when defining a finite 'retry_interval'. Got 'rerun_policy' of '" $.Values.__rerun_policy "' and 'retry_interval' of '" $.Values.__rerun_interval "'.") }}
    {{- end }}
  {{- end }}
  {{- $_ := set $.Values "__rerun_interval" .Values.conf.perm.rerun_interval }}
{{- end }}

{{- if hasKey .Values.conf.perm "rerun_policy" }}
      {{- if and (not (eq $.Values.__rerun_policy "always")) (not (eq $.Values.__rerun_policy "never")) (not (eq $.Values.__rerun_policy "once_successfully")) }}
        {{- fail (print "BAD 'rerun_policy' : Got '" $.Values.__rerun_policy "', but expected 'always', 'never', or 'once_successfully'.") }}
      {{- end }}
{{- end }}

cd "${backup_path}"

{{- $_ := set $.Values "__values_hash" list }}
{{- $hash := $.Values.__values_hash | toString | sha256sum }}

hash={{ $hash | squote }}
if [ ! -d "${hash}" ]; then
  mkdir -p "${hash}"
fi

# check rerun policy
hash_check=fail
if  [[ {{ $.Values.__rerun_policy }} = always ]] || \
    [[ ! -f ${hash}/exit_code ]] || \
   ([[ {{ $.Values.__rerun_policy }} = once_successfully ]] && \
    [[ $(cat ${hash}/exit_code) != 0 ]]); then
  hash_check=pass
fi
# check rerun interval
interval_check=fail
if  [[ ! -f ${hash}/last_run_timestamp ]] || [[ ! -f ${hash}/exit_code ]]; then
  interval_check=pass
elif [[ $(cat ${hash}/exit_code) = 0 ]]; then
  if [[ {{ $.Values.__rerun_interval }} = infinite ]]; then
    interval_check=pass
  elif [[ $(date +"%s") -ge $(($(cat ${hash}/last_run_timestamp) + {{ $.Values.__rerun_interval }})) ]]; then
    interval_check=pass
  fi
fi
if [[ $hash_check = pass ]] && [[ $interval_check = pass ]]; then
  if [[ -f ${hash}/exit_code ]]; then
    # remove previous run record, in case this run is interrupted
    rm ${hash}/exit_code
  fi
 # write timestamp at beginning of execution
 log.INFO 'All permissions successfully applied on this node.'
 echo $(date +"%s") > "${hash}/last_run_timestamp"

 {{- range $perm := .Values.conf.perm.paths }}
 add_perm {{ $perm.path | squote }} {{ $perm.owner | squote }} {{ $perm.group | squote }} {{ $perm.permissions | squote }}
 {{- end }}
 log.INFO "Applied: ${applied_perm}"

 revert_perm

 if [ -n "${curr_settings}" ]; then
  log.INFO 'All permissions successfully applied on this node.'
 else
  log.WARN 'No permissions overrides defined for this node.'
 fi
fi

echo 0 > "${hash}/exit_code"
{{- end}}
log.INFO 'Putting the daemon to sleep for {{ $perm_loop_sleep_interval }} seconds.'
EOF

chmod 755 {{ .Values.conf.chroot_mnt_path | quote }}/tmp/perm_host.sh

while true; do
  chroot {{ .Values.conf.chroot_mnt_path | quote }} /tmp/perm_host.sh
  sleep {{ $perm_loop_sleep_interval }}
done

exit 0
