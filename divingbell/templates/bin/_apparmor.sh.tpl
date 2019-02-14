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

cat <<'EOF' > {{ .Values.conf.chroot_mnt_path | quote }}/tmp/apparmor_host.sh
{{ include "divingbell.shcommon" . }}

load_flags="-r -W"
{{- if hasKey .Values.conf "apparmor" }}
{{- if hasKey .Values.conf.apparmor "complain_mode" }}
{{- if .Values.conf.apparmor.complain_mode }}
load_flags="$load_flags -C"
{{- end }}
{{- end }}
{{- end }}
load_cmd="apparmor_parser $load_flags"
unload_cmd='apparmor_parser -R'
defaults_path='/var/divingbell/apparmor'
persist_path='/etc/apparmor.d'
declare -A CURRENT_FILENAMES
declare -A SAVED_STATE_FILENAMES

if [ ! -d "${defaults_path}" ]; then
  mkdir -p "${defaults_path}"
fi

write_test "${defaults_path}"
write_test "${persist_path}"

save_apparmor_profile(){
  local filename="$1"
  local data="$2"
  CURRENT_FILENAMES["$filename"]=''

  #Check if host already had the same filename
  if [ ${SAVED_STATE_FILENAMES["$filename"]+_} ]; then
    unset SAVED_STATE_FILENAMES["$filename"]
  fi

  echo -ne "${data}" > ${defaults_path}/${filename}
  if [ ! -L ${persist_path}/${filename} ]; then
    ln -s ${defaults_path}/${filename}  ${persist_path}/${filename}
  fi
}

#######################################
#Stage 1
#Collect data
#######################################

#Search for any saved apparmor profiles
pushd $defaults_path
count=$(find . -type f | wc -l)

#Check if directory is non-empty
if [ $count -gt 0 ]; then
  for f in $(find . -type f|xargs -n1 basename); do
    SAVED_STATE_FILENAMES[$f]=''
  done
fi

#######################################
#Stage 2
#Save new apparmor profiles
#######################################

{{- if hasKey .Values.conf "apparmor" }}
{{- if hasKey .Values.conf.apparmor "profiles" }}
{{- range $filename, $value := .Values.conf.apparmor.profiles }}
save_apparmor_profile {{ $filename | squote }} {{ $value | squote }}
{{- end }}
{{- end }}
{{- end }}


#######################################
#Stage 3
#Clean stale apparmor profiles
#######################################

#If hash is not empty - there are old filenames that need to be handled
if [ ${#SAVED_STATE_FILENAMES[@]} -gt 0 ]; then
  for filename in ${!SAVED_STATE_FILENAMES[@]}; do
    #Unload any previously applied apparmor profiles which are now absent
    $unload_cmd ${defaults_path}/${filename} || die "Problem unloading profile ${defaults_path}/${filename}"
    if [ -L ${persist_path}/${filename} ]; then
      unlink ${persist_path}/${filename}
    fi
    rm -f ${defaults_path}/${filename}
    # log/append the stale profiles that require eventual reboot
    echo "apparmor: stale profile ${defaults_path}/${filename}" >> /var/run/reboot-required.pkgs
    unset SAVED_STATE_FILENAMES["$filename"]
  done
  # mark node as needing eventual reboot
  echo '*** System restart required ***' > /var/run/reboot-required
fi

#######################################
#Stage 4
#Install/update new apparmor profiles
#Save new apparmor profiles
#######################################

for filename in ${!CURRENT_FILENAMES[@]}; do
  $load_cmd ${persist_path}/${filename} || die "Problem loading ${persist_path}/${filename}"
done

log.INFO 'Putting the daemon to sleep.'
EOF

chmod 755 {{ .Values.conf.chroot_mnt_path | quote }}/tmp/apparmor_host.sh
chroot {{ .Values.conf.chroot_mnt_path | quote }} /tmp/apparmor_host.sh

while [ 1 ]; do
  sleep 300
done

exit 0
