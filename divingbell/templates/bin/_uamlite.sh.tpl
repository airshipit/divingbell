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

cat <<'EOF' > {{ .Values.conf.chroot_mnt_path | quote }}/tmp/uamlite_host.sh
{{ include "divingbell.shcommon" . }}

keyword='divingbell'
builtin_acct='ubuntu'

add_user(){
  die_if_null "${user_name}" ", 'user_name' env var not initialized"
  : ${user_sudo:=false}
  : ${user_crypt_passwd:=*}

  # Create user if user does not already exist
  getent passwd ${user_name} && \
    log.INFO "User '${user_name}' already exists" || \
  (useradd --create-home --shell /bin/bash --comment ${keyword} ${user_name} && \
    log.INFO "User '${user_name}' successfully created")

  # Unexpire the user (if user had been previously expired)
  if [ "$(chage -l ${user_name} | grep 'Account expires' | cut -d':' -f2 |
          tr -d '[:space:]')" != "never" ]; then
    usermod --expiredate "" ${user_name}
    log.INFO "User '${user_name}' has been unexpired"
  fi

  # Exclude case where user should not have a password set
  if [ "${user_crypt_passwd}" != '*' ]; then
    local user_has_passwd=true
  fi
  # Set user password if current password does not match desired password
  local crypt_passwd="$(getent shadow ${user_name} | cut -d':' -f2)"
  if [ "${crypt_passwd}" != "${user_crypt_passwd}" ]; then
    usermod -p "${user_crypt_passwd}" ${user_name}
    if [ "${user_has_passwd}" = 'true' ]; then
      log.INFO "User '${user_name}' password set successfully"
    else
      log.INFO "User '${user_name}' password removed successfully"
    fi
  else
    if [ "${user_has_passwd}" = 'true' ]; then
      log.INFO "No change required to password for user '${user_name}'"
    else
      log.INFO "User '${user_name}' has no password, and none was requested"
    fi
  fi

  # Add sudoers entry if requested for user
  if [ "${user_sudo}" = 'true' ]; then
    # Add sudoers entry if it does not already exist
    local user_sudo_file=/etc/sudoers.d/${keyword}-${user_name}-sudo
    if [ -f "${user_sudo_file}" ] ; then
      log.INFO "User '${user_name}' already added to sudoers: ${user_sudo_file}"
    else
      echo "${user_name} ALL=(ALL) NOPASSWD:ALL" > "${user_sudo_file}"
      log.INFO "User '${user_name}' added to sudoers: ${user_sudo_file}"
    fi
    curr_sudoers="${curr_sudoers}${user_sudo_file}"$'\n'
  else
    log.INFO "User '${user_name}' was not requested sudo access"
  fi

  if [ "${user_has_passwd}" = "true" ] && \
     [ "${user_sudo}" = "true" ] && \
     [ "${user_name}" != "${builtin_acct}" ]; then
    expire_builtin_acct_passwd_vote=true
  fi

  curr_userlist="${curr_userlist}${user_name}"$'\n'
}

add_sshkeys(){
  die_if_null "${user_name}" ", 'user_name' env var not initialized"
  local user_sshkeys="$@"

  local sshkey_dir="/home/${user_name}/.ssh"
  local sshkey_file="${sshkey_dir}/authorized_keys"
  if [ -z "${user_sshkeys}" ]; then
    log.INFO "User '${user_name}' has no SSH keys defined"
    if [ -f "${sshkey_file}" ]; then
      rm "${sshkey_file}"
      log.INFO "User '${user_name}' has had its authorized_keys file wiped"
    fi
  else
    local sshkey_file_contents='# NOTE: This file is managed by divingbell'$'\n'
    for sshkey in "$@"; do
      sshkey_file_contents="${sshkey_file_contents}${sshkey}"$'\n'
    done
    local write_file=false
    if [ -f "${sshkey_file}" ]; then
      if [ "$(cat "${sshkey_file}")" = \
           "$(echo "${sshkey_file_contents}" | head -n-1)" ]; then
        log.INFO "User '${user_name}' has no new SSH keys"
      else
        write_file=true
      fi
    else
      write_file=true
    fi
    if [ "${write_file}" = "true" ]; then
      mkdir -p "${sshkey_dir}"
      chmod 700 "${sshkey_dir}"
      echo -e "${sshkey_file_contents}" > "${sshkey_file}"
      chown -R ${user_name}:${user_name} "${sshkey_dir}" || \
        (rm "${sshkey_file}" && die "Error setting ownership on ${sshkey_dir}")
      log.INFO "User '${user_name}' has had SSH keys deployed: ${user_sshkeys}"
    fi

    # In the event that the user specifies ssh keys for the built-in account and
    # no others, do not expire the built-in account
    if [ "${user_sudo}" = "true" ] && \
       [ "${user_name}" != "${builtin_acct}" ]; then
      expire_builtin_acct_ssh_vote=true
    fi
  fi
}

{{- if hasKey .Values.conf "uamlite" }}
{{- if hasKey .Values.conf.uamlite "purge_expired_users" }}
purge_expired_users={{ .Values.conf.uamlite.purge_expired_users | squote }}
{{- end }}
{{- if hasKey .Values.conf.uamlite "users" }}
{{- range $item := .Values.conf.uamlite.users }}
  {{- range $key, $value := . }}
    {{- if eq $key "user_crypt_passwd" }}
      {{/* supported crypt types are 2a (blowfish), 1 (md5), 5 (sha-256), and 6 (sha-512) */}}
      {{- if not (or (regexMatch "\\$2a\\$.*\\$.*" $value) (regexMatch "\\$[156]\\$.*\\$.*" $value)) }}
        {{- fail (print "BAD PASSWORD FOR '" $item.user_name "': The 'user_crypt_passwd' specified for '" $item.user_name "' does not pass regex checks. Ensure that the supplied user password is encoded per divingbell documentation at https://airship-divingbell.readthedocs.io/#uamlite") }}
      {{- end }}
    {{- end }}
    {{ $key }}={{ $value | squote }} \
  {{- end }}
  add_user

  {{- range $key, $value := . }}
    {{ $key }}={{ $value | squote }} \
  {{- end }}
  {{- if hasKey . "user_sshkeys" }}
  {{- if not (eq (first .user_sshkeys) "Unmanaged") }}
  add_sshkeys {{ range $ssh_key := .user_sshkeys }}{{ if not (or (regexMatch "ssh-dss .*" $ssh_key) (regexMatch "ecdsa-.*" $ssh_key) (regexMatch "ssh-ed25519 .*" $ssh_key) (regexMatch "ssh-rsa .*" $ssh_key)) }}{{ fail (print "BAD SSH KEY FOR '" $item.user_name "': One of the 'user_sshkeys' specified for '" $item.user_name "' does not pass regex checks: '" $ssh_key "'. Ensure that the supplied user SSH keys are supported/formatted per divingbell documentation at https://airship-divingbell.readthedocs.io/#uamlite") }}{{ else }}{{ $ssh_key | squote }}{{ end }} {{ end }}
{{- end }}
{{- else }}
  add_sshkeys
{{- end }}
{{- end }}
{{- end }}
{{- end }}

# Expire any previously defined users that are no longer defined
if [ -n "$(getent passwd | grep ${keyword} | cut -d':' -f1)" ]; then
  users="$(getent passwd | grep ${keyword} | cut -d':' -f1)"
  echo "$users" | sort > /tmp/prev_users
  echo "$curr_userlist" | sort > /tmp/curr_users
  revert_list="$(comm -23 /tmp/prev_users /tmp/curr_users)"
  IFS=$'\n'
  for user in ${revert_list}; do
    # We expire rather than delete the user to maintain local UID FS consistency
    # unless purge is explicity requested (remove user and user home dir).
    if [ "${purge_expired_users}" = "true" ]; then
      deluser ${user} --remove-home
      log.INFO "User '${user}' and home directory have been purged."
    else
      usermod --expiredate 1 ${user}
      log.INFO "User '${user}' has been disabled (expired)"
    fi
  done
  unset IFS
fi

# Delete any previous user sudo access that is no longer defined
if [ -n "$(find /etc/sudoers.d | grep ${keyword})" ]; then
  sudoers="$(find /etc/sudoers.d | grep ${keyword})"
  echo "$sudoers" | sort > /tmp/prev_sudoers
  echo "$curr_sudoers" | sort > /tmp/curr_sudoers
  revert_list="$(comm -23 /tmp/prev_sudoers /tmp/curr_sudoers)"
  IFS=$'\n'
  for sudo_file in ${revert_list}; do
    rm -v "${sudo_file}"
    log.INFO "Sudoers file '${sudo_file}' has been deleted"
  done
  unset IFS
fi

if [ -n "${builtin_acct}" ] && [ -n "$(getent passwd ${builtin_acct})" ]; then
  # Disable built-in account as long as there was at least one account defined
  # in this chart with a ssh key present
  if [ "${expire_builtin_acct_passwd_vote}" = "true" ] && \
     [ "${expire_builtin_acct_ssh_vote}" = "true" ]; then
    if [ "$(chage -l ${builtin_acct} | grep 'Account expires' | cut -d':' -f2 |
          tr -d '[:space:]')" = "never" ]; then
      usermod --expiredate 1 ${builtin_acct}
      log.INFO "Built-in account '${builtin_acct}' was expired because at least"
      log.INFO "one other account was defined with an SSH key."
    fi
  # Re-enable built-in account as a fallback in the event that are no other
  # accounts defined in this chart with a ssh key present
  else
    if [ "$(chage -l ${builtin_acct} | grep 'Account expires' | cut -d':' -f2 |
          tr -d '[:space:]')" != "never" ]; then
      usermod --expiredate "" ${builtin_acct}
      log.INFO "Built-in account '${builtin_acct}' was un-expired because there"
      log.INFO "were no other accounts defined with an SSH key."
    fi
  fi
elif [ -n "${builtin_acct}" ]; then
  log.WARN "Could not find built-in account '${builtin_acct}'."
fi

if [ -n "${curr_userlist}" ]; then
  log.INFO 'All uamlite data successfully validated on this node.'
else
  log.WARN 'No uamlite overrides defined for this node.'
fi

log.INFO 'Putting the daemon to sleep.'
EOF

chmod 755 {{ .Values.conf.chroot_mnt_path | quote }}/tmp/uamlite_host.sh
chroot {{ .Values.conf.chroot_mnt_path | quote }} /tmp/uamlite_host.sh

while [ 1 ]; do
  sleep 300
done

exit 0

